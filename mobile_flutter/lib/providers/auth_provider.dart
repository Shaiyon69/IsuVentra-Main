import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _user;
  bool _isLoading = false;
  String? _savedEmail;
  bool _rememberMe = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  String? get savedEmail => _savedEmail;
  bool get rememberMe => _rememberMe;

  AuthProvider() {
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    _savedEmail = await _storage.read(key: 'saved_email');
    if (_savedEmail != null) _rememberMe = true;
    notifyListeners();
  }

  Future<bool> login(
    String identifier,
    String password, {
    bool remember = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.post('/login', {
        'email': identifier,
        'password': password,
      });

      await _storage.write(key: 'token', value: response['access_token']);

      if (remember) {
        await _storage.write(key: 'saved_email', value: identifier);
        _savedEmail = identifier;
        _rememberMe = true;
      } else {
        await _storage.delete(key: 'saved_email');
        _savedEmail = null;
        _rememberMe = false;
      }

      await fetchUserProfile();
      return true;
    } catch (e) {
      debugPrint("Login Error: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final data = await _api.get('/user');
      _user = User.fromJson(data);
      notifyListeners();
    } catch (e) {
      debugPrint("Profile Error: $e");
    }
  }

  Future<bool> tryAutoLogin() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return false;

    try {
      await fetchUserProfile();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout', {});
    } catch (_) {}
    await _storage.delete(key: 'token');
    _user = null;
    notifyListeners();
  }
}
