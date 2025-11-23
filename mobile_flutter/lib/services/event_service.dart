import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/event.dart';
import 'api_service.dart';

class EventService {
  final ApiService _apiService = ApiService();

  Future<List<Event>> getEvents() async {
    try {
      final response = await _apiService.get('/events');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        debugPrint('Get events failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Get events error: $e');
      return [];
    }
  }

  Future<Event?> getEvent(int id) async {
    try {
      final response = await _apiService.get('/events/$id');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Event.fromJson(data);
      } else {
        debugPrint('Get event failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Get event error: $e');
      return null;
    }
  }

  Future<bool> createEvent(Event event) async {
    try {
      final response = await _apiService.post('/events', event.toJson());
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Create event error: $e');
      return false;
    }
  }

  Future<bool> updateEvent(Event event) async {
    try {
      final response = await _apiService.put(
        '/events/${event.id}',
        event.toJson(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update event error: $e');
      return false;
    }
  }

  Future<bool> deleteEvent(int id) async {
    try {
      final response = await _apiService.delete('/events/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Delete event error: $e');
      return false;
    }
  }
}
