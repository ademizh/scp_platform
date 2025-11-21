import 'package:flutter/material.dart';
import 'package:mobile/services/api_client.dart';

class IncidentDetailsPage extends StatefulWidget {
  final Incident incident;
  const IncidentDetailsPage({required this.incident});

  @override
  _IncidentDetailsPageState createState() => _IncidentDetailsPageState();
}

class _IncidentDetailsPageState extends State<IncidentDetailsPage> {
  final api = ApiClient.instance;

  @override
  Widget build(BuildContext context) {
    final inc = widget.incident;

    return Scaffold(
      appBar: AppBar(title: Text("Complaint #${inc.id}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order: ${inc.orderId}", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("Message: ${inc.message}"),
            const SizedBox(height: 8),
            Text("Status: ${inc.status.toUpperCase()}",
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                await api.updateIncidentStatus(inc.id, "resolved");
                Navigator.pop(context);
              },
              child: const Text("Mark Resolved"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await api.escalateIncident(inc.id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text("Escalate to Manager"),
            ),
          ],
        ),
      ),
    );
  }
}
