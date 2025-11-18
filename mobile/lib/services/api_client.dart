import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Base URLs for different platforms
const String _webBaseUrl = 'http://127.0.0.1:8000';
const String _androidEmuBaseUrl = 'http://10.0.2.2:8000';

final String _baseUrl = kIsWeb ? _webBaseUrl : _androidEmuBaseUrl;

/// ---------- Auth / Session models ----------

class LoginResult {
  final int userId;
  final List<String> roles;
  final int? supplierId;
  final int? consumerId;

  LoginResult({
    required this.userId,
    required this.roles,
    this.supplierId,
    this.consumerId,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      userId: json['user_id'] as int,
      roles: (json['roles'] as List<dynamic>).map((e) => e.toString()).toList(),
      supplierId: json['supplier_id'] as int?,
      consumerId: json['consumer_id'] as int?,
    );
  }
}

/// ---------- Link requests models ----------

class ConsumerLink {
  final int id;
  final int supplierId;
  final String supplierName;
  final String status;

  ConsumerLink({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.status,
  });

  factory ConsumerLink.fromJson(Map<String, dynamic> json) {
    return ConsumerLink(
      id: json['id'] as int,
      supplierId: json['supplier_id'] as int,
      supplierName: json['supplier_name'] as String,
      status: json['status'] as String,
    );
  }
}

class SupplierLinkRequest {
  final int id;
  final int consumerId;
  final String consumerName;
  final String status;

  SupplierLinkRequest({
    required this.id,
    required this.consumerId,
    required this.consumerName,
    required this.status,
  });

  factory SupplierLinkRequest.fromJson(Map<String, dynamic> json) {
    return SupplierLinkRequest(
      id: json['id'] as int,
      consumerId: json['consumer_id'] as int,
      consumerName: json['consumer_name'] as String,
      status: json['status'] as String,
    );
  }
}

/// ---------- Products & Orders models ----------

class Product {
  final int id;
  final String sku;
  final String name;
  final String unitCode; // kg / liter / pack
  final double? price;
  final double stock;
  final double discount; // percent
  final int? deliveryTime; // minutes

  Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.unitCode,
    required this.price,
    required this.stock,
    required this.discount,
    required this.deliveryTime,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      sku: json['sku'] as String,
      name: json['name'] as String,
      unitCode: json['unit_code'] as String,
      price: (json['price'] as num?)?.toDouble(),
      stock: (json['stock'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      deliveryTime: json['delivery_time'] as int?,
    );
  }
}

class OrderItemInput {
  final int productId;
  final double quantity;

  OrderItemInput({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity': quantity,
      };
}

class OrderItem {
  final int productId;
  final String productName;
  final String unitCode;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.unitCode,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num).toDouble();
    final unitPrice = (json['unit_price'] as num).toDouble();
    return OrderItem(
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      unitCode: json['unit_code'] as String,
      quantity: qty,
      unitPrice: unitPrice,
      lineTotal: qty * unitPrice,
    );
  }
}

class Order {
  final int id;
  final String status;
  final double totalAmount;
  final String? supplierName;
  final String? consumerName;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.supplierName,
    required this.consumerName,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      status: json['status'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      supplierName: json['supplier_name'] as String?,
      consumerName: json['consumer_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// ---------- ApiClient ----------

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // -------- Auth --------

  Future<LoginResult> login(
    String email,
    String password, {
    required String loginAs,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'login_as': loginAs,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.body}');
    }

    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResult.fromJson(jsonMap);
  }

  Future<LoginResult> registerSupplier({
    required String email,
    required String password,
    required String fullName,
    required String supplierName,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/register-supplier/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'supplier_name': supplierName,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Register supplier failed: ${response.body}');
    }

    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResult.fromJson(jsonMap);
  }

  Future<LoginResult> registerConsumer({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/register-consumer/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Register consumer failed: ${response.body}');
    }

    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResult.fromJson(jsonMap);
  }

  // -------- Link requests --------

  Future<List<ConsumerLink>> getConsumerLinks({
    required int userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/links/consumer/');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': '$userId',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load consumer links: ${response.body}');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ConsumerLink.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendLinkRequest({
    required int userId,
    required int supplierId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/links/create/');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': '$userId',
      },
      body: jsonEncode({
        'supplier_id': supplierId,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create link request: ${response.body}');
    }
  }

  Future<List<SupplierLinkRequest>> getSupplierIncomingLinkRequests(
    int supplierId,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/links/supplier/$supplierId/');
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load supplier link requests: ${response.body}');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => SupplierLinkRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveLinkRequest(int linkId) async {
    final uri = Uri.parse('$_baseUrl/api/links/$linkId/approve/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to approve link request: ${response.body}');
    }
  }

  Future<void> rejectLinkRequest(int linkId) async {
    final uri = Uri.parse('$_baseUrl/api/links/$linkId/block/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reject link request: ${response.body}');
    }
  }

  // -------- Catalog / Products --------

  Future<List<Product>> getCatalog({
    required int userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/products/');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': '$userId',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load catalog: ${response.body}');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // (CRUD for products для Supplier UI можно добавить позже)

  // -------- Orders --------

  Future<Order> createOrder({
    required int userId,
    required List<OrderItemInput> items,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/orders/');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': '$userId',
      },
      body: jsonEncode({
        'items': items.map((e) => e.toJson()).toList(),
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create order: ${response.body}');
    }

    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    return Order.fromJson(jsonMap);
  }

  Future<List<Order>> getConsumerOrders({
    required int userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/orders/?role=consumer');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': '$userId',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load consumer orders: ${response.body}');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Order>> getSupplierOrders({
    required int userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/orders/?role=supplier');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': '$userId',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load supplier orders: ${response.body}');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> acceptOrder({
    required int userId,
    required int orderId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/orders/$orderId/accept/');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': '$userId',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to accept order: ${response.body}');
    }
  }

  Future<void> rejectOrder({
    required int userId,
    required int orderId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/orders/$orderId/reject/');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': '$userId',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reject order: ${response.body}');
    }
  }
}
