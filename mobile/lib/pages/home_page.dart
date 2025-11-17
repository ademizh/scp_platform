import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/pages/login_page.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/session.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<String?> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('role');
    await prefs.remove('isLoggedIn');
    await prefs.remove('userId');
    await prefs.remove('supplierId');
    await prefs.remove('consumerId');
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');

    await SessionService.instance.logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(onTap: () {}),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCP'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _loadRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final role = snapshot.data;

          if (role == 'supplier') {
            return const SupplierHome();
          } else if (role == 'consumer') {
            return const ConsumerHome();
          } else {
            return const Center(
              child: Text(
                'Role not found. Please login again.',
                textAlign: TextAlign.center,
              ),
            );
          }
        },
      ),
    );
  }
}

// ---------------- Supplier home: incoming link requests ----------------

class SupplierHome extends StatefulWidget {
  const SupplierHome({super.key});

  @override
  State<SupplierHome> createState() => _SupplierHomeState();
}

class _SupplierHomeState extends State<SupplierHome> {
  bool _isLoading = true;
  String? _error;
  List<SupplierLinkRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final supplierId = await SessionService.instance.getSupplierId();
      if (supplierId == null) {
        setState(() {
          _error = 'Supplier id is missing in session.';
          _isLoading = false;
        });
        return;
      }

      final api = ApiClient.instance;
      final items = await api.getSupplierIncomingLinkRequests(supplierId);

      setState(() {
        _requests = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approve(int id) async {
    try {
      await ApiClient.instance.approveLinkRequest(id);
      await _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve request: $e')),
      );
    }
  }

  Future<void> _reject(int id) async {
    try {
      await ApiClient.instance.rejectLinkRequest(id);
      await _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_requests.isEmpty) {
      return const Center(
        child: Text('No pending link requests yet.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final req = _requests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(req.consumerName),
            subtitle: Text('Status: ${req.status}'),
            trailing: req.status == 'pending'
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () => _approve(req.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _reject(req.id),
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }
}

// ---------------- Consumer home: send link request ----------------

class ConsumerHome extends StatefulWidget {
  const ConsumerHome({super.key});

  @override
  State<ConsumerHome> createState() => _ConsumerHomeState();
}

class _ConsumerHomeState extends State<ConsumerHome> {
  final TextEditingController _supplierIdController = TextEditingController();
  bool _isSending = false;
  bool _isLoadingLinks = true;
  String? _error;
  int? _consumerId;
  List<ConsumerLink> _links = [];

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    try {
      final consumerId = await SessionService.instance.getConsumerId();
      if (consumerId == null) {
        setState(() {
          _error = 'Consumer id is missing in session.';
          _isLoadingLinks = false;
        });
        return;
      }

      _consumerId = consumerId;
      final items = await ApiClient.instance.getConsumerLinks(consumerId);

      setState(() {
        _links = items;
        _isLoadingLinks = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingLinks = false;
      });
    }
  }

  Future<void> _sendLinkRequest() async {
    if (_consumerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consumer id not found. Please relogin.')),
      );
      return;
    }

    final text = _supplierIdController.text.trim();
    final supplierId = int.tryParse(text);
    if (supplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a numeric supplier id.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final link = await ApiClient.instance.sendLinkRequest(
        consumerId: _consumerId!,
        supplierId: supplierId,
      );

      _supplierIdController.clear();

      setState(() {
        _links = [..._links, link];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link request sent.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _supplierIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLinks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Consumer Home Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Request access to a supplier catalog by its ID. '
            'Once the supplier approves your request, their catalog will become available.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _supplierIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Supplier ID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSending ? null : _sendLinkRequest,
                child: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send link request'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Your suppliers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_links.isEmpty)
            const Text('You have no supplier links yet.')
          else
            Expanded(
              child: ListView.builder(
                itemCount: _links.length,
                itemBuilder: (context, index) {
                  final link = _links[index];
                  return Card(
                    child: ListTile(
                      title: Text(link.supplierName),
                      subtitle: Text('Status: ${link.status}'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
