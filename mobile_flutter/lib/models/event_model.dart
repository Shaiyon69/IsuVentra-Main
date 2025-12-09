class Event {
  final int id;
  final String title;
  final String? description;
  final DateTime timeStart;
  final DateTime timeEnd;
  final String? location;
  final int organizerId; // Added for RBAC filtering
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.timeStart,
    required this.timeEnd,
    this.location,
    required this.organizerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      timeStart: DateTime.parse(json['time_start']),
      timeEnd: DateTime.parse(json['time_end']),
      location: json['location'],
      // Default to 0 if null to prevent crashes, implies unassigned
      organizerId: json['organizer_id'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
