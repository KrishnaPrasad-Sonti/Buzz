import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:buzz_app/components/chatupdate_notifier.dart';
import 'package:buzz_app/models/message_model.dart';
import 'package:buzz_app/screens/chat_manager.dart';

import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String myUsername;
  final String friendUsername;
  final String friendIp;

  const ChatScreen({
    super.key,
    required this.myUsername,
    required this.friendUsername,
    required this.friendIp,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<ChatMessageModel> _messages = [];
  RawDatagramSocket? _udpSocket;

  late final ChatUpdateNotifier _chatUpdateNotifier; // <-- Notifier instance
  late final VoidCallback _chatListener; // <-- Listener callback

  @override
  void initState() {
    super.initState();  
    _loadChatHistory();
    _initUdpSocket();

    _chatUpdateNotifier = ChatUpdateNotifier();
    _chatListener = () {
      // Check if new message is for this conversation
      final lastMsg = _chatUpdateNotifier.lastMessage;
      if (lastMsg != null &&
          ((lastMsg.sender == widget.friendUsername && lastMsg.receiver == widget.myUsername) ||
           (lastMsg.sender == widget.myUsername && lastMsg.receiver == widget.friendUsername))) {
        setState(() {
          _messages = ChatManager().getMessages(widget.myUsername, widget.friendUsername);
        });
      }
    };

    _chatUpdateNotifier.addListener(_chatListener); // Start listening
  }

  @override
  void dispose() {
    _udpSocket?.close();
    _chatUpdateNotifier.removeListener(_chatListener); // Clean up listener
    super.dispose();
  }
Future<void> _initUdpSocket() async {
  try {
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4445); // ✅ BIND TO 4445
    print("✅ UDP socket bound to ${_udpSocket?.address.address}:${_udpSocket?.port}");

    _udpSocket?.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = _udpSocket?.receive();
        if (dg != null) {
          final jsonString = utf8.decode(dg.data);
          print("📩 Received UDP data: $jsonString from ${dg.address.address}");

          try {
            final decoded = jsonDecode(jsonString);
            final msg = ChatMessageModel(
              sender: decoded['sender'],
              receiver: decoded['receiver'],
              message: decoded['message'],
              timestamp: DateTime.parse(decoded['timestamp']),
            );

            // Save received message
            ChatManager().addMessage(msg).then((_) {
              print("📝 Stored message from ${msg.sender}");
              _chatUpdateNotifier.notifyMessageReceived(msg);
            });

          } catch (e) {
            print("❌ Failed to decode message: $e");
          }
        }
      }
    });
  } catch (e) {
    print("❌ Failed to bind UDP socket: $e");
  }
}


  Future<void> _loadChatHistory() async {
    await ChatManager().loadMessages(widget.myUsername, widget.friendUsername);
    setState(() {
      _messages = ChatManager().getMessages(widget.myUsername, widget.friendUsername);
    });
  }

Future<void> _sendMessage() async {
  final text = _controller.text.trim();
  if (text.isEmpty || _udpSocket == null) {
    print("⚠️ Message is empty or socket is null");
    return;
  }

  final msg = ChatMessageModel(
    sender: widget.myUsername,
    receiver: widget.friendUsername,
    message: text,
    timestamp: DateTime.now(),
  );

  await ChatManager().addMessage(msg);
  print("🚀 Sending message: '${msg.message}' to ${widget.friendIp}:4445");

  try {
    final String jsonData = jsonEncode({
      'sender': msg.sender,
      'receiver': msg.receiver,
      'message': msg.message,
      'timestamp': msg.timestamp.toIso8601String(),
    });

    final data = utf8.encode(jsonData);
    final targetAddress = InternetAddress(widget.friendIp);
    const int targetPort = 4445;

    _udpSocket!.send(data, targetAddress, targetPort);
    print("✅ UDP packet sent to $targetAddress:$targetPort");
  } catch (e) {
    print("❌ UDP send failed: $e");
  }

  setState(() {
    _messages.add(msg);
    _controller.clear();
  });
}


 Widget _buildMessageBubble(ChatMessageModel msg) {
  final isMe = msg.sender == widget.myUsername;
  return Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFD1C4E9) : const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isMe ? 12 : 0),
          bottomRight: Radius.circular(isMe ? 0 : 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(1, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        msg.message,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    ),
  );
}


  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF3E5F5), // light violet background
    appBar: AppBar(
      title: Text(widget.friendUsername),
      backgroundColor: const Color(0xFF7E57C2), // deep violet
      foregroundColor: Colors.white,
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: false,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return _buildMessageBubble(_messages[index]);
            },
          ),
        ),
        const Divider(height: 1),
        Container(
          color: const Color(0xFFE1BEE7), // input row light violet
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Type a message",
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
                color: const Color(0xFF7E57C2), // send button violet
              ),
            ],
          ),
        )
      ],
    ),
  );
}

}
