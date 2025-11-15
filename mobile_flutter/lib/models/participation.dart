class Participation {
  final int id;
  final int studentId;
  final int eventId;
  final String timeIn;
  final String? timeOut;

  Participation({
    required this.id,
    required this.studentId,
    required this.eventId,
    required this.timeIn,
    this.timeOut,
  });

  factory Participation.fromJson(Map<String, dynamic> json) {
    return Participation(
      id: json['id'],
      studentId: json['student_id'],
      eventId: json['event_id'],
      timeIn: json['time_in'],
      timeOut: json['time_out'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'event_id': eventId,
      'time_in': timeIn,
      'time_out': timeOut,
    };
  }
}
