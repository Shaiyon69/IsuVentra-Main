import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/student_model.dart';

class StudentProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  Future<Student?> fetchStudentByStudentId(String studentId) async {
    try {
      final data = await _api.get('/students/$studentId');
      return Student.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching student: $e');
      return null;
    }
  }
}
