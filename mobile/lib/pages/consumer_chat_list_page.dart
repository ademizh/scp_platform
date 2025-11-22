import 'package:flutter/material.dart';
import 'package:mobile/chat/screens/chat_screen.dart';
import 'package:mobile/services/api_client.dart'; 

class ConsumerChatListPage extends StatelessWidget {
  final int consumerId;
  final List<ConsumerLink> suppliers;

  const ConsumerChatListPage({
    super.key,
    required this.consumerId,
    required this.suppliers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Sales")),
      body: ListView.builder(
        itemCount: suppliers.length,
        itemBuilder: (_, index) {
          final s = suppliers[index];

          return ListTile(
            title: Text(s.supplierName),
            subtitle: Text("Supplier ID: ${s.supplierId}"),
            trailing: const Icon(Icons.chat_bubble),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatId: "supplier-${s.supplierId}-consumer-$consumerId",
                    authorId: consumerId.toString(),
                    isSupplier: false, 
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
