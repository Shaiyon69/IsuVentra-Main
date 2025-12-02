import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'event_list_screen.dart';
import 'qr_scanner_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Screen List
  final List<Widget> _screens = [
    const DashboardScreen(),
    const EventListScreen(),
    const QRScannerScreen(),
  ];

  // Titles correspond to the screens
  static const List<String> _titles = ['Dashboard', 'Events', 'Scanner'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false, // Standard M3 alignment
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              tooltip: 'Profile',
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        // Optional: Make the nav bar transparent or colored
        // backgroundColor: colorScheme.surface,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.qr_code_scanner,
            ), // No outlined variant for this standard icon
            selectedIcon: Icon(Icons.qr_code_2),
            label: 'Scanner',
          ),
        ],
      ),
    );
  }
}
