enum UserRole {
  student,
  admin, // Organizer
  superAdmin,
}

class User {
  final int id;
  final String name;
  final String email;
  final UserRole role;

  final String? studentId;
  final String? course;
  final String? yearLevel;
  final String? department;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
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
      role: _parseRole(json['role'] ?? json['is_admin']),
      studentId: json['student_id'],
      course: json['course'],
      yearLevel: json['year_level']?.toString(),
      department: json['department'],
    );
  }

  static UserRole _parseRole(dynamic roleData) {
    if (roleData is String) {
      switch (roleData.toLowerCase()) {
        case 'super_admin':
        case 'superadmin':
          return UserRole.superAdmin;
        case 'admin':
        case 'organizer':
          return UserRole.admin;
        case 'user':
        case 'student':
        default:
          return UserRole.student;
      }
    }
    if (roleData is int) {
      if (roleData == 1) return UserRole.superAdmin;
      if (roleData == 2) return UserRole.admin;
    }
    return UserRole.student;
  }
}
