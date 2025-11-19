import 'package:flutter/material.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/session.dart';

class SupplierDirectoryPage extends StatefulWidget {
  const SupplierDirectoryPage({super.key});

  @override
  State<SupplierDirectoryPage> createState() => _SupplierDirectoryPageState();
}

class _SupplierDirectoryPageState extends State<SupplierDirectoryPage> {
  bool _loading = true;
  String? _error;
  List<SupplierInfo> _suppliers = [];
  int? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userId = await SessionService.instance.getUserId();
      if (userId == null) {
        setState(() {
          _error = 'User not logged in';
          _loading = false;
        });
        return;
      }

      final suppliers = await ApiClient.instance.getSuppliersDirectory();

      if (!mounted) return;
      setState(() {
        _userId = userId;
        _suppliers = suppliers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
  Future<void> _requestLink(int supplierId) async {
    final consumerId = await SessionService.instance.getConsumerId();
    if (consumerId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consumer id not found. Please re-login as consumer.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ApiClient.instance.sendLinkRequest(
        consumerId: consumerId,
        supplierId: supplierId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link request sent'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Find Suppliers')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Find Suppliers')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load suppliers:\n$_error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      body: ListView.builder(
        itemCount: _suppliers.length,
        itemBuilder: (context, index) {
          final supplier = _suppliers[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(supplier.name),
              subtitle: Text('ID: ${supplier.id}'),
              trailing: ElevatedButton(
                onPressed: () => _requestLink(supplier.id),
                child: const Text('Connect'),
              ),
            ),
          );
        },
      ),
    );
  }
}
