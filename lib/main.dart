// ============================================================
// DAD (Drink and Drive) - Mobile Application
// ============================================================
// Flutter app entry point.
// Always shows the Landing page on app start.
// Session is restored silently in the background so the
// auth state is available when the user logs in.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/landing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DadApp());
}

class DadApp extends StatelessWidget {
  const DadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..restoreSession()),
      ],
      child: MaterialApp(
        title: 'DAD - Drink and Drive',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: const StartupScreen(),
      ),
    );
  }
}

// Always show the Landing page on app start.
// The session is restored silently in the background so that
// when the user logs in (via "Let's Hire" or "other logins"),
// the auth state is already available.
class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LandingScreen();
  }
}
