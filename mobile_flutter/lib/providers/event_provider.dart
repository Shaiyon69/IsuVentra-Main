import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';

class EventProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Now accepts context for filtering
  Future<void> fetchEvents({int? userId, UserRole? role}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get('/events');

      List<dynamic> data;
      if (response is Map && response.containsKey('data')) {
        data = response['data'] as List<dynamic>;
      } else if (response is List) {
        data = response;
      } else {
        throw Exception('Unexpected response format');
      }

      List<Event> allEvents = data.map((json) => Event.fromJson(json)).toList();

      // --- RBAC FILTERING ---
      if (role == UserRole.student) {
        // Students: Active events only (Ending in future)
        final now = DateTime.now();
        _events = allEvents.where((e) => e.timeEnd.isAfter(now)).toList();
      } else if (role == UserRole.admin) {
        // Organizers: Only events created by/assigned to them
        if (userId != null) {
          _events = allEvents.where((e) => e.organizerId == userId).toList();
        } else {
          _events = [];
        }
      } else {
        // Super Admin: See All
        _events = allEvents;
      }
    } catch (e) {
      debugPrint("Event Error: $e");
      _errorMessage = "Failed to load events. Please try again.";
      _events = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Alias for backward compatibility if needed
  Future<void> loadEvents() => fetchEvents();

  Future<void> createEvent(Event event) async {
    try {
      await _api.post('/events', {
        'title': event.title,
        'description': event.description,
        'time_start': DateFormat('yyyy-MM-dd HH:mm:ss').format(event.timeStart),
        'time_end': DateFormat('yyyy-MM-dd HH:mm:ss').format(event.timeEnd),
        'location': event.location,
        // Backend should handle assigning organizer_id based on auth token
      });
      // Re-fetch to update list (requires passing context again in UI, or just fetching all)
      // Ideally, the UI triggers a refresh with the correct credentials.
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

    filteredEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filteredEvents;
  }
}
