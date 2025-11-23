import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

import '../api/http_chat_service.dart';
import '../api/chat_polling_controller.dart';
import 'package:mobile/pages/supplier_incidents_page.dart';
import 'package:mobile/pages/incident_details_page.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/session.dart';
import 'package:mobile/pages/consumer_incident_page.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String authorId;
  final bool isSupplier;
  final String? incidentDescription;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.authorId,
    required this.isSupplier, 
    this.incidentDescription,

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
void _showComplaintForm(BuildContext context) {
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: orderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Order ID",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: msgCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Complaint Message",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final orderId = int.tryParse(orderCtrl.text);
                    final msg = msgCtrl.text.trim();

                    if (orderId == null || msg.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill in all fields.")),
                      );
                      return;
                    }
                    
                    // API Call
                    final api = ApiClient.instance;
                    final rawUserId = await SessionService.instance.getUserId();
                    if (rawUserId == null) return;
                   final int userId = rawUserId is int
                        ? rawUserId
                        : int.parse(rawUserId.toString());
                    final ok = await api.createIncident(
                      userId: userId,
                      orderId: orderId,
                      message: msg,
                    );
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ok ? "Complaint submitted!" : "Failed to submit")),
                      );
                    }
                  },
                  child: const Text("Submit Complaint"),
                ),
              ),
            ],
          ),
        );
      },
    );
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

        showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        // Option 1: Submit New
                        ListTile(
                          leading: const Icon(Icons.add_circle_outline, color: Colors.red),
                          title: const Text("Submit New Complaint"),
                          onTap: () {
                            Navigator.pop(ctx); // Close menu
                            _showComplaintForm(context); // Open the form helper
                          },
                        ),
                        const Divider(),
                        // Option 2: View History (🟢 THIS IS THE NEW PART)
                        ListTile(
                          leading: const Icon(Icons.history, color: Colors.blue),
                          title: const Text("View My Complaints"),
                          onTap: () {
                            Navigator.pop(ctx); // Close menu
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ConsumerIncidentsPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      
      // Body Layout
      body: Column(
        children: [
          // 1. THE COMPLAINT HEADER
          if (widget.incidentDescription != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "⚠️ Complaint / Issue:",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.incidentDescription!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          // 2. YOUR CHAT WIDGET (Wrapped in Expanded)
          Expanded(
            child: Chat(
              chatController: _controller,
              currentUserId: widget.authorId,
              onMessageSend: _sendMessage,
              resolveUser: (id) async => User(id: id, name: "User $id"),
            ),
          ),
        ],
      ),
    );
  }
}
