import 'dart:async';

import 'package:dio/dio.dart';
import 'package:cross_cache/cross_cache.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// CHAT MODELS
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
import 'package:flyer_chat_text_message/flyer_chat_text_message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/pages/supplier_incidents_page.dart';

// LOCAL PROJECT CHAT FILES
import 'package:mobile/chat/api/api_service.dart';
import 'package:mobile/chat/api/connection_status.dart';
import 'package:mobile/chat/api/upload_file.dart';
import 'package:mobile/chat/api/websocket_service.dart';
import 'package:mobile/chat/widgets/create_message.dart';

const baseUrl = 'https://whatever.diamanthq.dev';
const host = 'whatever.diamanthq.dev';

class Api extends StatefulWidget {
  final UserID currentUserId;
  final String chatId;
  final String? chatPartnerName;
  final List<Message> initialMessages;
  final Dio dio;

  const Api({
    super.key,
    required this.currentUserId,
    required this.chatId,
    required this.initialMessages,
    required this.dio,
    this.chatPartnerName,
  });

  @override
  ApiState createState() => ApiState();
}

class ApiState extends State<Api> {
  final _crossCache = CrossCache();
  final _uuid = const Uuid();

  final users = const {
    'john': User(id: 'john'),
    'jane': User(id: 'jane'),
  };

  late final ApiService _apiService;
  late final ChatWebSocketService _webSocketService;
  late final StreamSubscription<WebSocketEvent> _webSocketSubscription;
  late final ChatController _chatController;

  final TextEditingController _composerController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _chatController = InMemoryChatController(messages: widget.initialMessages);

    _apiService = ApiService(
      baseUrl: baseUrl,
      chatId: widget.chatId,
      dio: widget.dio,
    );

    _webSocketService = ChatWebSocketService(
      host: host,
      chatId: widget.chatId,
      authorId: widget.currentUserId,
    );

    _connectToWs();
  }

  @override
  void dispose() {
    _composerController.dispose();
    _webSocketSubscription.cancel();
    _webSocketService.dispose();
    _chatController.dispose();
    _crossCache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        title: Text(widget.chatPartnerName ?? "Chat"),
        actions: [
  IconButton(
    icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SupplierIncidentsPage()),
      );
    },
  ),
],

      ),
      body: Stack(
        children: [
          /// CHAT MESSAGES
          Positioned.fill(
            child: Chat(
              builders: Builders(
                textMessageBuilder: (context, message, index,
                        {required isSentByMe, groupStatus}) =>
                    FlyerChatTextMessage(message: message, index: index),
                imageMessageBuilder: (context, message, index,
                        {required isSentByMe, groupStatus}) =>
                    FlyerChatImageMessage(message: message, index: index),
              ),
              chatController: _chatController,
              crossCache: _crossCache,
              currentUserId: widget.currentUserId,
              onAttachmentTap: _handleAttachmentTap,
              onMessageSend: _addItem,
              onMessageTap: _removeItem,
              resolveUser: (id) => Future.value(users[id]),
              theme: ChatTheme.fromThemeData(theme),
            ),
          ),

          /// CONNECTION STATUS (top-left)
          Positioned(
            top: 16,
            left: 16,
            child: ConnectionStatus(webSocketService: _webSocketService),
          ),

          /// CUSTOM INPUT BAR (bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildInputBar(),
          ),
        ],
      ),
    );
  }

  /// --------------------------------------------
  /// WEB SOCKET
  /// --------------------------------------------
  void _connectToWs() {
    _webSocketSubscription = _webSocketService.connect().listen((event) {
      if (!mounted) return;

      switch (event.type) {
        case WebSocketEventType.newMessage:
          _chatController.insertMessage(event.message!);
          break;
        case WebSocketEventType.deleteMessage:
          _chatController.removeMessage(event.message!);
          break;
        case WebSocketEventType.flush:
          _chatController.setMessages([]);
          break;
        case WebSocketEventType.error:
          _showInfo("Error: ${event.error}");
          break;
        case WebSocketEventType.unknown:
          break;
      }
    });
  }

  /// --------------------------------------------
  /// SEND MESSAGE
  /// --------------------------------------------
  void _addItem(String? text) async {
    if (text == null || text.trim().isEmpty) return;

    final message = await createMessage(
      widget.currentUserId,
      widget.dio,
      text: text.trim(),
    );

    final originalMetadata = message.metadata;

    await _chatController.insertMessage(
      message.copyWith(metadata: {...?originalMetadata, 'sending': true}),
    );

    try {
      final response = await _apiService.send(message);

      final oldMessage = _chatController.messages.firstWhere(
        (m) => m.id == message.id,
        orElse: () => message,
      );

      final updated = oldMessage.copyWith(
        id: response['id'],
        createdAt: null,
        sentAt: DateTime.fromMillisecondsSinceEpoch(response['ts'], isUtc: true),
        metadata: originalMetadata,
      );

      await _chatController.updateMessage(oldMessage, updated);
    } catch (e) {
      debugPrint("Send error: $e");
    }
  }

  /// --------------------------------------------
  /// ATTACH IMAGE
  /// --------------------------------------------
  void _handleAttachmentTap() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    await _crossCache.set(image.path, bytes);

    final id = _uuid.v4();

    final imageMessage = ImageMessage(
      id: id,
      authorId: widget.currentUserId,
      createdAt: DateTime.now().toUtc(),
      source: image.path,
    );

    await _chatController.insertMessage(imageMessage);

    try {
      final upload = await uploadFile(image.path, bytes, id, _chatController);
      final newUrl = "https://whatever.diamanthq.dev/blob/${upload['blob_id']}";

      final current = _chatController.messages
              .firstWhere((m) => m.id == id, orElse: () => imageMessage)
          as ImageMessage;
      final original = current.metadata;

      await _crossCache.set(newUrl, bytes);

      final updated = current.copyWith(source: newUrl);
      await _chatController.updateMessage(
        current,
        updated.copyWith(metadata: {...?original, 'sending': true}),
      );

      final response = await _apiService.send(updated);
      final confirmed = updated.copyWith(
        id: response['id'],
        createdAt: null,
        sentAt: DateTime.fromMillisecondsSinceEpoch(response['ts'], isUtc: true),
        metadata: original,
      );

      await _chatController.updateMessage(updated, confirmed);
    } catch (e) {
      debugPrint("Image send error: $e");
    }
  }

  /// --------------------------------------------
  /// REMOVE MESSAGE
  /// --------------------------------------------
  void _removeItem(BuildContext context, Message msg,
      {int? index, TapUpDetails? details}) async {
    await _chatController.removeMessage(msg);
    try {
      await _apiService.delete(msg);
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  /// --------------------------------------------
  /// CUSTOM INPUT BAR
  /// --------------------------------------------
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.black.withOpacity(0.85),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.white),
            onPressed: _handleAttachmentTap,
          ),

          Expanded(
            child: TextField(
              controller: _composerController,
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Message...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  _addItem(text);
                  _composerController.clear();
                }
              },
            ),
          ),

          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: () {
              final text = _composerController.text.trim();
              if (text.isNotEmpty) {
                _addItem(text);
                _composerController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showInfo(String message) async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Info"),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }
}
