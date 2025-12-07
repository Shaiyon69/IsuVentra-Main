class Student {
  final int id;
  final String studentId;
  final String lrn;
  final String name;
  final String course;
  final String yearLevel;
  final String department;

  Student({
    required this.id,
    required this.studentId,
    required this.lrn,
    required this.name,
    required this.course,
    required this.yearLevel,
    required this.department,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      studentId: json['student_id'],
      lrn: json['lrn'],
      name: json['name'],
      course: json['course'],
      yearLevel: json['year_lvl'].toString(),
      department: json['department'],
    );
  }
}
