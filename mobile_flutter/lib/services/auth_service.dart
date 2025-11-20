import 'dart:convert';
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

        // Return the full response data (token + user)
        return {
          'token': data["access_token"],
          'user': data.containsKey("user") ? data["user"] : null,
        };
      } else {
        print('Login failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Register method
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

      print('Register: ${response.statusCode} - ${response.body}');

      // Registration returns 201 on success
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Register failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  Future<bool> logout() async {
    try {
      final response = await _apiService.post('/logout', {});
      return response.statusCode == 200;
    } catch (e) {
      print('Logout error: $e');
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
      print('Get current user error: $e');
      return null;
    }
  }
}
