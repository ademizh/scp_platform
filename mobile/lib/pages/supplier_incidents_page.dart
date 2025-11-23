import 'package:flutter/material.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/pages/incident_details_page.dart';
import 'package:mobile/services/session.dart'; 

class SupplierIncidentsPage extends StatefulWidget {
  @override
  _SupplierIncidentsPageState createState() => _SupplierIncidentsPageState();
}

class _SupplierIncidentsPageState extends State<SupplierIncidentsPage> {
  // 1. Define your variables here
  List<Incident> incidents = [];
  final api = ApiClient.instance;
  
  // 🟢 FIX: Define the _isLoading variable here
  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      int? supplierId = await SessionService.instance.getSupplierId();
      int? userId = await SessionService.instance.getUserId(); 

      print("DEBUG: User: $userId, Supplier: $supplierId");
      if (supplierId != null && userId != null) {
        final data = await api.getSupplierIncidents(userId, supplierId);
        print("DEBUG: API returned ${data.length} incidents");
        if (mounted) {
          setState(() {
            incidents = data;
            _isLoading = false; // Now this works because the variable exists
          });
        }
      } else {
        print("DEBUG: ERROR - Supplier ID is NULL. Are you logged in as a Supplier?");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("DEBUG: EXCEPTION: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complaints")),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : incidents.isEmpty 
              ? const Center(child: Text("No complaints found"))
              : ListView.builder(
                  itemCount: incidents.length,
                  itemBuilder: (_, i) {
                    final inc = incidents[i];
                    return ListTile(
                      title: Text("Order #${inc.orderId}"),
                      subtitle: Text(inc.message),
                      trailing: Text(
                        inc.status.toUpperCase(),
                        style: TextStyle(
                          color: inc.status == 'open' ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () async {
                        // Wait for the detail page to close
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => IncidentDetailsPage(incident: inc),
                          ),
                        );
                        
                        // 🟢 REFRESH THE LIST after coming back
                        _load(); 
                      },
                      
                    );
                  },
                ),
    );
  }
}