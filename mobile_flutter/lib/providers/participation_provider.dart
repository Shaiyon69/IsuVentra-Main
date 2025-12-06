import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/participation_model.dart';

class ParticipationProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Participation> _history = [];
  bool _isLoading = false;

  List<Participation> get history => _history;
  bool get isLoading => _isLoading;

  // CLOCK IN
  Future<String> scanIn(int eventId) async {
    try {
      final response = await _api.post('/participations/scan', {
        'event_id': eventId,
      });
      fetchHistory();
      return response['message'];
    } catch (e) {
      rethrow;
    }
  }

  // CLOCK OUT
  Future<String> scanOut(int eventId) async {
    try {
      final response = await _api.post('/participations/out', {
        'event_id': eventId,
      });
      fetchHistory();
      return response['message'];
    } catch (e) {
      rethrow;
    }
  }

  // ADMIN RECORD PARTICIPATION
  Future<String> adminRecordParticipation(int studentId, int eventId) async {
    try {
      await _api.post('/participations', {
        'student_id': studentId,
        'event_id': eventId,
        'time_in': DateTime.now().toIso8601String(),
      });
      return 'Participation recorded successfully';
    } catch (e) {
      rethrow;
    }
  }

  // FETCH HISTORY
  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> data = await _api.get('/participation');
      _history = data.map((json) => Participation.fromJson(json)).toList();
    } catch (e) {
      debugPrint("History Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
