import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/participation_service.dart';

class DashboardProvider extends ChangeNotifier {
  final EventService _eventService = EventService();
  final ParticipationService _participationService = ParticipationService();

  int _eventsCount = 0;
  int _participationsCount = 0;
  int _scansCount = 0;
  List<Event> _recentEvents = [];
  bool _isLoading = false;

  int get eventsCount => _eventsCount;
  int get participationsCount => _participationsCount;
  int get scansCount => _scansCount;
  List<Event> get recentEvents => _recentEvents;
  bool get isLoading => _isLoading;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final events = await _eventService.getEvents();
      _eventsCount = events.length;

      final participations = await _participationService.getParticipations();
      _participationsCount = participations.length;

      _scansCount = participations.length;
      _recentEvents = events.take(3).toList();
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
