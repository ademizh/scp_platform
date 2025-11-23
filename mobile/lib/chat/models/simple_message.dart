import 'package:flutter_chat_core/flutter_chat_core.dart';

class SimpleMessage {
  final String id;
  final String authorId;
  final String text;
  final int createdAt;

  SimpleMessage({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
  });

  factory SimpleMessage.fromJson(Map<String, dynamic> json) {
    return SimpleMessage(
      id: json["id"],
      authorId: json["authorId"],
      text: json["text"] ?? "",
      createdAt: json["createdAt"],
    );
  }

  TextMessage toTextMessage() {
    return TextMessage(
      id: id,
      authorId: authorId,
      text: text,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true),
    );
  }
}
