class ChatMessageModel {
  final String sender;
  final String receiver;
  final String message;
  final DateTime timestamp;

  ChatMessageModel({
    required this.sender,
    required this.receiver,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'sender': sender,
        'receiver': receiver,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      sender: json['sender'],
      receiver: json['receiver'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
