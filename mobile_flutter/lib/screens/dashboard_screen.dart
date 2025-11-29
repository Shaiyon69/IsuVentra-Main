import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Placeholdeer for now, dashboard screen with basic layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   'Welcome to the Dashboard!',
            //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Stats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard('Events', '5', Icons.event),
                        _buildStatCard('Participations', '12', Icons.people),
                        _buildStatCard('Scans', '8', Icons.qr_code),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.event),
                    title: Text('Attended Event: Tech Conference'),
                    subtitle: Text('2 hours ago'),
                  ),
                  ListTile(
                    leading: Icon(Icons.qr_code_scanner),
                    title: Text('Scanned QR Code'),
                    subtitle: Text('5 hours ago'),
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Profile Updated'),
                    subtitle: Text('1 day ago'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
