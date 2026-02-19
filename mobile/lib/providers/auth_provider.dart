import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:steermate/services/api_service.dart';
import 'package:steermate/services/storage_service.dart';
import 'package:steermate/config/api_config.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  int? _userId;
  String? _email;
  String? _errorMessage;
  
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  int? get userId => _userId;
  String? get email => _email;
  String? get errorMessage => _errorMessage;
  
  AuthProvider() {
    _loadStoredAuth();
  }
  
  Future<void> _loadStoredAuth() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return;

    // Optimistically set token so ApiService can attach it.
    _token = token;

    try {
      final profileResponse = await ApiService.getProfile();
      if (profileResponse.statusCode == 200) {
        _userId = profileResponse.data['id'];
        _email = profileResponse.data['email'];
        _isAuthenticated = true;
        await StorageService.saveUserData(_userId!, _email!);
      } else {
        await StorageService.clearAll();
        _token = null;
        _isAuthenticated = false;
      }
    } catch (_) {
      // If offline, keep previous cached user fields but require token presence.
      _userId = StorageService.getUserId();
      _email = StorageService.getUserEmail();
      _isAuthenticated = true;
    }

    notifyListeners();
  }
  
  Future<bool> register(String email, String password, String? name) async {
    _errorMessage = null;
    try {
      final response = await ApiService.register(email, password, name);
      if (response.statusCode == 201) {
        // Auto-login after registration
        return await login(email, password);
      }
      _errorMessage = response.data['detail'] ?? 'Registration failed';
      return false;
    } on DioException catch (e) {
      debugPrint('Registration error: $e');

      final status = e.response?.statusCode;
      final uri = e.requestOptions.uri;
      final data = e.response?.data;

      if (status != null) {
        _errorMessage =
            'Server responded with $status at $uri.\n'
            'Response: ${data ?? '(empty)'}';
      } else {
        _errorMessage =
            'Cannot reach the server (${ApiConfig.apiBaseUrl}).\n'
            'Check: backend is running, IP/port are correct, and your phone can access it.';
      }
      return false;
    }
  }
  
  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    try {
      final response = await ApiService.login(email, password);
      if (response.statusCode == 200) {
        _token = response.data['access_token'];
        _isAuthenticated = true;
        
        // Store auth data
        await StorageService.saveToken(_token!);
        
        // Get user profile to get user ID
        final profileResponse = await ApiService.getProfile();
        if (profileResponse.statusCode == 200) {
          _userId = profileResponse.data['id'];
          _email = profileResponse.data['email'];
          await StorageService.saveUserData(_userId!, _email!);
        }
        
        notifyListeners();
        return true;
      }
      _errorMessage = response.data['detail'] ?? 'Login failed';
      return false;
    } on DioException catch (e) {
      debugPrint('Login error: $e');

      final status = e.response?.statusCode;
      final uri = e.requestOptions.uri;
      final data = e.response?.data;

      if (status != null) {
        _errorMessage =
            'Server responded with $status at $uri.\n'
            'Response: ${data ?? '(empty)'}';
      } else {
        _errorMessage =
            'Cannot reach the server (${ApiConfig.apiBaseUrl}).\n'
            'Check: backend is running, IP/port are correct, and your phone/emulator can access it. '
            'For Android emulator use http://10.0.2.2:8000; for a real phone use your PC LAN IP and allow port 8000 through firewall. '
            'If you are using --dart-define, do a full restart so it takes effect.';
      }
      return false;
    }
  }
  
  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _userId = null;
    _email = null;
    _errorMessage = null;
    await StorageService.clearAll();
    notifyListeners();
  }
}
