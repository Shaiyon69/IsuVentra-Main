class Event {
  final int id;
  final String title;
  final String? description;
  final String timeStart;
  final String timeEnd;
  final String location;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.timeStart,
    required this.timeEnd,
    required this.location,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      timeStart: json['time_start'],
      timeEnd: json['time_end'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'time_start': timeStart,
      'time_end': timeEnd,
      'location': location,
    };
  }
}
