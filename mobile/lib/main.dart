import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'widgets/auth_gate.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 3));
    AuthService.instance.initializeWithFirebase();
  } catch (e) {
    debugPrint('Firebase.initializeApp notice: $e. App running with seamless fallback.');
    AuthService.instance.initializeWithFirebase();
  }

  runApp(const SmartNutriApp());
}

class SmartNutriApp extends StatefulWidget {
  const SmartNutriApp({super.key});

  @override
  State<SmartNutriApp> createState() => _SmartNutriAppState();
}

class _SmartNutriAppState extends State<SmartNutriApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartNutri',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: AuthGate(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}
