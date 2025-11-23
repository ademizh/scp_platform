import 'dart:async';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'http_chat_service.dart';

class ChatPollingController {
  final HttpChatService service;
  final StreamController<List<Message>> stream =
      StreamController.broadcast();

  Timer? _timer;

  ChatPollingController(this.service);

  void start() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final simpleMsgs = await service.loadMessages();

      final chatMsgs = simpleMsgs
          .map((m) => m.toTextMessage())
          .toList();

      stream.add(chatMsgs);
    });
  }

  void stop() => _timer?.cancel();
}
