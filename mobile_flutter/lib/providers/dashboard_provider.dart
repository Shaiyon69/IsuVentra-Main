import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  int _eventsCount = 0;
  int _participationsCount = 0;
  int _scansCount = 0;
  List<Event> _recentEvents = [];
  Map<int, int> _eventParticipations = {};
  bool _isLoading = false;
  int _userAdminLevel = 0; // 0: user, 1: super admin, 2: admin

  int get eventsCount => _eventsCount;
  int get participationsCount => _participationsCount;
  int get scansCount => _scansCount;
  List<Event> get recentEvents => _recentEvents;
  Map<int, int> get eventParticipations => _eventParticipations;
  bool get isLoading => _isLoading;

  void setUserAdminLevel(int adminLevel) {
    _userAdminLevel = adminLevel;
    notifyListeners();
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final eventsResponse = await _api.get('/events');

      // Parse events (handle paginated and non-paginated formats)
      List<dynamic> eventsData = [];
      int eventsTotal = 0;
      if (eventsResponse is Map && eventsResponse.containsKey('data')) {
        eventsData = eventsResponse['data'] as List<dynamic>;
        eventsTotal = eventsResponse['total'] ?? eventsData.length;
      } else if (eventsResponse is List) {
        eventsData = eventsResponse;
        eventsTotal = eventsData.length;
      } else {
        throw Exception('Unexpected events response format');
      }

      List<Event> events = eventsData
          .map((json) => Event.fromJson(json))
          .toList();

      final now = DateTime.now();
      List<Event> filteredEvents;

      if (_userAdminLevel == 0) {
        // Regular users: only upcoming events
        filteredEvents = events.where((e) => e.timeStart.isAfter(now)).toList();
      } else {
        // Admins and super-admins: show all events returned by backend
        filteredEvents = events;
      }

      filteredEvents.sort((a, b) => a.timeStart.compareTo(b.timeStart));

      // Use paginated total when available for overall count, otherwise use filtered length
      _eventsCount = eventsTotal > 0 ? eventsTotal : filteredEvents.length;

      // Recent events: upcoming ones limited to 3
      _recentEvents = filteredEvents
          .where((e) => e.timeStart.isAfter(now))
          .take(3)
          .toList();

      // Fetch participations (may fail for non-admins) and compute counts per visible events
      try {
        final partResponse = await _api.get('/participations');

        List<dynamic> partData = [];
        if (partResponse is Map && partResponse.containsKey('data')) {
          partData = partResponse['data'] as List<dynamic>;
        } else if (partResponse is List) {
          partData = partResponse;
        } else {
          throw Exception('Unexpected participation response format');
        }

        final eventIds = filteredEvents.map((e) => e.id).toSet();
        final filteredParts = partData.where((p) {
          try {
            return eventIds.contains(p['event_id'] as int);
          } catch (_) {
            return false;
          }
        }).toList();

        _participationsCount = filteredParts.length;
        _scansCount = filteredParts.length;
        _eventParticipations = {};
        for (var part in filteredParts) {
          final eventId = part['event_id'] as int;
          _eventParticipations[eventId] =
              (_eventParticipations[eventId] ?? 0) + 1;
        }
      } catch (e) {
        // Participations endpoint might be restricted; fall back to zeroed counts
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
      _eventParticipations = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStats() => loadDashboardData();
}
