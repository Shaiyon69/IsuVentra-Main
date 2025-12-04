class Event {
  final int id;
  final String title;
  final String? description;
  final DateTime timeStart;
  final DateTime timeEnd;
  final String? location;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.timeStart,
    required this.timeEnd,
    this.location,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      timeStart: DateTime.parse(json['time_start']),
      timeEnd: DateTime.parse(json['time_end']),
      location: json['location'],
    );
  }
}
