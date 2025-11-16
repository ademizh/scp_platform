import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // NEW

// For now
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

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Future<LoginResult> login(String email, String password, {
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
      roles: ['owner'],
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
      roles: ['consumer'],
      supplierId: null,
      consumerId: json['consumer_id'] as int?,
    );
  }
}
