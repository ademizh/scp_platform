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
  List<ConsumerLink> _links = [];

  int? _consumerId;
  bool _sendingRequest = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Берём consumerId из сессии
      final consumerId = await SessionService.instance.getConsumerId();
      if (consumerId == null) {
        if (!mounted) return;
        setState(() {
          _error =
              'Consumer id not found. Please re-login as consumer.'; // как и раньше
          _loading = false;
        });
        return;
      }

      // Тянем всех поставщиков (как и раньше)
      final suppliers = await ApiClient.instance.getSuppliersDirectory();

      // Тянем все линки этого consumer’а
      final links =
          await ApiClient.instance.getConsumerLinks(consumerId: consumerId);

      if (!mounted) return;
      setState(() {
        _consumerId = consumerId;
        _suppliers = suppliers;
        _links = links;
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

  Future<void> _refresh() => _load();

  // Находим линк по поставщику (если есть)
  ConsumerLink? _linkForSupplier(int supplierId) {
    try {
      return _links.firstWhere((l) => l.supplierId == supplierId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _requestLink(int supplierId) async {
    if (_consumerId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Consumer id not found. Please re-login as consumer.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _sendingRequest = true;
    });

    try {
      await ApiClient.instance.sendLinkRequest(
        consumerId: _consumerId!,
        supplierId: supplierId,
      );

      // после отправки обновляем список линков
      final links =
          await ApiClient.instance.getConsumerLinks(consumerId: _consumerId!);

      if (!mounted) return;
      setState(() {
        _links = links;
      });

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
    } finally {
      if (!mounted) return;
      setState(() {
        _sendingRequest = false;
      });
    }
  }

  // Кнопка со статусом: Connect / Pending / Accepted / Rejected
  Widget _buildStatusButton(SupplierInfo supplier) {
    final link = _linkForSupplier(supplier.id);

    String label;
    VoidCallback? onPressed;

    switch (link?.status) {
      case 'pending':
        label = 'Pending';
        onPressed = null; // ждём, нельзя нажимать
        break;
      case 'accepted':
        label = 'Accepted';
        onPressed = null; // уже связаны
        break;
      case 'rejected':
        label = 'Rejected';
        onPressed = null;
        // если захочешь повторный запрос:
        // onPressed = _sendingRequest ? null : () => _requestLink(supplier.id);
        break;
      default:
        label = 'Connect';
        onPressed =
            _sendingRequest ? null : () => _requestLink(supplier.id);
    }

    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          itemCount: _suppliers.length,
          itemBuilder: (context, index) {
            final supplier = _suppliers[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(supplier.name),
                subtitle: Text('ID: ${supplier.id}'),
                trailing: _buildStatusButton(supplier),
              ),
            );
          },
        ),
      ),
    );
  }
}
