class Participation {
  final int id;
  final int studentId;
  final int eventId;
  final String studentName;
  final String eventName;
  final DateTime? timeIn;
  final DateTime? timeOut;

  Participation({
    required this.id,
    required this.studentId,
    required this.eventId,
    required this.studentName,
    required this.eventName,
    this.timeIn,
    this.timeOut,
  });

  factory Participation.fromJson(Map<String, dynamic> json) {
    return Participation(
      id: json['id'],
      studentId: json['student_id'],
      eventId: json['event_id'],
      studentName: json['student_name'] ?? 'Unknown',
      eventName: json['event_name'] ?? 'Unknown',
      timeIn: json['time_in'] != null ? DateTime.parse(json['time_in']) : null,
      timeOut: json['time_out'] != null
          ? DateTime.parse(json['time_out'])
          : null,
    );
  }
}
