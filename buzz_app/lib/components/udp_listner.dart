import 'dart:convert';
import 'dart:io';

import 'package:buzz_app/models/message_model.dart';
import 'package:buzz_app/screens/chat_manager.dart';


class UDPListener {
  static final UDPListener _instance = UDPListener._internal();
  factory UDPListener() => _instance;
  UDPListener._internal();

  RawDatagramSocket? _socket;
  final int port = 4445;

  Future<void> startListening() async {
    if (_socket != null) return; // Already listening

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      print('✅ UDP Listener started on port $port');

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram == null) return;

          final messageString = utf8.decode(datagram.data);
          print('📩 Received UDP message: $messageString');

          try {
            final decoded = json.decode(messageString);
            final message = ChatMessageModel(
              sender: decoded['sender'],
              receiver: decoded['receiver'],
              message: decoded['message'],
              timestamp: DateTime.parse(decoded['timestamp']),
            );

            // Save to local chat
            ChatManager().addMessage(message);

            // TODO: You can notify chat UI here using a stream or callback if needed
          } catch (e) {
            print('⚠️ Error decoding UDP message: $e');
          }
        }
      });
    } catch (e) {
      print('❌ Failed to start UDP listener: $e');
    }
  }

  void stopListening() {
    _socket?.close();
    _socket = null;
    print('🛑 UDP Listener stopped');
  }
}
