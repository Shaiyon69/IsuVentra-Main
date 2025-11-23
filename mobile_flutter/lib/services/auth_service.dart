import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _apiService.post('/login', {
        "email": email,
        "password": password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'token': data["access_token"],
          'user': data.containsKey("user") ? data["user"] : null,
        };
      } else {
        debugPrint('Login failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      final response = await _apiService.post('/register', {
        "name": name,
        "email": email,
        "password": password,
        "password_confirmation": confirmPassword,
      });

      debugPrint('Register: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        debugPrint(
          'Register failed: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Register error: $e');
      return null;
    }
  }

  Future<bool> logout() async {
    try {
      final response = await _apiService.post('/logout', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Logout error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _apiService.get('/user');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Get current user error: $e');
      return null;
    }
  }
}
