import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'user_panel.dart';
import 'admin_panel.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;

          if (user == null) {
            return LoginScreen(); // Show login screen if user is not logged in
          } else if (user.email == 'admin@example.com') {
            return AdminPanel(); // Show admin panel for admin user
          } else {
            return UserPanel(userId: user.uid); // Show user panel for regular user
          }
        }

        // Show a loading indicator while checking authentication state
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}