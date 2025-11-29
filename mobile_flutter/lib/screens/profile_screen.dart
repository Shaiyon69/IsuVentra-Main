import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../auth/login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final userMap = userProvider.currentUser;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // const Text(
                      //   'Student Profile',
                      //   style: TextStyle(
                      //     fontSize: 22,
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
                      // IconButton(
                      //   onPressed: () async {
                      //     await userProvider.refreshUser();
                      //   },
                      //   icon: const Icon(Icons.refresh),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        userProvider.name.isNotEmpty
                            ? userProvider.name[0].toUpperCase()
                            : 'G',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Basic user info
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
                  const SizedBox(height: 24),

                  const Text(
                    'Student Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

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

                  if (userMap != null && userMap.isNotEmpty) ...[
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Other details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final entry in userMap.entries)
                              if (entry.key != 'name' && entry.key != 'email')
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${entry.key}: ',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          entry.value?.toString() ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        await authProvider.logout();
                        userProvider.clearUser();

                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => Login()),
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
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
      ),
    );
  }

  // Remove this on later builds or change it to different one -Shaine
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
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
