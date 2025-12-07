class Event {
  final int id;
  final String title;
  final String? description;
  final DateTime timeStart;
  final DateTime timeEnd;
  final String? location;
  final DateTime createdAt;
  final int? creatorId;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.timeStart,
    required this.timeEnd,
    this.location,
    required this.createdAt,
    this.creatorId,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      timeStart: DateTime.parse(json['time_start']),
      timeEnd: DateTime.parse(json['time_end']),
      location: json['location'],
      createdAt: DateTime.parse(json['created_at']),
      creatorId: json['creator_id'],
    );
  }
}
