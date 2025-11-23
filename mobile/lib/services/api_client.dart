import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:mobile/services/session.dart';



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
  final String? token; 


  LoginResult({
    required this.userId,
    required this.roles,
    this.supplierId,
    this.consumerId,
    required this.token,

  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      userId: json['user_id'] as int,
      roles: (json['roles'] as List<dynamic>).map((e) => e.toString()).toList(),
      supplierId: json['supplier_id'] as int?,
      consumerId: json['consumer_id'] as int?,
      token: json['token'],
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

class SupplierInfo {
  final int id;
  final String name;

  SupplierInfo({
    required this.id,
    required this.name,
  });

  factory SupplierInfo.fromJson(Map<String, dynamic> json) {
    return SupplierInfo(
      id: json['id'] as int,
      // Если в Django поле называется иначе (например, 'supplier_name'),
      // поменяй строку ниже.
      name: json['name'] as String,
    );
  }
}
/// ---------- Products & Orders models ----------

class Product {
  final int id;
  final String sku;
  final String name;
  final int supplierId;   
  final String? supplierName;
  final String unitCode; // kg / liter / pack
  final double? price;
  final double stock;
  final double discount; // percent
  final int? deliveryTime; // minutes
  final String? imageUrl; 

  Product({
    required this.id,
    required this.sku,
    required this.supplierId,
    this.supplierName,
    required this.name,
    required this.unitCode,
    required this.price,
    required this.stock,
    required this.discount,
    required this.deliveryTime,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      supplierId: json['supplier_id'] ?? 0, 
      supplierName: json['supplier_name'],
      sku: json['sku'] as String,
      name: json['name'] as String,
      unitCode: json['unit_code'] as String,
      price: _asDouble(json['price'] as num?),
      stock: _asDouble(json['stock'] as num),
      discount: _asDouble(json['discount'] as num?),
      deliveryTime: json['delivery_time'] as int?,
      imageUrl: json['image_url'], 
    );
  }
}
double _asDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
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
    final qty = _asDouble(json['quantity']);
    final unitPrice = _asDouble(json['unit_price']);
    final lineTotal = _asDouble(json['line_total']);
    return OrderItem(
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      unitCode: json['unit_code'] as String,
      quantity: qty,
      unitPrice: unitPrice,
      lineTotal: lineTotal,
    );
  }
}
class Incident {
  final int id;
  final int orderId;
  final int consumerId;
  final int supplierId;
  final String message;
  final String status;
  final DateTime createdAt;
  final int createdBy;
  final int? assignedTo;
  Incident({
    required this.id,
    required this.orderId,
    required this.consumerId,
    required this.supplierId,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.assignedTo,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as int,
      
  
      orderId: json['order_id'] as int, 
      
      consumerId: json['consumer_id'] as int, 
      
      supplierId: json['supplier_id'] as int, 
      
      message: json['message'] ?? "",
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at']),
      createdBy: json['created_by'] as int, 
      
      assignedTo: json['assigned_to'],
    );
  }
}

class Supplier {
  final int id;
  final String name;

  Supplier({required this.id, required this.name});

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'],
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
  final bool hasIncident;
  final String? incidentStatus; // "open", "in_progress", "resolved", "escalated"
  final int? incidentId;

  Order({
  required this.id,
  required this.status,
  required this.totalAmount,
  this.supplierName,
  this.consumerName,
  required this.createdAt,
  required this.items,
  this.hasIncident = false,
  this.incidentStatus,
  this.incidentId,


  });

factory Order.fromJson(Map<String, dynamic> json) {
  return Order(
    id: json['id'],
    status: json['status'],
    totalAmount: _asDouble(json['total_amount']),
    supplierName: json['supplier_name'],
    consumerName: json['consumer_name'],
    createdAt: DateTime.parse(json['created_at']),
    items: (json['items'] as List<dynamic>).map((e) => OrderItem.fromJson(e)).toList(),
    hasIncident: json['has_incident'] ?? false,
    incidentStatus: json['incident_status'],
    incidentId: json['incident_id'],
  );
}


}

