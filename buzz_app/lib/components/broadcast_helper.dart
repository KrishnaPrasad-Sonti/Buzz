import 'dart:async';
import 'dart:convert';
import 'dart:io';

RawDatagramSocket? _broadcastSocket;
Timer? _backgroundBroadcastTimer;

/// Start background UDP broadcasting BUZZ::username every 8 seconds
Future<void> startBackgroundBroadcast(String username) async {
  // Cancel old timer if it exists
  _backgroundBroadcastTimer?.cancel();
  _broadcastSocket?.close();

  // Open socket
  _broadcastSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  _broadcastSocket!.broadcastEnabled = true;

  // Repeating timer to send presence
  _backgroundBroadcastTimer = Timer.periodic(const Duration(seconds: 8), (_) {
    final message = 'BUZZ::$username';
    final data = utf8.encode(message);
    _broadcastSocket!.send(data, InternetAddress('255.255.255.255'), 4445);
    
  });
}
