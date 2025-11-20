import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class EventProvider with ChangeNotifier {
  List<Event> events = [];
  bool isLoading = false;
  String? errorMessage;

  final EventService _service = EventService();

  Future<void> loadEvents() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      events = await _service.getEvents();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to load events: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createEvent(Event event) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.createEvent(event);
      if (success) {
        await loadEvents();
      } else {
        errorMessage = 'Failed to create event';
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Failed to create event: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEvent(Event event) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.updateEvent(event);
      if (success) {
        await loadEvents();
      } else {
        errorMessage = 'Failed to update event';
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Failed to update event: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEvent(int id) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.deleteEvent(id);
      if (success) {
        await loadEvents();
      } else {
        errorMessage = 'Failed to delete event';
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Failed to delete event: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
