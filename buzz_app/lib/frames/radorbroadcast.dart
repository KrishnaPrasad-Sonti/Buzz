import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class RadarBroadcastPage extends StatefulWidget {
  final String username;
  const RadarBroadcastPage({super.key, required this.username});

  @override
  State<RadarBroadcastPage> createState() => _RadarBroadcastPageState();
}

class _RadarBroadcastPageState extends State<RadarBroadcastPage> {
  List<Map<String, String>> nearbyDevices = [];
  String? myIp;
  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;

  @override
  void initState() {
    super.initState();
    initializeRadar();
  }

  @override
  void dispose() {
    _socket?.close();
    _broadcastTimer?.cancel();
    super.dispose();
  }

  Future<void> initializeRadar() async {
    await requestPermissions();
    await getLocalIP();
    await startBroadcastListener();

    if (widget.username != "Unknown") {
      sendBroadcast(); // Initial broadcast
    }

    startPeriodicBroadcast();
  }

  Future<void> requestPermissions() async {
    await Permission.location.request();
  }

  Future<void> getLocalIP() async {
    final info = NetworkInfo();
    try {
      myIp = await info.getWifiIP();
      debugPrint("My IP: $myIp");
    } catch (e) {
      debugPrint("Failed to get IP address: $e");
    }
  }

  Future<void> startBroadcastListener() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4445);
    _socket?.broadcastEnabled = true;

    _socket?.listen((RawSocketEvent event) async {
      if (event == RawSocketEvent.read) {
        final dg = _socket?.receive();
        if (dg == null) return;

        final senderIp = dg.address.address;
        if (senderIp == myIp) return;

        final data = utf8.decode(dg.data);

        if (data.startsWith('BUZZ::')) {
          final senderUsername = data.substring(6);
          if (senderUsername.toLowerCase() == widget.username.toLowerCase()) return;

          final alreadyExists = nearbyDevices.any((d) => d['username'] == senderUsername);
          if (!alreadyExists) {
            setState(() {
              nearbyDevices.add({'ip': senderIp, 'username': senderUsername});
            });
          }
        }

        // FRIEND REQUEST
        else if (data.startsWith('FRIEND_REQ::')) {
          final requester = data.substring('FRIEND_REQ::'.length);

          if (requester == widget.username) return;

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Friend Request"),
              content: Text("$requester wants to be your friend. Accept?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Reject"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await addToContacts(requester);
                    sendFriendAccept(dg.address); // reply to requester
                  },
                  child: Text("Accept"),
                ),
              ],
            ),
          );
        }

        // FRIEND ACCEPTED
        else if (data.startsWith('FRIEND_ACCEPT::')) {
            final friendUsername = data.substring('FRIEND_ACCEPT::'.length);

          await addToContacts(friendUsername);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("$friendUsername accepted your friend request!"),
          ));
        }
      }
    });
  }

  Future<void> sendFriendRequest(String targetIp) async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.send(
        utf8.encode('FRIEND_REQ::${widget.username}'),
        InternetAddress(targetIp),
        4445,
      );
      socket.close();
    } catch (e) {
      debugPrint("Failed to send friend request: $e");
    }
  }

  Future<void> sendFriendAccept(InternetAddress targetIp) async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.send(
        utf8.encode('FRIEND_ACCEPT::${widget.username}'),
        targetIp,
        4445,
      );
      socket.close();
    } catch (e) {
      debugPrint("Failed to send friend accept: $e");
    }
  }

  Future<void> addToContacts(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = prefs.getStringList('contacts') ?? [];

    if (!contacts.contains(username)) {
      contacts.add(username);
      await prefs.setStringList('contacts', contacts);
    }
  }

  void startPeriodicBroadcast() {
    const interval = Duration(seconds: 8);
    _broadcastTimer = Timer.periodic(interval, (_) {
      sendBroadcast();
    });
  }

  Future<void> sendBroadcast() async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final message = 'BUZZ::${widget.username}';
      socket.send(utf8.encode(message), InternetAddress('255.255.255.255'), 4445);
      socket.close();
    } catch (e) {
      debugPrint("Broadcast failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Radar Broadcast")),
      body: nearbyDevices.isEmpty
          ? const Center(child: Text("Searching for Buzz users..."))
          : ListView.builder(
              itemCount: nearbyDevices.length,
              itemBuilder: (context, index) {
                final device = nearbyDevices[index];
                return ListTile(
                  leading: const Icon(Icons.wifi),
                  title: Text(device['username']!),
                  subtitle: Text("IP: ${device['ip']}"),
                  onTap: () {
                    sendFriendRequest(device['ip']!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Friend request sent to ${device['username']}")),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            nearbyDevices.clear();
          });
          sendBroadcast();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
