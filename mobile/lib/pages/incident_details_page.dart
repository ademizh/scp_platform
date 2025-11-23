import 'package:flutter/material.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/session.dart';
import '../../chat/screens/chat_screen.dart';

class IncidentDetailsPage extends StatefulWidget {
  final Incident incident;

  const IncidentDetailsPage({super.key, required this.incident});

  @override
  _IncidentDetailsPageState createState() => _IncidentDetailsPageState();
}

class _IncidentDetailsPageState extends State<IncidentDetailsPage> {
  late String _status;
  bool _isUpdating = false;
  bool _isSupplier = false;
  @override
  void initState() {
    super.initState();
    _status = widget.incident.status;
    _checkRole();
  }
  Future<void> _checkRole() async {
    
    final supplierId = await SessionService.instance.getSupplierId();
    if (mounted) {
      setState(() {
        _isSupplier = supplierId != null;
      });
    }
  }

  
  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      final userId = await SessionService.instance.getUserId();
      
      if (userId != null) {
        final success = await ApiClient.instance.updateIncidentStatus(
          userId, 
          widget.incident.id, 
          newStatus
        );
        
        if (success) {
          setState(() => _status = newStatus);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Status updated to $newStatus"))
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to update status"))
            );
          }
        }
      }
    } catch (e) {
      print("Error updating status: $e");
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }


  Future<void> _escalate() async {
    setState(() => _isUpdating = true);
    try {
      final userId = await SessionService.instance.getUserId();
      if (userId != null) {
        final success = await ApiClient.instance.escalateIncident(userId, widget.incident.id);
        
        if (success) {
          setState(() => _status = 'open'); 
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Escalated to Manager (Unassigned)"))
            );
            Navigator.pop(context); 
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to escalate"))
            );
          }
        }
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order #${widget.incident.orderId}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _status == 'open' ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Status: ${_status.toUpperCase()}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _status == 'open' ? Colors.red.shade900 : Colors.green.shade900,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
           
            const Text("Complaint:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.incident.message, style: const TextStyle(fontSize: 16)),
            
            const SizedBox(height: 10),
            Text("Created By User ID: ${widget.incident.createdBy}"),

            const SizedBox(height: 30),

            
            if (_isSupplier &&_status != 'resolved') ...[
              const Text("Actions:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
             
              Row(
                children: [
                  if (_status == 'open')
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        onPressed: _isUpdating ? null : () => _updateStatus('in_progress'),
                        child: const Text("Take It", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  
                  if (_status == 'open') const SizedBox(width: 8),

                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: _isUpdating ? null : () => _updateStatus('resolved'),
                      child: const Text("Resolve", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),

              // Escalate Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  label: const Text("Escalate to Manager", style: TextStyle(color: Colors.orange)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                  ),
                  onPressed: _isUpdating ? null : _escalate,
                ),
              ),
            ],

            const Spacer(),

           
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text("Open Chat"),
                onPressed: () async {
                  final userId = await SessionService.instance.getUserId();
                  if (context.mounted && userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: "incident-${widget.incident.id}",
                          authorId: userId.toString(),
                          isSupplier: true, 
                          incidentDescription: widget.incident.message,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ], 
        ),
      ),
    );
  }
}