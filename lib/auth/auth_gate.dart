import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import 'auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({this.protectedPage, this.authState, super.key});

  final Widget? protectedPage;
  final Stream<bool>? authState;

  @override
  Widget build(BuildContext context) {
    final stream =
        authState ??
        AuthService().authStateChanges.map((User? user) => user != null);
    return StreamBuilder<bool>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.data!) return const LoginScreen();
        return protectedPage ?? const HomeScreen();
      },
    );
  }
}
