import 'dart:convert';
import 'package:buzz_app/models/message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatManager {
  static final ChatManager _instance = ChatManager._internal();
  factory ChatManager() => _instance;
  ChatManager._internal();

  final Map<String, List<ChatMessageModel>> _chatMap = {};

  // Key format: same for sender|receiver and receiver|sender for simplicity
  String _getChatKey(String user1, String user2) {
    final sorted = [user1, user2]..sort(); // alphabetical order
    return '${sorted[0]}|${sorted[1]}';
  }

  Future<void> addMessage(ChatMessageModel msg) async {
    final key = _getChatKey(msg.sender, msg.receiver);
    _chatMap.putIfAbsent(key, () => []);
    final messages = _chatMap[key]!;

    messages.add(msg);
    print("💾 ChatManager: Added message to $key");

    if (messages.length > 20) {
      messages.removeAt(0); // keep only last 50 messages
      print("🧹 ChatManager: Trimmed message list to last 50");
    }

    await _saveMessages(key, messages);
    print("✅ ChatManager: Message saved to SharedPreferences");
  }

  List<ChatMessageModel> getMessages(String user1, String user2) {
    final key = _getChatKey(user1, user2);
    return _chatMap[key] ?? [];
  }

  Future<void> loadMessages(String user1, String user2) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getChatKey(user1, user2);
    final data = prefs.getString(key);

    if (data != null) {
      List<dynamic> jsonList = jsonDecode(data);
      _chatMap[key] = jsonList
          .map((json) => ChatMessageModel.fromJson(json))
          .toList();
    }
  }

  Future<void> _saveMessages(String key, List<ChatMessageModel> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages.map((m) => m.toJson()).toList();
    prefs.setString(key, jsonEncode(jsonList));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _chatMap.keys) {
      await prefs.remove(key);
    }
    _chatMap.clear();
  }
}
