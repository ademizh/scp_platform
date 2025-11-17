import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const _keyUserId = 'user_id';
  static const _keyRoles = 'roles';
  static const _keySupplierId = 'supplier_id';
  static const _keyConsumerId = 'consumer_id';

  Future<void> saveLogin(LoginResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, result.userId);
    await prefs.setStringList(_keyRoles, result.roles);

    
    if (result.supplierId != null) {
      await prefs.setInt(_keySupplierId, result.supplierId!);
      await prefs.remove(_keyConsumerId);
    } else if (result.consumerId != null) {
      await prefs.setInt(_keyConsumerId, result.consumerId!);
      await prefs.remove(_keySupplierId);
    } else {
      await prefs.remove(_keySupplierId);
      await prefs.remove(_keyConsumerId);
    }
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  Future<List<String>> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyRoles) ?? <String>[];
  }

  Future<int?> getSupplierId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySupplierId);
  }

  Future<int?> getConsumerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyConsumerId);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyRoles);
    await prefs.remove(_keySupplierId);
    await prefs.remove(_keyConsumerId);
  }
}
