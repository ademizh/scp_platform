// lib/pages/supplier_homepage.dart
import 'package:flutter/material.dart';

import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/session.dart';
import 'package:mobile/pages/login_page.dart';

class SupplierHomePage extends StatefulWidget {
  final int userId;

  const SupplierHomePage({
    super.key,
    required this.userId,
  });

  @override
  State<SupplierHomePage> createState() => _SupplierHomePageState();
}

class _SupplierHomePageState extends State<SupplierHomePage> {
  int _supplierTabIndex = 0;

  bool _linksLoading = false;
  String? _linksError;
  List<SupplierLinkRequest> _linkRequests = [];

  bool _supplierOrdersLoading = false;
  String? _supplierOrdersError;
  List<Order> _supplierOrders = [];

  @override
  void initState() {
    super.initState();
    _loadSupplierLinks();
    _loadSupplierOrders();
  }

  Future<void> _logout() async {
    await SessionService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage(onTap: () {})),
      (route) => false,
    );
  }

  Future<void> _loadSupplierLinks() async {
    final supplierId = await SessionService.instance.getSupplierId();
    if (supplierId == null) {
      if (!mounted) return;
      setState(() {
        _linksError = 'No supplier id for this user';
      });
      return;
    }

    setState(() {
      _linksLoading = true;
      _linksError = null;
    });

    try {
      final links =
          await ApiClient.instance.getSupplierIncomingLinkRequests(supplierId);
      if (!mounted) return;
      setState(() {
        _linkRequests = links;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _linksError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _linksLoading = false;
      });
    }
  }

  Future<void> _approveLink(SupplierLinkRequest req) async {
    try {
      await ApiClient.instance.approveLinkRequest(req.id);
      await _loadSupplierLinks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link with ${req.consumerName} approved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve link: $e')),
      );
    }
  }

  Future<void> _rejectLink(SupplierLinkRequest req) async {
    try {
      await ApiClient.instance.rejectLinkRequest(req.id);
      await _loadSupplierLinks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link with ${req.consumerName} rejected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject link: $e')),
      );
    }
  }

  Future<void> _loadSupplierOrders() async {
    setState(() {
      _supplierOrdersLoading = true;
      _supplierOrdersError = null;
    });

    try {
      final orders =
          await ApiClient.instance.getSupplierOrders(userId: widget.userId);
      if (!mounted) return;
      setState(() {
        _supplierOrders = orders;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _supplierOrdersError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _supplierOrdersLoading = false;
      });
    }
  }

  Future<void> _acceptOrder(Order order) async {
    try {
      await ApiClient.instance.acceptOrder(
        userId: widget.userId,
        orderId: order.id,
      );
      await _loadSupplierOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #${order.id} accepted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept order: $e')),
      );
    }
  }

  Future<void> _rejectOrder(Order order) async {
    try {
      await ApiClient.instance.rejectOrder(
        userId: widget.userId,
        orderId: order.id,
      );
      await _loadSupplierOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #${order.id} rejected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final newOrdersCount =
        _supplierOrders.where((o) => o.status == 'pending').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SCP – Supplier'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _supplierTabIndex,
        children: [
          _buildSupplierLinks(),
          _buildSupplierOrders(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _supplierTabIndex,
        onTap: (index) {
          setState(() {
            _supplierTabIndex = index;
          });
          if (index == 0) {
            _loadSupplierLinks();
          } else if (index == 1) {
            _loadSupplierOrders();
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.link),
            label: 'Links',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: newOrdersCount > 0
                ? 'Orders ($newOrdersCount)'
                : 'Orders',
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierLinks() {
    if (_linksLoading && _linkRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_linksError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load link requests:\n$_linksError',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSupplierLinks,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_linkRequests.isEmpty) {
      return const Center(
        child: Text('No link requests yet.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSupplierLinks,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _linkRequests.length,
        itemBuilder: (context, index) {
          final req = _linkRequests[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(req.consumerName),
              subtitle: Text('Status: ${req.status}'),
              trailing: req.status == 'pending'
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _rejectLink(req),
                          child: const Text('Reject'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _approveLink(req),
                          child: const Text('Accept'),
                        ),
                      ],
                    )
                  : Text(
                      req.status,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSupplierOrders() {
    if (_supplierOrdersLoading && _supplierOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_supplierOrdersError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load orders:\n$_supplierOrdersError',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSupplierOrders,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_supplierOrders.isEmpty) {
      return const Center(
        child: Text('No orders yet.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSupplierOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _supplierOrders.length,
        itemBuilder: (context, index) {
          final order = _supplierOrders[index];
          final isPending = order.status == 'pending';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              title: Text('Order #${order.id} — ${order.status.toUpperCase()}'),
              subtitle: Text(
                'Consumer: ${order.consumerName}\n'
                'Total: ${order.totalAmount.toStringAsFixed(2)} ₸',
              ),
              children: [
                ...order.items.map(
                  (item) => ListTile(
                    title: Text(item.productName),
                    subtitle: Text(
                      '${item.quantity} ${item.unitCode} × ${item.unitPrice.toStringAsFixed(2)} ₸',
                    ),
                    trailing: Text(
                      '${item.lineTotal.toStringAsFixed(2)} ₸',
                    ),
                  ),
                ),
                if (isPending)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _rejectOrder(order),
                          child: const Text('Reject'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _acceptOrder(order),
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
