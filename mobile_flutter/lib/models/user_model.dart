class User {
  final int id;
  final String name;
  final String email;
  final int adminLevel; // 0: user, 1: super admin, 2: admin

  final String? studentId;
  final String? course;
  final String? yearLevel;
  final String? department;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.adminLevel,

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
      adminLevel: json['is_admin'] ?? 0,

      studentId: json['student_id'],
      course: json['course'],
      yearLevel: json['year_level']?.toString(),
      department: json['department'],
    );
  }
}
