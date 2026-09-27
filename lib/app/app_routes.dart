import 'package:flutter/material.dart';

import '../auth/auth_gate.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/budgets_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/register_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/transaction_detail_screen.dart';
import '../screens/transactions_screen.dart';

abstract final class AppRoutes {
  static const start = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const transactions = '/transactions';
  static const addTransaction = '/transactions/add';
  static const transactionDetail = '/transactions/detail';
  static const reports = '/reports';
  static const budgets = '/budgets';
  static const categories = '/categories';
  static const settings = '/settings';

  static const all = <String>[
    start,
    onboarding,
    login,
    register,
    home,
    transactions,
    addTransaction,
    transactionDetail,
    reports,
    budgets,
    categories,
    settings,
  ];

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      start => const AuthGate(),
      onboarding => const OnboardingScreen(),
      login => const LoginScreen(),
      register => const RegisterScreen(),
      home => const AuthGate(protectedPage: HomeScreen()),
      transactions => const AuthGate(protectedPage: TransactionsScreen()),
      addTransaction => AuthGate(
        protectedPage: AddTransactionScreen(
          transactionId: settings.arguments as String?,
        ),
      ),
      transactionDetail => AuthGate(
        protectedPage: TransactionDetailScreen(
          transactionId: settings.arguments as String,
        ),
      ),
      reports => const AuthGate(protectedPage: ReportsScreen()),
      budgets => const AuthGate(protectedPage: BudgetsScreen()),
      categories => const AuthGate(protectedPage: CategoriesScreen()),
      AppRoutes.settings => const AuthGate(protectedPage: SettingsScreen()),
      _ => const AuthGate(),
    };

    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final slide =
            Tween<Offset>(
              begin: const Offset(.04, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}
