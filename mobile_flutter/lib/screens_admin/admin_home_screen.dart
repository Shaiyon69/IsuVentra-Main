import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart'; // We will create this next
import 'admin_event_management_screen.dart'; // We will create this next
import '../screens/qr_scanner_screen.dart'; // Admin uses scanner for participation
import 'profile_screen.dart'; // We can reuse this with small tweaks

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(), // New Admin Dashboard
    const EventListScreen(), // CRUD for Events
    const QRScannerScreen(), // Scan QR Codes for participation
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ADMIN PORTAL',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_calendar_outlined),
            selectedIcon: Icon(Icons.edit_calendar),
            label: 'Manage Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2),
            selectedIcon: Icon(Icons.qr_code),
            label: 'Generate QR',
          ),
        ],
      ),
    );
  }
}
