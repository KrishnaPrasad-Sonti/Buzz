import 'dart:async';
import 'package:buzz_app/components/online_user_manager.dart';
import 'package:buzz_app/frames/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessagesTab extends StatefulWidget {
  final String? username;
  const MessagesTab({super.key, required this.username});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  List<String> friends = [];
  List<String> onlineFriends = [];

  Timer? _onlineCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _startOnlineCheckLoop();
  }

  Future<void> _loadFriends() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    friends = prefs.getStringList('contacts') ?? [];
    if (mounted) {
      setState(() {});
    }
  }

 Map<String, String> onlineFriendIPs = {};

void _startOnlineCheckLoop() {
  _onlineCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) {
    if (!mounted) return;

    final allUsersData = OnlineUserManager().getAllUsersData(); // Map<String, Map<String, dynamic>>
    final now = DateTime.now();
    final filteredMap = <String, String>{};

    for (var friend in friends) {
      if (allUsersData.containsKey(friend)) {
        final lastSeenStr = allUsersData[friend]?['lastSeen'] as String?;
        final lastSeen = lastSeenStr != null ? DateTime.parse(lastSeenStr) : null;
        final ip = allUsersData[friend]?['ip'] as String?;

        if (lastSeen != null &&
            ip != null &&
            now.difference(lastSeen).inSeconds <= 10) { // Consider online if seen in last 10s
          filteredMap[friend] = ip;
        }
      }
    }

    setState(() {
      onlineFriends = filteredMap.keys.toList();
      onlineFriendIPs = filteredMap;
    });
  });
}



  @override
  void dispose() {
    _onlineCheckTimer?.cancel(); // cancel the timer on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) 
  {
    return friends.isEmpty
        ? const Center(
            child: Text("No friends added yet.", style: TextStyle(color: Colors.white)))
        : ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              final isOnline = onlineFriends.contains(friend);
              return ListTile(
 onTap: () {
  final friendIp = onlineFriendIPs[friend] ?? '0.0.0.0'; // fallback if offline

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        myUsername: widget.username!,
        friendUsername: friend,
        friendIp: friendIp,
      ),
    ),
  );
},

  leading: CircleAvatar(
    backgroundColor: isOnline ? Colors.green : Colors.grey,
    radius: 6,
  ),
  title: Text(friend, style: const TextStyle(color: Colors.white)),
  subtitle: Text(
    isOnline ? 'Online' : 'Offline',
    style: TextStyle(color: isOnline ? Colors.green : Colors.grey),
  ),
);

            },
          );
  }
}
