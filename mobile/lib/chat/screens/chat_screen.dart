import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

import '../api/http_chat_service.dart';
import '../api/chat_polling_controller.dart';
import 'package:mobile/pages/supplier_incidents_page.dart';
import 'package:mobile/pages/incident_details_page.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/session.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String authorId;
  final bool isSupplier;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.authorId,
    required this.isSupplier, 

  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late HttpChatService api;
  late ChatPollingController polling;

  final InMemoryChatController _controller = InMemoryChatController();

  @override
  void initState() {
    super.initState();

    api = HttpChatService(
      baseUrl: "http://localhost:8000",
      chatId: widget.chatId,
      authorId: widget.authorId,
    );

    polling = ChatPollingController(api);
    polling.start();

    polling.stream.stream.listen((msgs) {
      _controller.setMessages(msgs);   // <<< FIX
    });
  }

  @override
  void dispose() {
    polling.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    await api.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  title: const Text("Chat"),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => Navigator.pop(context),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.report_problem_outlined),
      onPressed: () async {
        // ==========================
        //   SUPPLIER → open list
        // ==========================
        if (widget.isSupplier) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SupplierIncidentsPage(),
            ),
          );
          return;
        }

        // ==========================
        //   CONSUMER → open COMPLAINT FORM
        // ==========================

        final TextEditingController orderCtrl = TextEditingController();
        final TextEditingController msgCtrl = TextEditingController();

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (_) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Submit a Complaint",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ORDER ID
                  TextField(
                    controller: orderCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Order ID",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // MESSAGE
                  TextField(
                    controller: msgCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Complaint Message",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final orderId = int.tryParse(orderCtrl.text);
                        final msg = msgCtrl.text.trim();

                        if (orderId == null || msg.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fill in all fields."),
                            ),
                          );
                          return;
                        }

                        final api = ApiClient.instance;
                        final ok = await api.createIncident(orderId, msg);

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? "Complaint submitted!"
                                : "Failed to submit"),
                          ),
                        );
                      },
                      child: const Text("Submit Complaint"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  ],
),






      body: Chat(
        chatController: _controller,
        currentUserId: widget.authorId,
        onMessageSend: _sendMessage,
        resolveUser: (id) async => User(id: id, name: "User $id"),
      ),
    );
  }
}
