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

  /// Fetch list of attendees
  Future<void> fetchParticipations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get('/participations');
      List<dynamic> data;

      if (response is Map && response.containsKey('data')) {
        data = response['data'] as List<dynamic>;
      } else if (response is List) {
        data = response;
      } else {
        data = [];
      }

      _participations = data
          .map((json) => Participation.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Participation Fetch Error: $e");
      _errorMessage = "Failed to load attendees.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Main Scanning Logic
  Future<String> adminRecordParticipation(
    dynamic studentId,
    int eventId, {
    String? studentName,
  }) async {
    String message = '';

    // 1. Force a silent refresh first to ensure local state is accurate
    // We don't await this if we want speed, but for accuracy we should check.
    if (_participations.isEmpty) {
      try {
        await fetchParticipations();
      } catch (_) {}
    }

    try {
      // 2. Check Local List First
      // We look for an existing record for this student + event
      final existingIndex = _participations.indexWhere(
        (p) =>
            (p.studentId.toString() == studentId.toString() ||
                p.studentId == studentId) &&
            p.eventId == eventId,
      );

      final body = {'student_id': studentId, 'event_id': eventId};

      if (existingIndex != -1) {
        final existing = _participations[existingIndex];

        // --- A. FULLY ATTENDED (Stop) ---
        if (existing.timeIn != null && existing.timeOut != null) {
          throw Exception(
            "Student has already completed this event (In & Out).",
          );
        }
        // --- B. CURRENTLY IN (Check Out) ---
        else if (existing.timeIn != null && existing.timeOut == null) {
          debugPrint('Local: Student is IN. Attempting Check-out...');
          message = await _performCheckOut(body);
        }
        // Fallback
        else {
          message = await _performCheckIn(body);
        }
      } else {
        // --- C. NEW STUDENT (Check In) ---
        debugPrint('Local: Student not found. Attempting Check-in...');
        try {
          message = await _performCheckIn(body);
        } catch (e) {
          // If API returns 422, it means our local list was stale and they ARE in DB.
          if (e.toString().contains('422') ||
              e.toString().contains('already_in')) {
            debugPrint(
              'API 422: Student actually IN. Switching to Check OUT...',
            );
            message = await _performCheckOut(body);
          } else {
            rethrow;
          }
        }
      }

      return message;
    } catch (e) {
      debugPrint("Admin Record Error: $e");
      rethrow;
    } finally {
      // 3. CRITICAL: Update the UI List immediately
      await fetchParticipations();
    }
  }

  Future<String> _performCheckIn(Map<String, dynamic> body) async {
    await _api.post('/participations/scan', body);
    return "Checked IN successfully.";
  }

  Future<String> _performCheckOut(Map<String, dynamic> body) async {
    try {
      await _api.post('/participations/out', body);
      return "Checked OUT successfully.";
    } catch (e) {
      // Catch the 404 specifically to help debug the server
      if (e.toString().contains('404')) {
        throw Exception(
          "Server Error 404: The check-out route is missing. Please clear server cache.",
        );
      }
      rethrow;
    }
  }

  /// Helper to filter list for the specific event view
  List<Participation> getParticipationsForEvent(int eventId) {
    return _participations.where((p) => p.eventId == eventId).toList();
  }
}