/// ---------- ApiClient ----------

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  

  /// Helper to generate authenticated headers
  Future<Map<String, String>> _getAuthHeaders({String contentType = 'application/json'}) async {
    final token = await SessionService.instance.getToken();
    final headers = <String, String>{};
    if (contentType.isNotEmpty) {
      headers['Content-Type'] = contentType;
    }
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    } else {
      debugPrint("Warning: Authentication token is missing.");
    }
    return headers;
  }

  // CREATE complaint (consumer)
  Future<bool> createIncident({
    required int userId,
    required int orderId,
    required String message,
  }) async {
    // headers: X-User-Id is what Django uses
    final headers = await _getAuthHeaders();
    headers['X-User-Id'] = '$userId';

    final response = await http.post(
      Uri.parse('$_baseUrl/api/incidents/'),
      headers: headers,
      body: jsonEncode({
        'order_id': orderId,  // snake_case matches ComplaintCreateSerializer
        'message': message,
      }),
    );

    // for debug
    debugPrint('📨 createIncident -> ${response.statusCode} ${response.body}');

    if (response.statusCode != 201) {
      debugPrint('Failed to submit incident: ${response.body}');
    }
    return response.statusCode == 201;
  }


  // GET supplier incidents
  Future<List<Incident>> getSupplierIncidents(int userId, int supplierId) async {
    // 🟢 FIX 1: Add authentication token to headers
    final headers = await _getAuthHeaders(); 
    headers['X-User-Id'] = userId.toString();
    final response = await http.get(
      // 🟢 FIX 2: Corrected URL to include '/api/' prefix
      Uri.parse('$_baseUrl/api/supplier/$supplierId/incidents/'), 
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Incident.fromJson(json)).toList();
    } else {
      // Optional: Print error to see why it fails next time
      print("Request failed: ${response.body}");
      return [];
    }
  }

  // UPDATE status
Future<bool> updateIncidentStatus(int userId, int incidentId, String newStatus) async {
    final headers = await _getAuthHeaders();
    headers['X-User-Id'] = userId.toString();
    final response = await http.patch( // <--- Must be PATCH
      Uri.parse('$_baseUrl/api/incidents/$incidentId/'),
      headers: headers,
      body: jsonEncode({'status': newStatus}),
    );
    if (response.statusCode != 200) {
      print("Failed to update: ${response.body}");
    }
    return response.statusCode == 200;
  }

  // ESCALATE
// ESCALATE (Updated)
  Future<bool> escalateIncident(int userId, int id) async {
    final headers = await _getAuthHeaders();
    
    // 🟢 FIX: Add User ID Header
    headers['X-User-Id'] = userId.toString();

    final response = await http.post(
      Uri.parse('$_baseUrl/api/incidents/$id/escalate/'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
        print("Escalation failed: ${response.body}");
    }
    
    return response.statusCode == 200;
  }

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
        'consumer_name': fullName,
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
    required int consumerId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/links/consumer/$consumerId/');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load consumer links: ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return data.map((e) => ConsumerLink.fromJson(e)).toList();
}

  Future<void> sendLinkRequest({
    required int consumerId,
    required int supplierId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/links/request/');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',

      },
      body: jsonEncode({
        'consumer_id': consumerId,
        'supplier_id': supplierId,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
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

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return data.map((e) => SupplierLinkRequest.fromJson(e)).toList();
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
  final bodyMap = {
      'items': items.map((e) => e.toJson()).toList(),
    };
  final bodyString = jsonEncode(bodyMap);

  print('🚀 FINAL BODY: $bodyString');
  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'X-User-Id': '$userId', // 👈 ОБЯЗАТЕЛЬНО
    },
    body: bodyString, 
  );
// 2. СМОТРИМ В КОНСОЛЬ (внизу экрана)
    print('----------------------------------------');
    print('🚀 ОТПРАВЛЯЮ ЗАКАЗ:');
    print(bodyString); 
    print('----------------------------------------');
    print('📥 ОТВЕТ СЕРВЕРА (${response.statusCode}):');
    print(response.body);
  
  if (response.statusCode != 201) {
    print('❌ SERVER ERROR: ${response.body}');
      // Выводим текст ошибки, чтобы видеть, что ответил сервер
      throw Exception('Failed to create order (${response.statusCode}): ${response.body}');
    }

  return Order.fromJson(jsonDecode(response.body));
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
  Future<List<SupplierInfo>> getSuppliersDirectory() async {
    // Путь подгони под свой Django (например, /api/suppliers/ или /api/suppliers/directory/)
    final uri = Uri.parse('$_baseUrl/api/suppliers/directory/');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load suppliers: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => SupplierInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  // GET consumer incidents
Future<List<Incident>> getConsumerIncidents() async {
  final headers = await _getAuthHeaders(contentType: '');
  final userId = await SessionService.instance.getUserId();
  if (userId != null) {
      headers['X-User-Id'] = userId.toString();
    }
  final response = await http.get(
    Uri.parse('$_baseUrl/api/my-incidents/'),
    headers: headers,
  );

  if (response.statusCode == 200) {
      // Decode UTF8 to handle special characters correctly
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return data.map((e) => Incident.fromJson(e)).toList();
    } else {
      print("Failed to load consumer incidents: ${response.body}");
      return [];
    }
}

  
}