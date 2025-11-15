class Student {
  final int id;
  final int userId;
  final String studentId;
  final String name;
  final String course;
  final int yearLvl;
  final String campus;

  Student({
    required this.id,
    required this.userId,
    required this.studentId,
    required this.name,
    required this.course,
    required this.yearLvl,
    required this.campus,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      userId: json['user_id'],
      studentId: json['student_id'],
      name: json['name'],
      course: json['course'],
      yearLvl: json['year_lvl'],
      campus: json['campus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'student_id': studentId,
      'name': name,
      'course': course,
      'year_lvl': yearLvl,
      'campus': campus,
    };
  }
}
