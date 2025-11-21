import 'package:flutter/material.dart';
import 'package:mobile/chat/api/api.dart';
import 'package:dio/dio.dart';
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
      appBar: AppBar(title: const Text("Your Suppliers")),
      body: ListView.builder(
        itemCount: suppliers.length,
        itemBuilder: (_, index) {
          final s = suppliers[index];

          return ListTile(
            title: Text(s.supplierName),
            subtitle: Text("Supplier ID: ${s.supplierId}"),
            trailing: const Icon(Icons.chat_bubble),
            onTap: () {
              final dio = Dio(); // must be new

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Api(
                    currentUserId: consumerId.toString(),
                    chatId:
                        "supplier-${s.supplierId}-consumer-$consumerId",
                    chatPartnerName: s.supplierName,
                    initialMessages: const [],
                    dio: dio,
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
