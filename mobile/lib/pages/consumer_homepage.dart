// lib/pages/consumer_homepage.dart
import 'package:flutter/material.dart';

import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/session.dart';
import 'package:mobile/pages/login_page.dart';
import 'package:mobile/pages/supplier_directory_page.dart';
import 'package:mobile/pages/product_card.dart';

class ConsumerHomePage extends StatefulWidget {
  final int userId;

  const ConsumerHomePage({
    super.key,
    required this.userId,
  });

  @override
  State<ConsumerHomePage> createState() => _ConsumerHomePageState();
}

class _ConsumerHomePageState extends State<ConsumerHomePage> {
  bool _initialLoading = true;

  // links
  int _userId = 0;
  List<int> _myLinkedSupplierIds = [];
  bool _linksLoading = false;
  String? _linksError;
  List<ConsumerLink> _consumerLinks = [];
  // catalog
  int _consumerTabIndex = 0;
  bool _catalogLoading = false;
  String? _catalogError;
  List<Product> _catalog = [];
  final Map<int, double> _cart = {}; // productId -> quantity

  // orders
  bool _placingOrder = false;
  bool _consumerOrdersLoading = false;
  String? _consumerOrdersError;
  List<Order> _consumerOrders = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

Future<void> _init() async {
    setState(() => _initialLoading = true); // Начинаем загрузку

    try {
      final uid = await SessionService.instance.getUserId();

      if (uid != null) {
        setState(() => _userId = uid);
        print('✅ Consumer Logged in as ID: $_userId');

        // 1. Загружаем список друзей
        await _loadMyApprovedLinks();

        // 2. Если друзья есть — грузим каталог
        if (_myLinkedSupplierIds.isNotEmpty) {
          await _loadCatalog();
        }
      } else {
        print('⛔ NO USER ID FOUND');
      }
    } catch (e) {
      print('Error in _init: $e');
    } finally {
      // ВАЖНО: В любом случае (даже если ошибка) убираем загрузку
      if (mounted) {
        setState(() {
          _initialLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await SessionService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage(onTap: () {})),
      (route) => false,
    );
  }

  Future<void> _loadMyApprovedLinks() async {
    setState(() {
      _linksLoading = true;
      _linksError = null;
    });

    try {
      final consumerId = await SessionService.instance.getConsumerId();
      if (consumerId == null) return;

      final links =
          await ApiClient.instance.getConsumerLinks(consumerId: consumerId);

      setState(() {
        _consumerLinks = links;
        _myLinkedSupplierIds = links
            .where((l) => l.status == 'accepted')
            .map((l) => l.supplierId)
            .toList();
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

    Future<void> _loadCatalog() async {
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });

    try {
      final products =
          await ApiClient.instance.getCatalog(userId: widget.userId); // ← назад к userId
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
      // Если в корзине уже есть товар, проверяем, что он от того же поставщика
      if (_cart.isNotEmpty) {
        final existingProductId = _cart.keys.first;
        final existingProduct = _findProduct(existingProductId);

        if (existingProduct != null &&
            existingProduct.supplierId != product.supplierId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You can place an order with one supplier at a time. Clear the cart or finish this order first.',
              ),
            ),
          );
          return;
        }
      }

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

  Future<void> _requestLinkForSupplier(int supplierId) async {
    try {
      final consumerId = await SessionService.instance.getConsumerId();
      if (consumerId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      await ApiClient.instance.sendLinkRequest(
        consumerId: consumerId,
        supplierId: supplierId,
      );
      await _loadMyApprovedLinks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link request sent to supplier'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send link request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadConsumerOrders() async {
    setState(() {
      _consumerOrdersLoading = true;
      _consumerOrdersError = null;
    });

    try {
      final orders =
          await ApiClient.instance.getConsumerOrders(userId: widget.userId);
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
    // 1) Получаем consumerId из сессии
    final consumerId = await SessionService.instance.getConsumerId();
    if (consumerId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consumer not found. Please log in again.'),
        ),
      );
      return;
    }

    // 2) Определяем supplierId по первому товару в корзине
    int? supplierId;
    for (final entry in _cart.entries) {
      final product = _findProduct(entry.key);
      if (product == null) continue;

      supplierId ??= product.supplierId;

      // Дополнительная защита: если вдруг в корзине разные suppliers
      if (product.supplierId != supplierId) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Cart must contain products from only one supplier.'),
          ),
        );
        return;
      }
    }

    if (supplierId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not determine supplier for this order.'),
        ),
      );
      return;
    }

