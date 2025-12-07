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
    int studentId,
    int eventId, {
    String? studentName,
  }) async {
    try {
      final response = await _api.post('/participations/scan', {
        'student_id': studentId,
        'event_id': eventId,
      });

      debugPrint('Scan API response: $response');

      // If the API returned the updated/created participation, update local list
      if (response is Map) {
        Map<String, dynamic> partJson = {};

        if (response.containsKey('participation')) {
          partJson = Map<String, dynamic>.from(response['participation']);
        } else if (response.containsKey('data')) {
          // some APIs return { data: { ... } }
          final d = response['data'];
          if (d is Map) partJson = Map<String, dynamic>.from(d);
        } else if (response.containsKey('id')) {
          partJson = Map<String, dynamic>.from(response);
        }

        if (partJson.isNotEmpty && partJson.containsKey('id')) {
          final newPart = Participation.fromJson(partJson);

          // replace existing participation if present, otherwise add
          final idx = _participations.indexWhere((p) => p.id == newPart.id);
          if (idx >= 0) {
            _participations[idx] = newPart;
          } else {
            // If we don't have it, add to the list
            _participations.add(newPart);
          }
          notifyListeners();
        } else {
          // If API didn't return participation JSON, apply optimistic update
          final matchIdx = _participations.indexWhere(
            (p) => p.studentId == studentId && p.eventId == eventId,
          );
          final now = DateTime.now();
          if (matchIdx >= 0) {
            final existing = _participations[matchIdx];
            final updated = Participation(
              id: existing.id,
              studentId: existing.studentId,
              eventId: existing.eventId,
              studentName: existing.studentName,
              eventName: existing.eventName,
              timeIn: existing.timeIn ?? now,
              timeOut: existing.timeIn != null && existing.timeOut == null
                  ? now
                  : existing.timeOut,
            );
            _participations[matchIdx] = updated;
            notifyListeners();
          } else {
            // No existing participation — create optimistic record.
            final tempId = -DateTime.now().millisecondsSinceEpoch;
            final newPart = Participation(
              id: tempId,
              studentId: studentId,
              eventId: eventId,
              studentName: studentName ?? 'Unknown',
              eventName: 'Unknown',
              timeIn: now,
              timeOut: null,
            );
            _participations.add(newPart);
            notifyListeners();
          }
        }
        // If API returned a status telling us the student is already in, perform timeout
        if (response.containsKey('status') &&
            response['status'] == 'already_in') {
          try {
            final outResp = await _api.post('/participations/out', {
              'student_id': studentId,
              'event_id': eventId,
            });
            debugPrint('Timeout API response: $outResp');

            // Apply timeOut locally based on server success
            final outNow = DateTime.now();
            final idx2 = _participations.indexWhere(
              (p) => p.studentId == studentId && p.eventId == eventId,
            );
            if (idx2 >= 0) {
              final existing = _participations[idx2];
              final updated = Participation(
                id: existing.id,
                studentId: existing.studentId,
                eventId: existing.eventId,
                studentName: existing.studentName,
                eventName: existing.eventName,
                timeIn: existing.timeIn ?? outNow,
                timeOut: outNow,
              );
              _participations[idx2] = updated;
              notifyListeners();
            } else {
              final tempId = -DateTime.now().millisecondsSinceEpoch;
              final newPart2 = Participation(
                id: tempId,
                studentId: studentId,
                eventId: eventId,
                studentName: studentName ?? 'Unknown',
                eventName: 'Unknown',
                timeIn: outNow,
                timeOut: outNow,
              );
              _participations.add(newPart2);
              notifyListeners();
            }
          } catch (e) {
            debugPrint('Timeout request failed: $e');
          }
        }
      }
      // If response was a list, null, or other, apply optimistic update so UI reflects scan immediately.
      if (response is! Map) {
        final matchIdx = _participations.indexWhere(
          (p) => p.studentId == studentId && p.eventId == eventId,
        );
        final now = DateTime.now();
        if (matchIdx >= 0) {
          final existing = _participations[matchIdx];
          final updated = Participation(
            id: existing.id,
            studentId: existing.studentId,
            eventId: existing.eventId,
            studentName: existing.studentName,
            eventName: existing.eventName,
            timeIn: existing.timeIn ?? now,
            timeOut: existing.timeIn != null && existing.timeOut == null
                ? now
                : existing.timeOut,
          );
          _participations[matchIdx] = updated;
          notifyListeners();
          // If we just set a timeOut locally, notify server via timeout endpoint
          if (existing.timeIn != null && existing.timeOut == null) {
            try {
              await _api.post('/participations/out', {
                'student_id': studentId,
                'event_id': eventId,
              });
            } catch (e) {
              debugPrint('Timeout request failed during optimistic update: $e');
            }
          }
        } else {
          final tempId = -DateTime.now().millisecondsSinceEpoch;
          final newPart = Participation(
            id: tempId,
            studentId: studentId,
            eventId: eventId,
            studentName: 'Unknown',
            eventName: 'Unknown',
            timeIn: now,
            timeOut: null,
          );
          _participations.add(newPart);
          notifyListeners();
        }
        // Try to reconcile with server state shortly after optimistic update
        Future.delayed(const Duration(seconds: 1), () async {
          try {
            await fetchParticipations();
          } catch (_) {
            // ignore failures here; we only attempt to reconcile
          }
        });
      }
    } catch (e) {
      debugPrint("Admin Record Participation Error: $e");
      throw Exception('Failed to record participation');
    }
  }

  List<Participation> getParticipationsForEvent(int eventId) {
    return _participations.where((p) => p.eventId == eventId).toList();
  }
}
