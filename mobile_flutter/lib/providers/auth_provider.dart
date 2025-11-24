import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

/// Consolidated AuthProvider that handles login/logout, token management,
/// and optional "remember me" persistence.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _token;
  Map<String, dynamic>? _currentUser;
  String? savedEmail;
  bool rememberMe = false;

  bool get isLoading => _isLoading;
  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;

  AuthProvider() {
    loadFromStorage();
  }

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    savedEmail = prefs.getString('savedEmail');
    _token = prefs.getString('savedToken');
    rememberMe = prefs.getBool('rememberMe') ?? false;

    if (_token != null && _token!.isNotEmpty) {
      _apiService.setToken(_token!);
    }

    notifyListeners();
  }

  Future<bool> login(
    String email,
    String password, {
    required bool remember,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final loginData = await _authService.login(email, password);
      _isLoading = false;

      if (loginData != null && loginData['token'] != null) {
        _token = loginData['token'];
        _currentUser = loginData['user'];
        savedEmail = email;
        rememberMe = remember;

        _apiService.setToken(_token!);

        final prefs = await SharedPreferences.getInstance();
        if (remember) {
          await prefs.setBool('rememberMe', true);
          await prefs.setString('savedEmail', email);
          await prefs.setString('savedToken', _token!);
        } else {
          await prefs.remove('rememberMe');
          await prefs.remove('savedEmail');
          await prefs.remove('savedToken');
        }

        notifyListeners();
        return true;
      }

      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    rememberMe = false;
    savedEmail = null;
    _apiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberMe');
    await prefs.remove('savedEmail');
    await prefs.remove('savedToken');
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      final userData = await _authService.getCurrentUser();
      if (userData != null) {
        _currentUser = userData;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }
}
