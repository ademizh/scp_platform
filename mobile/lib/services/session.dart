import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const _keyUserId = 'user_id';
  static const _keyRoles = 'roles';

  Future<void> saveLogin(LoginResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, result.userId);
    await prefs.setStringList(_keyRoles, result.roles);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  Future<List<String>> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyRoles) ?? [];
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyRoles);
  }
}
