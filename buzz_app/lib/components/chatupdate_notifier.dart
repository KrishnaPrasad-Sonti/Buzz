import 'package:flutter/foundation.dart';
import 'package:buzz_app/models/message_model.dart';

class ChatUpdateNotifier extends ChangeNotifier {
  ChatMessageModel? _lastMessage;

  ChatMessageModel? get lastMessage => _lastMessage;

  void notifyMessageReceived(ChatMessageModel message) {
    _lastMessage = message;
    notifyListeners();
  }
}
