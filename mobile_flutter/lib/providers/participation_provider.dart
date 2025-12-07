import 'package:flutter/material.dart';
import '../models/participation_model.dart';
import '../services/api_service.dart';

class ParticipationProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Participation> _participations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Participation> get participations => _participations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchParticipations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<dynamic> data = await _api.get('/participation');
      _participations = data
          .map((json) => Participation.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Participation Error: $e");
      _errorMessage = "Failed to load participations. Please try again.";
      _participations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adminRecordParticipation(int studentId, int eventId) async {
    try {
      await _api.post('/participations', {
        'student_id': studentId,
        'event_id': eventId,
        'time_in': DateTime.now().toIso8601String(),
      });
      await fetchParticipations(); // Refresh the list
    } catch (e) {
      debugPrint("Admin Record Participation Error: $e");
      throw Exception('Failed to record participation');
    }
  }

  List<Participation> getParticipationsForEvent(int eventId) {
    return _participations.where((p) => p.eventId == eventId).toList();
  }
}
