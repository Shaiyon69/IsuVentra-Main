class User {
  final int id;
  final String name;
  final String email;
  final bool isAdmin;

  final String? studentId;
  final String? course;
  final String? yearLevel;
  final String? department;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,

    this.studentId,
    this.course,
    this.yearLevel,
    this.department,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      isAdmin: json['is_admin'] == 1 || json['is_admin'] == true,

      studentId: json['student_id'],
      course: json['course'],
      yearLevel: json['year_level']?.toString(),
      department: json['department'],
    );
  }
}
