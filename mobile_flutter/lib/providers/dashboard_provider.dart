import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

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
      final List<dynamic> eventsData = await _api.get('/events');
      final events = eventsData.map((json) => Event.fromJson(json)).toList();
      _eventsCount = events.length;
      _recentEvents = events.take(3).toList();

      final List<dynamic> partData = await _api.get('/participation');
      _participationsCount = partData.length;
      _scansCount = partData.length;
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
