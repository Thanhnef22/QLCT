import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/app/app_routes.dart';
import 'package:flutter_qlct/auth/auth_gate.dart';
import 'package:flutter_qlct/screens/login_screen.dart';

void main() {
  testWidgets('unauthenticated users see login at startup', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AuthGate(authState: Stream.value(false))),
    );
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  test('declares the core navigation paths', () {
    expect(
      AppRoutes.all,
      containsAll(<String>[
        AppRoutes.onboarding,
        AppRoutes.start,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.home,
        AppRoutes.transactions,
        AppRoutes.addTransaction,
        AppRoutes.transactionDetail,
        AppRoutes.reports,
        AppRoutes.budgets,
        AppRoutes.categories,
        AppRoutes.settings,
      ]),
    );
  });
}
