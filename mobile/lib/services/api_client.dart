import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';


const String _webBaseUrl = 'http://127.0.0.1:8000';
const String _androidEmuBaseUrl = 'http://10.0.2.2:8000';

final String _baseUrl = kIsWeb ? _webBaseUrl : _androidEmuBaseUrl;

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
  final String status; // pending / accepted / rejected / blocked

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

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // ---------- AUTH ----------

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

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResult.fromJson(json);
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
      throw Exception('Register failed: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResult(
      userId: json['user_id'] as int,
      roles: const ['owner'],
      supplierId: json['supplier_id'] as int?,
      consumerId: null,
    );
  }

  Future<LoginResult> registerConsumer({
    required String email,
    required String password,
    required String fullName,
    required String consumerName,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/register-consumer/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'consumer_name': consumerName,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Register failed: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResult(
      userId: json['user_id'] as int,
      roles: const ['consumer'],
      supplierId: null,
      consumerId: json['consumer_id'] as int?,
    );
  }

  // ---------- LINK REQUESTS (Consumer side) ----------
  Future<List<ConsumerLink>> getConsumerLinks(int consumerId) async {
    final uri = Uri.parse('$_baseUrl/api/links/consumer/$consumerId/');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load consumer links: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((e) => ConsumerLink.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Send a link request from a consumer to a supplier.
  
  Future<ConsumerLink> sendLinkRequest({
    required int consumerId,
    required int supplierId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/links/request/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'consumer_id': consumerId,
        'supplier_id': supplierId,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to send link request: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ConsumerLink.fromJson(json);
  }

  // ---------- LINK REQUESTS (Supplier side) ----------

  Future<List<SupplierLinkRequest>> getSupplierIncomingLinkRequests(
      int supplierId) async {
    final uri = Uri.parse('$_baseUrl/api/links/supplier/$supplierId/');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load link requests: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((e) => SupplierLinkRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveLinkRequest(int requestId) async {
    final uri = Uri.parse('$_baseUrl/api/links/$requestId/approve/');
    final response = await http.post(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to approve link request: ${response.body}');
    }
  }

  Future<void> rejectLinkRequest(int requestId) async {
    final uri = Uri.parse('$_baseUrl/api/links/$requestId/reject/');
    final response = await http.post(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to reject link request: ${response.body}');
    }
  }
}
