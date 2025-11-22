import 'package:flutter/material.dart';

import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/session.dart';
import '../../chat/screens/chat_screen.dart'; // ← новый путь к чату

class SupplierChatListPage extends StatefulWidget {
  const SupplierChatListPage({super.key});

  @override
  State<SupplierChatListPage> createState() => _SupplierChatListPageState();
}

class _SupplierChatListPageState extends State<SupplierChatListPage> {
  bool loading = true;
  List<SupplierLinkRequest> approved = [];
  int? supplierId;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    supplierId = await SessionService.instance.getSupplierId();
    if (supplierId == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final links =
          await ApiClient.instance.getSupplierIncomingLinkRequests(supplierId!);

      approved = links.where((l) => l.status == "accepted").toList();

      setState(() => loading = false);
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (approved.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No approved consumers to chat with.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: ListView.builder(
        itemCount: approved.length,
        itemBuilder: (_, i) {
          final link = approved[i];

          return ListTile(
            title: Text(link.consumerName),
            subtitle: Text("Consumer ID: ${link.consumerId}"),
            trailing: const Icon(Icons.chat),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatId: "supplier-$supplierId-consumer-${link.consumerId}",
                    authorId: supplierId.toString(),
                    isSupplier: true, 
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
