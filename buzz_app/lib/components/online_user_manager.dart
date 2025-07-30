import 'dart:async';
import 'dart:convert';
import 'dart:io';

class OnlineUser {
  final String ip;
  final DateTime lastSeen;

  OnlineUser({required this.ip, required this.lastSeen});
}

class OnlineUserManager {
  static final OnlineUserManager _instance = OnlineUserManager._internal();
  factory OnlineUserManager() => _instance;
  OnlineUserManager._internal();

  final int port = 4445;
  RawDatagramSocket? _socket;
  final Map<String, OnlineUser> _lastSeenMap = {};
  Timer? _cleanupTimer;

  /// Starts listening for UDP broadcast packets
  Future<void> startListening() async {
    _socket ??= await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    print("✅ UDP socket bound to ${_socket?.address.address}:${_socket?.port}");

    _socket?.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = _socket?.receive();
        if (dg != null) {
          final data = utf8.decode(dg.data);
          final senderIp = dg.address.address;

          print("📥 Received UDP data: $data from $senderIp");

          if (data.startsWith('BUZZ::')) {
            // Handle online broadcast
            final username = data.split('::')[1].trim();
            _lastSeenMap[username] = OnlineUser(ip: senderIp, lastSeen: DateTime.now());
            print("🟢 Seen user: $username from $senderIp");
          } else {
            // Try parsing actual chat message
            try {
              final decoded = jsonDecode(data);
              final sender = decoded['sender'];
              final receiver = decoded['receiver'];
              final message = decoded['message'];

              print("📩 Chat message from $sender to $receiver: $message");

              // You can add logic here to pass it to ChatManager or update UI
              // Example:
              // ChatManager().addMessage(ChatMessageModel.fromJson(decoded));
              // ChatUpdateNotifier().notifyNewMessage(decoded);

            } catch (e) {
              print("❌ JSON decode failed: $e");
            }
          }
        }
      }
    });

    _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) => _cleanup());
  }

  /// Removes users not seen in last 15 seconds
  void _cleanup() {
    final now = DateTime.now();
    _lastSeenMap.removeWhere(
      (_, user) => now.difference(user.lastSeen).inSeconds > 15,
    );
  }

  /// ✅ Returns all currently online users with IP and lastSeen
  Map<String, Map<String, dynamic>> getAllUsersData() {
    final now = DateTime.now();
    final Map<String, Map<String, dynamic>> result = {};

    _lastSeenMap.forEach((username, user) {
      if (now.difference(user.lastSeen).inSeconds <= 10) {
        result[username] = {
          'ip': user.ip,
          'lastSeen': user.lastSeen.toIso8601String(),
        };
      }
    });

    print("🧾 getAllUsersData(): $result");
    return result;
  }

  void stop() {
    _socket?.close();
    _socket = null;
    _cleanupTimer?.cancel();
  }
}
