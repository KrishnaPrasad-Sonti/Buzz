import 'dart:convert';
import 'dart:io';

import 'package:buzz_app/models/message_model.dart';
import 'package:buzz_app/screens/chat_manager.dart';


class MessageUDPService {
  static final MessageUDPService _instance = MessageUDPService._internal();
  factory MessageUDPService() => _instance;
  MessageUDPService._internal();

  RawDatagramSocket? _socket;
  final int port = 4567; // You can change this if needed

  Future<void> startListening(
    String currentUsername,
    void Function(ChatMessageModel) onMessageReceived,
  ) async {
  _socket ??= await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
  _socket!.listen((RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = _socket!.receive();
      if (datagram != null) {
        try {
          final decoded = jsonDecode(utf8.decode(datagram.data));
          if (decoded["type"] == "message") {
            final msg = ChatMessageModel(
              sender: decoded["sender"],
              receiver: decoded["receiver"],
              message: decoded["message"],
              timestamp: DateTime.parse(decoded["timestamp"]),
            );

            // Don't process your own message
            if (msg.sender != currentUsername) {
              ChatManager().addMessage(msg);
              onMessageReceived(msg);
            }
          }
        } catch (e) {
          print("Error decoding message: $e");
        }
      }
    }
  });
}


  void sendMessage(ChatMessageModel msg, InternetAddress targetIP) {
    final jsonString = jsonEncode({
      "type": "message",
      "sender": msg.sender,
      "receiver": msg.receiver,
      "message": msg.message,
      "timestamp": msg.timestamp.toIso8601String(),
    });

    final data = utf8.encode(jsonString);
    _socket?.send(data, targetIP, port);
  }
}
