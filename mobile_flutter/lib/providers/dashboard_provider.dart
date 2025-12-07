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
  int? _currentUserId;

  int get eventsCount => _eventsCount;
  int get participationsCount => _participationsCount;
  int get scansCount => _scansCount;
  List<Event> get recentEvents => _recentEvents;
  Map<int, int> get eventParticipations => _eventParticipations;
  bool get isLoading => _isLoading;

  void setCurrentUserId(int? userId) {
    _currentUserId = userId;
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> eventsData = await _api.get('/events');
      List<Event> events = eventsData
          .map((json) => Event.fromJson(json))
          .toList();

      // Filter events by creator if not admin
      if (_currentUserId != null) {
        events = events
            .where((event) => event.creatorId == _currentUserId)
            .toList();
      }

      _eventsCount = events.length;
      // Sort events by timeStart ascending and take the first 3 upcoming events
      events.sort((a, b) => a.timeStart.compareTo(b.timeStart));
      _recentEvents = events
          .where((event) => event.timeStart.isAfter(DateTime.now()))
          .take(3)
          .toList();

      final List<dynamic> partData = await _api.get('/participation');
      // Filter participations by events created by current user
      if (_currentUserId != null) {
        final eventIds = events.map((e) => e.id).toSet();
        final filteredParts = partData
            .where((p) => eventIds.contains(p['event_id']))
            .toList();
        _participationsCount = filteredParts.length;
        _scansCount = filteredParts.length;
        // Count participations per event
        _eventParticipations = {};
        for (var part in filteredParts) {
          final eventId = part['event_id'] as int;
          _eventParticipations[eventId] =
              (_eventParticipations[eventId] ?? 0) + 1;
        }
      } else {
        _participationsCount = partData.length;
        _scansCount = partData.length;
        // Count participations per event
        _eventParticipations = {};
        for (var part in partData) {
          final eventId = part['event_id'] as int;
          _eventParticipations[eventId] =
              (_eventParticipations[eventId] ?? 0) + 1;
        }
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      _eventsCount = 0;
      _participationsCount = 0;
      _recentEvents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStats() => loadDashboardData();
}
