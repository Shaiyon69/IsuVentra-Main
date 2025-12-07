import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/event_model.dart';

class EventProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<dynamic> data = await _api.get('/events');
      _events = data.map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Event Error: $e");
      _errorMessage = "Failed to load events. Please try again.";
      _events = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEvents() => fetchEvents();

  Future<void> createEvent(Event event) async {
    try {
      await _api.post('/events', {
        'title': event.title,
        'description': event.description,
        'time_start': DateFormat('yyyy-MM-dd HH:mm:ss').format(event.timeStart),
        'time_end': DateFormat('yyyy-MM-dd HH:mm:ss').format(event.timeEnd),
        'location': event.location,
        'creator_id': event.creatorId,
      });
      await fetchEvents(); // Refresh the events list
    } catch (e) {
      debugPrint("Create Event Error: $e");
      throw Exception('Failed to create event');
    }
  }

  List<Event> searchAndSortEvents(String query) {
    List<Event> filteredEvents = _events
        .where(
          (event) =>
              event.title.toLowerCase().contains(query.toLowerCase()) ||
              (event.description?.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              (event.location?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        )
        .toList();

    // Sort by createdAt in descending order (most recent first)
    filteredEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filteredEvents;
  }
}
