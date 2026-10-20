import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/home_navigation_screen.dart';
import '../screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const AuthGate({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthUser?>(
      stream: AuthService.instance.authStateChanges,
      initialData: AuthService.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user != null) {
          return HomeNavigationScreen(
            onToggleTheme: onToggleTheme,
            isDarkMode: isDarkMode,
          );
        }

        return LoginScreen(
          onToggleTheme: onToggleTheme,
          isDarkMode: isDarkMode,
        );
      },
    );
  }
}
