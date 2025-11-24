import 'dart:convert';
import 'package:http/http.dart' as http;
import '../variables.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  String? getToken() {
    return _token;
  }

  void clearToken() {
    _token = null;
  }

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<http.Response> get(String endpoint) async {
    return await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(),
    );
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(),
      body: jsonEncode(data),
    );
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(),
      body: jsonEncode(data),
    );
  }

  Future<http.Response> delete(String endpoint) async {
    return await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(),
    );
  }

  Map<String, String> _buildHeaders() {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  static Future<http.Response> staticGet(String endpoint) async {
    return _instance.get(endpoint);
  }

  static Future<http.Response> staticPost(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return _instance.post(endpoint, data);
  }

  static Future<http.Response> staticPut(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return _instance.put(endpoint, data);
  }

  static Future<http.Response> staticDelete(String endpoint) async {
    return _instance.delete(endpoint);
  }
}
