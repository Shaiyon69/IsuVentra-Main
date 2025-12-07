// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import Providers
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/participation_provider.dart';
import 'providers/student_provider.dart';

// Import Screens
import 'auth/login.dart';
import 'theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => ParticipationProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'IsuVentra',
        theme: AppTheme.lightTheme(),
        home: const Login(),
      ),
    );
  }
}
