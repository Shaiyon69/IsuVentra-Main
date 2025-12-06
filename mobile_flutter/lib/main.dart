import 'package:flutter/material.dart';
import 'providers/participation_provider.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
// import 'providers/user_provider.dart';
import 'providers/event_provider.dart';
import 'providers/dashboard_provider.dart';
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
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        // ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => ParticipationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        home: const Login(),
      ),
    );
  }
}
