import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  // Keys for SharedPreferences
  static const _keyUserId = 'user_id';
  static const _keyRoles = 'roles';
  static const _keySupplierId = 'supplier_id';
  static const _keyConsumerId = 'consumer_id';
  static const _keyLoginRole = 'role';
  static const _keyIsLoggedIn = 'isLoggedIn';
  static const _keyToken = 'auth_token';


  /// Save login result after successful login
  Future<void> saveLogin(LoginResult result) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setInt(_keyUserId, result.userId);
  await prefs.setStringList(_keyRoles, result.roles);

  if (result.token != null) {
  await prefs.setString(_keyToken, result.token!);
}

  if (result.consumerId != null) {
    await prefs.setInt(_keyConsumerId, result.consumerId!);
  }

  if (result.supplierId != null) {
    await prefs.setInt(_keySupplierId, result.supplierId!);
  }

  await prefs.setString(_keyLoginRole,
      result.roles.contains('supplier') ? 'supplier' : 'consumer');

  await prefs.setBool(_keyIsLoggedIn, true);
}

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keyToken);
}


  /// Retrieve user_id from session
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  /// Retrieve user roles (consumer / supplier)
  Future<List<String>> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyRoles) ?? <String>[];
  }

  /// Retrieve stored supplier_id (if logged as supplier)
  Future<int?> getSupplierId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySupplierId);
  }

  /// Retrieve stored consumer_id (if logged as consumer)
  Future<int?> getConsumerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyConsumerId);
  }

  /// Retrieve login UI mode (consumer / supplier)
  Future<String?> getLoginRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLoginRole);
  }

  /// Check if user has active session
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Full logout — clears all fields
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyUserId);
    await prefs.remove(_keyRoles);
    await prefs.remove(_keySupplierId);
    await prefs.remove(_keyConsumerId);
    await prefs.remove(_keyLoginRole);
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyToken);

  }
}
