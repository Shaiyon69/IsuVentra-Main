import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  String get name => _currentUser?['name'] ?? 'Guest';
  String get email => _currentUser?['email'] ?? '';
  String get studentId => _currentUser?['student_id']?.toString() ?? '';
  String get course => _currentUser?['course'] ?? '';
  String get yearLevel => _currentUser?['year_level']?.toString() ?? '';
  String get campus => _currentUser?['campus'] ?? '';

  void setUser(Map<String, dynamic>? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _authService.getCurrentUser();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    await loadUser();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}
