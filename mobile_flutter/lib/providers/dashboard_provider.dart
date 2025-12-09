import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  int _eventsCount = 0;
  int _participationsCount = 0;
  int _scansCount = 0;
  List<Event> _recentEvents = [];
  Map<int, int> _eventParticipations = {};
  bool _isLoading = false;

  int get eventsCount => _eventsCount;
  int get participationsCount => _participationsCount;
  int get scansCount => _scansCount;
  List<Event> get recentEvents => _recentEvents;
  Map<int, int> get eventParticipations => _eventParticipations;
  bool get isLoading => _isLoading;

  Future<void> loadDashboardData({int? userId, UserRole? role}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Events
      final eventsResponse = await _api.get('/events');
      List<dynamic> eventsData = [];
      if (eventsResponse is Map && eventsResponse.containsKey('data')) {
        eventsData = eventsResponse['data'] as List<dynamic>;
      } else if (eventsResponse is List) {
        eventsData = eventsResponse;
      }

      List<Event> allEvents = eventsData
          .map((json) => Event.fromJson(json))
          .toList();

      List<Event> filteredEvents = [];
      final now = DateTime.now();

      // --- RBAC Filtering for Dashboard ---
      if (role == UserRole.student) {
        filteredEvents = allEvents
            .where((e) => e.timeEnd.isAfter(now))
            .toList();
      } else if (role == UserRole.admin) {
        if (userId != null) {
          filteredEvents = allEvents
              .where((e) => e.organizerId == userId)
              .toList();
        }
      } else {
        // Super Admin sees all
        filteredEvents = allEvents;
      }

      // 2. Sort & Count
      if (role == UserRole.student) {
        filteredEvents.sort((a, b) => a.timeStart.compareTo(b.timeStart));
      } else {
        filteredEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      _eventsCount = filteredEvents.length;
      _recentEvents = filteredEvents.take(5).toList();

      // 3. Fetch Participations & Filter
      try {
        final partResponse = await _api.get('/participations');
        List<dynamic> partData = [];
        if (partResponse is Map && partResponse.containsKey('data')) {
          partData = partResponse['data'] as List<dynamic>;
        } else if (partResponse is List) {
          partData = partResponse;
        }

        // Only count participations for events visible to this user
        final visibleEventIds = filteredEvents.map((e) => e.id).toSet();

        final filteredParts = partData.where((p) {
          try {
            return visibleEventIds.contains(p['event_id'] as int);
          } catch (_) {
            return false;
          }
        }).toList();

        _participationsCount = filteredParts.length;
        _scansCount =
            filteredParts.length; // Assuming scan = participation entry

        _eventParticipations = {};
        for (var part in filteredParts) {
          final eventId = part['event_id'] as int;
          _eventParticipations[eventId] =
              (_eventParticipations[eventId] ?? 0) + 1;
        }
      } catch (e) {
        _participationsCount = 0;
        _scansCount = 0;
        _eventParticipations = {};
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      _eventsCount = 0;
      _participationsCount = 0;
      _scansCount = 0;
      _recentEvents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
