import 'package:flutter/material.dart';
import 'app/app_routes.dart';
import 'app/app_theme.dart';

void main() {
  runApp(const QlctApp());
}

class QlctApp extends StatelessWidget {
  const QlctApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QLCT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.onboarding,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
