import 'package:dio/dio.dart';
import '../models/simple_message.dart';

class HttpChatService {
  final String baseUrl;
  final String chatId;
  final String authorId;

  final Dio dio = Dio();

  HttpChatService({
    required this.baseUrl,
    required this.chatId,
    required this.authorId,
  });

  Future<List<SimpleMessage>> loadMessages() async {
    final url = "$baseUrl/api/chat/$chatId/messages/";
    final response = await dio.get(url);

    return (response.data as List)
        .map((e) => SimpleMessage.fromJson(e))
        .toList();
  }

  Future<void> sendMessage(String text) async {
    final url = "$baseUrl/api/chat/$chatId/messages/";
    await dio.post(url, data: {
      "authorId": authorId,
      "text": text,
    });
  }
}
