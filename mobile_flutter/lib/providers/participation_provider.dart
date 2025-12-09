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
      final response = await _api.get('/participations');

      // Handle paginated response
      List<dynamic> data;
      if (response is Map && response.containsKey('data')) {
        // If response is paginated, extract the 'data' array
        data = response['data'] as List<dynamic>;
      } else if (response is List) {
        // If response is already a list, use it directly
        data = response;
      } else {
        throw Exception('Unexpected response format');
      }

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

  Future<void> adminRecordParticipation(
    String studentSchoolId, // Changed to String to match the School Assigned ID
    int eventId, {
    String? studentName,
  }) async {
    try {
      debugPrint(
        'Sending Scan -> Student School ID: $studentSchoolId, Event ID: $eventId',
      );

      final body = {
        'student_id':
            studentSchoolId, // Sends the School ID string (e.g., "2023-005")
        'event_id': eventId,
      };

      // 1. Send the primary scan request
      final response = await _api.post('/participations/scan', body);
      debugPrint('Scan API response: $response');

      // 2. Handle Auto-Timeout logic
      // If backend says "already_in", automatically trigger the check-out endpoint
      if (response is Map &&
          (response['status'] == 'already_in' ||
              response['message'] == 'Student already checked in')) {
        debugPrint('Student already in. Attempting to record check-out...');

        final outResponse = await _api.post('/participations/out', body);
        debugPrint('Timeout API response: $outResponse');
      }

      // 3. Sync with Server
      // Immediately fetch the fresh list so the UI updates with the real database state
      await fetchParticipations();
    } catch (e) {
      debugPrint("Admin Record Participation Error: $e");
      // Rethrow the error so the Scanner Screen knows to show the Red SnackBar
      rethrow;
    }
  }

  List<Participation> getParticipationsForEvent(int eventId) {
    return _participations.where((p) => p.eventId == eventId).toList();
  }
}
