import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_routes.dart';
import 'app/app_theme.dart';
import 'app/theme_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final preferences = await SharedPreferences.getInstance();
  runApp(QlctApp(themeController: ThemeController(preferences)));
}

class QlctApp extends StatefulWidget {
  const QlctApp({this.themeController, super.key});

  final ThemeController? themeController;

  @override
  State<QlctApp> createState() => _QlctAppState();
}

class _QlctAppState extends State<QlctApp> {
  ThemeController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.themeController;
    if (_controller == null) {
      SharedPreferences.getInstance().then((preferences) {
        if (mounted) setState(() => _controller = ThemeController(preferences));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return ThemeControllerScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => MaterialApp(
          title: 'QLCT',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: controller.mode,
          initialRoute: AppRoutes.start,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
  }
}
