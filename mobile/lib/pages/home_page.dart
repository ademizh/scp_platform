import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/pages/login_page.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/session.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _initialLoading = true;
  String? _initError;

  int? _userId;
  String? _loginRole; // 'consumer' or 'supplier'

  // ---------- Consumer state ----------
  int _consumerTabIndex = 0;
  bool _catalogLoading = false;
  String? _catalogError;
  List<Product> _catalog = [];
  final Map<int, double> _cart = {}; // productId -> quantity
  bool _placingOrder = false;

  bool _consumerOrdersLoading = false;
  String? _consumerOrdersError;
  List<Order> _consumerOrders = [];

  // ---------- Supplier state ----------
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
    _init();
  }

  Future<void> _init() async {
    try {
      final userId = await SessionService.instance.getUserId();
      if (userId == null) {
        _goToLogin();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      String? loginRole = prefs.getString('role');

      final roles = await SessionService.instance.getRoles();
      if (loginRole == null) {
        if (roles.contains('consumer')) {
          loginRole = 'consumer';
        } else if (roles.contains('supplier')) {
          loginRole = 'supplier';
        }
      }

      setState(() {
        _userId = userId;
        _loginRole = loginRole ?? 'consumer';
        _initialLoading = false;
      });

      if (_loginRole == 'consumer') {
        await Future.wait([
          _loadCatalog(),
          _loadConsumerOrders(),
        ]);
      } else if (_loginRole == 'supplier') {
        await Future.wait([
          _loadSupplierLinks(),
          _loadSupplierOrders(),
        ]);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = e.toString();
        _initialLoading = false;
      });
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(onTap: () {}),
      ),
      (route) => false,
    );
  }

  Future<void> _logout() async {
    await SessionService.instance.logout();
    _goToLogin();
  }

  // ============================================================
  //                      CONSUMER: CATALOG
  // ============================================================

  Future<void> _loadCatalog() async {
    if (_userId == null) return;
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });

    try {
      final products = await ApiClient.instance.getCatalog(userId: _userId!);
      if (!mounted) return;
      setState(() {
        _catalog = products;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _catalogLoading = false;
      });
    }
  }

  void _addToCart(Product product) {
    setState(() {
      final current = _cart[product.id] ?? 0.0;
      _cart[product.id] = current + 1.0;
    });
  }

  void _decreaseCart(Product product) {
    setState(() {
      final current = _cart[product.id] ?? 0.0;
      if (current <= 1.0) {
        _cart.remove(product.id);
      } else {
        _cart[product.id] = current - 1.0;
      }
    });
  }

  Product? _findProduct(int productId) {
    try {
      return _catalog.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  String _formatPrice(Product p) {
    final price = p.price;
    if (price == null) return 'No price';
    if (p.discount > 0) {
      final discounted = price * (1 - p.discount / 100);
      return '${discounted.toStringAsFixed(2)} ₸ (-${p.discount.toStringAsFixed(0)}%)';
    }
    return '${price.toStringAsFixed(2)} ₸';
  }

  String _formatProductSubtitle(Product p) {
    final stockText = 'In stock: ${p.stock.toStringAsFixed(1)} ${p.unitCode}';
    final delivery =
        p.deliveryTime != null ? 'Delivery: ${p.deliveryTime} min' : '';
    return [stockText, delivery].where((s) => s.isNotEmpty).join(' • ');
  }

  // ============================================================
  //                      CONSUMER: ORDERS
  // ============================================================

  Future<void> _loadConsumerOrders() async {
    if (_userId == null) return;
    setState(() {
      _consumerOrdersLoading = true;
      _consumerOrdersError = null;
    });

    try {
      final orders =
          await ApiClient.instance.getConsumerOrders(userId: _userId!);
      if (!mounted) return;
      setState(() {
        _consumerOrders = orders;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _consumerOrdersError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _consumerOrdersLoading = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_userId == null) return;
    if (_cart.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    setState(() {
      _placingOrder = true;
    });

    try {
      final items = _cart.entries
          .map(
            (e) => OrderItemInput(
              productId: e.key,
              quantity: e.value,
            ),
          )
          .toList();

      final order = await ApiClient.instance.createOrder(
        userId: _userId!,
        items: items,
      );

      if (!mounted) return;
      setState(() {
        _cart.clear();
      });
      await _loadConsumerOrders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #${order.id} created')),
      );
      setState(() {
        _consumerTabIndex = 2; // switch to "My Orders"
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create order: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _placingOrder = false;
      });
    }
  }

  // ============================================================
  //                      SUPPLIER: LINKS
  // ============================================================

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

  // ============================================================
  //                      SUPPLIER: ORDERS
  // ============================================================

  Future<void> _loadSupplierOrders() async {
    if (_userId == null) return;
    setState(() {
      _supplierOrdersLoading = true;
      _supplierOrdersError = null;
    });

    try {
      final orders =
          await ApiClient.instance.getSupplierOrders(userId: _userId!);
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
    if (_userId == null) return;
    try {
      await ApiClient.instance.acceptOrder(
        userId: _userId!,
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
    if (_userId == null) return;
    try {
      await ApiClient.instance.rejectOrder(
        userId: _userId!,
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

  // ============================================================
  //                          BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('SCP')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Initialization error:\n$_initError',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _init,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loginRole == 'supplier') {
      return _buildSupplierScaffold();
    }

    // default: consumer
    return _buildConsumerScaffold();
  }

  // ---------------------- CONSUMER UI ------------------------

  Widget _buildConsumerScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCP – Consumer'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _consumerTabIndex,
        children: [
          _buildConsumerCatalog(), // Catalog
          _buildConsumerCart(),    // Cart
          _buildConsumerOrders(),  // My Orders
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _consumerTabIndex,
        onTap: (index) {
          setState(() {
            _consumerTabIndex = index;
          });
          if (index == 0) {
            _loadCatalog();
          } else if (index == 2) {
            _loadConsumerOrders();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Catalog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'My Orders',
          ),
        ],
      ),
    );
  }

  /// Catalog as GRID (как категории / meals)
  Widget _buildConsumerCatalog() {
    if (_catalogLoading && _catalog.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_catalogError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load catalog:\n$_catalogError',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCatalog,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_catalog.isEmpty) {
      return const Center(
        child: Text('No products available yet.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCatalog,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // как в meals – 2 колонки
          childAspectRatio: 3 / 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _catalog.length,
        itemBuilder: (context, index) {
          final product = _catalog[index];
          final inCart = _cart[product.id] ?? 0.0;
          final priceText = _formatPrice(product);
          final subtitleText = _formatProductSubtitle(product);

          return _ProductGridCard(
            product: product,
            priceText: priceText,
            subtitleText: subtitleText,
            inCart: inCart,
            onAdd: product.price == null ? null : () => _addToCart(product),
          );
        },
      ),
    );
  }

  Widget _buildConsumerCart() {
    if (_cart.isEmpty) {
      return const Center(
        child: Text('Your cart is empty.'),
      );
    }

    final entries = _cart.entries.toList();
    double total = 0;

    final rows = <Widget>[];

    for (final entry in entries) {
      final product = _findProduct(entry.key);
      if (product == null) continue;

      final qty = entry.value;
      final price = product.price ?? 0;
      final lineTotal = price * qty;
      total += lineTotal;

      rows.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(product.name),
            subtitle: Text(
              '${qty.toStringAsFixed(0)} × ${price.toStringAsFixed(2)} ₸',
            ),
            trailing: SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => _decreaseCart(product),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(qty.toStringAsFixed(0)),
                  IconButton(
                    onPressed: () => _addToCart(product),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      return const Center(
        child: Text('Products in cart are no longer available.'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: rows,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            boxShadow: const [
              BoxShadow(
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Total: ${total.toStringAsFixed(2)} ₸',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _placingOrder ? null : _placeOrder,
                icon: _placingOrder
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_placingOrder ? 'Placing...' : 'Place order'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsumerOrders() {
    if (_consumerOrdersLoading && _consumerOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_consumerOrdersError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load orders:\n$_consumerOrdersError',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadConsumerOrders,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_consumerOrders.isEmpty) {
      return const Center(
        child: Text('You don\'t have any orders yet.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConsumerOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _consumerOrders.length,
        itemBuilder: (context, index) {
          final order = _consumerOrders[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              title: Text('Order #${order.id} — ${order.status.toUpperCase()}'),
              subtitle: Text(
                'Supplier: ${order.supplierName}\n'
                'Total: ${order.totalAmount.toStringAsFixed(2)} ₸',
              ),
              children: order.items
                  .map(
                    (item) => ListTile(
                      title: Text(item.productName),
                      subtitle: Text(
                        '${item.quantity} ${item.unitCode} × ${item.unitPrice.toStringAsFixed(2)} ₸',
                      ),
                      trailing: Text(
                        '${item.lineTotal.toStringAsFixed(2)} ₸',
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  // ---------------------- SUPPLIER UI ------------------------

  Widget _buildSupplierScaffold() {
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

// ============================================================
//                 КАРТОЧКА ТОВАРА В КАТАЛОГЕ
//                 (стиль как meal_item / category_grid_item)
// ============================================================

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final String priceText;
  final String subtitleText;
  final double inCart;
  final VoidCallback? onAdd;

  const _ProductGridCard({
    required this.product,
    required this.priceText,
    required this.subtitleText,
    required this.inCart,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onAdd,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.85),
              theme.colorScheme.primary.withOpacity(0.65),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              offset: Offset(0, 2),
              color: Colors.black26,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верх: название товара
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              // Цена
              Text(
                priceText,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.yellow.shade200,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // Остаток + доставка
              Text(
                subtitleText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              // Низ: кнопка + "In cart"
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    onPressed: onAdd,
                    child: const Text('Add'),
                  ),
                  const Spacer(),
                  if (inCart > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'In cart: ${inCart.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
