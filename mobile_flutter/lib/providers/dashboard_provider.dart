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

  // Getters
  int get eventsCount => _eventsCount;
  int get participationsCount => _participationsCount;
  int get scansCount => _scansCount;
  List<Event> get recentEvents => _recentEvents;
  Map<int, int> get eventParticipations => _eventParticipations;
  bool get isLoading => _isLoading;

  Future<void> loadDashboardData({
    int? userId,
    UserRole? role,
    bool refresh = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Events
      // We request sorting by newest/descending if API supports it
      final eventsResponse = await _api.get('/events?sort=desc');

      List<dynamic> eventsData = [];
      int? apiTotalEvents;

      // Handle various API response structures (List vs Map with data/meta)
      if (eventsResponse is Map) {
        if (eventsResponse.containsKey('data')) {
          eventsData = eventsResponse['data'] as List<dynamic>;
        }
        // Try to grab total from API meta for accurate Admin stats
        if (eventsResponse.containsKey('total')) {
          apiTotalEvents = eventsResponse['total'] as int?;
        } else if (eventsResponse.containsKey('meta') &&
            eventsResponse['meta'] is Map) {
          apiTotalEvents = eventsResponse['meta']['total'] as int?;
        }
      } else if (eventsResponse is List) {
        eventsData = eventsResponse;
      }

      List<Event> allEvents = eventsData
          .map((json) => Event.fromJson(json))
          .toList();

      List<Event> filteredEvents = [];
      final now = DateTime.now();

      // --- RBAC Event Filtering ---
      if (role == UserRole.student) {
        // Students: See active future events
        filteredEvents = allEvents
            .where((e) => e.timeEnd.isAfter(now))
            .toList();

        // Students: Sort by "Soonest Starting"
        filteredEvents.sort((a, b) => a.timeStart.compareTo(b.timeStart));

        // Count for students is the number of active/upcoming events
        _eventsCount = filteredEvents.length;
      } else if (role == UserRole.admin) {
        // Organizers: Only see their own events
        if (userId != null) {
          filteredEvents = allEvents
              .where((e) => e.organizerId == userId)
              .toList();

          _eventsCount = filteredEvents.length;
        } else {
          _eventsCount = 0;
        }
        // Admins: Sort by Newest Created
        filteredEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        // Super Admin: Sees all
        filteredEvents = allEvents;
        filteredEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        // Use API total if available, otherwise list length
        _eventsCount = apiTotalEvents ?? filteredEvents.length;
      }

      // Limit Recent Events to Top 5
      _recentEvents = filteredEvents.take(5).toList();

      // 2. Fetch Participations
      try {
        final partResponse = await _api.get('/participations');
        List<dynamic> partData = [];

        if (partResponse is Map && partResponse.containsKey('data')) {
          partData = partResponse['data'] as List<dynamic>;
        } else if (partResponse is List) {
          partData = partResponse;
        }

        // Filter participations relevant to the visible events
        final visibleEventIds = filteredEvents.map((e) => e.id).toSet();

        final relevantParticipations = partData.where((p) {
          try {
            return visibleEventIds.contains(p['event_id'] as int);
          } catch (_) {
            return false;
          }
        }).toList();

        // --- Calculate Stats based on Role ---
        if (role == UserRole.student) {
          // STUDENT VIEW: "Today's" Stats
          final today = DateTime.now();

          final todayParticipations = relevantParticipations.where((p) {
            if (p['created_at'] == null) return false;
            try {
              final pDate = DateTime.parse(p['created_at'].toString());
              return pDate.year == today.year &&
                  pDate.month == today.month &&
                  pDate.day == today.day;
            } catch (e) {
              return false;
            }
          }).toList();

          _participationsCount = todayParticipations.length; // "Joined Today"
          _scansCount = todayParticipations.length; // "Scans Today"
        } else {
          // ADMIN VIEW: "Total" Stats (All Time)
          if (role == UserRole.superAdmin &&
              partResponse is Map &&
              partResponse.containsKey('total')) {
            _participationsCount = partResponse['total'] as int;
            _scansCount = _participationsCount;
          } else {
            _participationsCount = relevantParticipations.length;
            _scansCount = relevantParticipations.length;
          }
        }

        // Map for "Participants per Event" (used in event cards)
        _eventParticipations = {};
        for (var part in relevantParticipations) {
          final eventId = part['event_id'] as int;
          _eventParticipations[eventId] =
              (_eventParticipations[eventId] ?? 0) + 1;
        }
      } catch (e) {
        debugPrint('Error fetching participations: $e');
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

  // Placeholder for future pagination if needed
  Future<void> loadMoreEvents() async {}
}