    // 3) Проверяем, что с этим поставщиком есть accepted-link
    if (!_myLinkedSupplierIds.contains(supplierId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('You are not linked to this supplier. Request access first.'),
        ),
      );
      return;
    }

    // 4) Собираем позиции заказа
    final items = _cart.entries
        .map(
          (e) => OrderItemInput(
            productId: e.key,
            quantity: e.value,
          ),
        )
        .toList();

    // 5) Отправляем заказ на бэкенд
    final order = await ApiClient.instance.createOrder(
      userId: widget.userId,
      items: items,
    );

    if (!mounted) return;

    // 6) Чистим корзину и обновляем список заказов
    setState(() {
      _cart.clear();
    });

    await _loadConsumerOrders();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order #${order.id} created')),
    );

    // 7) Переключаемся на вкладку "My orders"
    setState(() {
      _consumerTabIndex = 2;
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

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SCP – Consumer'),
        actions: [
          IconButton(
            onPressed: () async {
              // Открываем список поставщиков
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SupplierDirectoryPage(),
                ),
              );
              // После возврата обновляем линки
              await _loadMyApprovedLinks();
              // Если появились accepted-линки — грузим каталог
              if (_myLinkedSupplierIds.isNotEmpty) {
                await _loadCatalog();
              }
            },
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Find suppliers',
          ),
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
          _buildConsumerCart(), // Cart
          _buildConsumerOrders(), // My orders
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _consumerTabIndex,
        onTap: (index) async {
          setState(() {
            _consumerTabIndex = index;
          });

          if (index == 0) {
            await _loadMyApprovedLinks();
            if (_myLinkedSupplierIds.isNotEmpty) {
              await _loadCatalog();
            }
          } else if (index == 2) {
            await _loadConsumerOrders();
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

  // --------- UI pieces ---------

  Widget _buildConsumerCatalog() {
    if (_linksError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load links:\n$_linksError'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMyApprovedLinks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Есть линк-запросы, но ни одного accepted
    if (_myLinkedSupplierIds.isEmpty && _consumerLinks.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            'Your supplier link requests:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._consumerLinks.map(
            (link) => ListTile(
              title: Text(link.supplierName),
              subtitle: Text('Status: ${link.status}'),
            ),
          ),
        ],
      );
    }

    // Полностью нет линков → старый экран "Find suppliers"
    if (_myLinkedSupplierIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have no approved suppliers yet.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SupplierDirectoryPage(),
                  ),
                );
                await _loadMyApprovedLinks();
                if (_myLinkedSupplierIds.isNotEmpty) {
                  await _loadCatalog();
                }
              },
              child: const Text('Find Suppliers'),
            ),
          ],
        ),
      );
    }

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


    return RefreshIndicator(
      onRefresh: () async {
        await _loadMyApprovedLinks();
        if (_myLinkedSupplierIds.isNotEmpty) {
          await _loadCatalog();
        }
      },
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _catalog.length,
        itemBuilder: (context, index) {
          final product = _catalog[index];
          final inCart = (_cart[product.id] ?? 0).toInt();

          return ProductGridCard(
            product: product,
            inCart: inCart,
            linkedSupplierIds: _myLinkedSupplierIds,
            onAddToCart: () => _addToCart(product),
            onRemoveFromCart: () => _decreaseCart(product),
            onRequestLink: _requestLinkForSupplier,
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
}
