import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../users/login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<UserProvider>(context, listen: false).loadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      userProvider.name.isNotEmpty
                          ? userProvider.name[0].toUpperCase()
                          : 'G',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoCard(
                  icon: Icons.person,
                  label: 'Name',
                  value: userProvider.name,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.email,
                  label: 'Email',
                  value: userProvider.email,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.badge,
                  label: 'Student ID',
                  value: userProvider.studentId.isNotEmpty
                      ? userProvider.studentId
                      : 'Not available',
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.school,
                  label: 'Course',
                  value: userProvider.course.isNotEmpty
                      ? userProvider.course
                      : 'Not available',
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.grade,
                  label: 'Year Level',
                  value: userProvider.yearLevel.isNotEmpty
                      ? userProvider.yearLevel
                      : 'Not available',
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.location_on,
                  label: 'Campus',
                  value: userProvider.campus.isNotEmpty
                      ? userProvider.campus
                      : 'Not available',
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.logout();
                      userProvider.clearUser();

                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const Login()),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
