import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/event_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/home_screen.dart';

class AppProvidersWrapper extends StatelessWidget {
  const AppProvidersWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const HomeScreen(),
    );
  }
}
