import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secure = FlutterSecureStorage();
  
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyEmail = 'user_email';
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Token management
  static Future<void> saveToken(String token) async {
    await _secure.write(key: _keyToken, value: token);
  }
  
  static Future<String?> getToken() async {
    return _secure.read(key: _keyToken);
  }
  
  static Future<void> clearToken() async {
    await _secure.delete(key: _keyToken);
  }
  
  // User data
  static Future<void> saveUserData(int userId, String email) async {
    await _prefs?.setInt(_keyUserId, userId);
    await _prefs?.setString(_keyEmail, email);
  }
  
  static int? getUserId() {
    return _prefs?.getInt(_keyUserId);
  }
  
  static String? getUserEmail() {
    return _prefs?.getString(_keyEmail);
  }
  
  static Future<void> clearUserData() async {
    await _prefs?.remove(_keyUserId);
    await _prefs?.remove(_keyEmail);
  }
  
  // Clear all
  static Future<void> clearAll() async {
    await clearToken();
    await clearUserData();
  }
}
