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
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is int) {
        // Handle epoch in seconds or milliseconds
        if (v > 1000000000000) {
          // milliseconds
          return DateTime.fromMillisecondsSinceEpoch(v);
        } else {
          return DateTime.fromMillisecondsSinceEpoch(v * 1000);
        }
      }
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          // Try common alternative formats
          try {
            return DateTime.parse(v.replaceAll(' ', 'T'));
          } catch (_) {
            return null;
          }
        }
      }
      return null;
    }

    return Participation(
      id: json['id'],
      studentId: json['student_id'],
      eventId: json['event_id'],
      studentName: json['student_name'] ?? 'Unknown',
      eventName: json['event_name'] ?? 'Unknown',
      timeIn: parseDate(json['time_in']),
      timeOut: parseDate(json['time_out']),
    );
  }
}
