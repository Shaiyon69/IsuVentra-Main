import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  // State
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  Map<String, dynamic>? _currentUser;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;

  // User data getters
  String get userName => _currentUser?['name'] ?? 'Guest';
  String get userEmail => _currentUser?['email'] ?? '';
  String get userStudentId => _currentUser?['student_id']?.toString() ?? '';
  String get userCourse => _currentUser?['course'] ?? '';
  String get userYearLevel => _currentUser?['year_level']?.toString() ?? '';
  String get userCampus => _currentUser?['campus'] ?? '';

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _isAuthenticated = _apiService.isAuthenticated;

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginData = await _authService.login(email, password);

      if (loginData != null) {
        _token = loginData['token'];
        _currentUser = loginData['user'];

        _apiService.setToken(_token!);

        _isAuthenticated = true;
        _errorMessage = null;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final registerData = await _authService.register(
        name,
        email,
        password,
        confirmPassword,
      );

      if (registerData != null) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();

    // Clear all state
    _apiService.clearToken();
    _token = null;
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;

    _isLoading = false;
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
      print('Error refreshing user: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
