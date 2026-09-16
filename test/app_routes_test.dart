import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/app/app_routes.dart';
import 'package:flutter_qlct/screens/onboarding_screen.dart';

void main() {
  testWidgets('opens onboarding at the initial route', (tester) async {
    await tester.pumpWidget(MaterialApp(
      initialRoute: AppRoutes.onboarding,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    ));

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  test('declares the core navigation paths', () {
    expect(
        AppRoutes.all,
        containsAll(<String>[
          AppRoutes.onboarding,
          AppRoutes.login,
          AppRoutes.register,
          AppRoutes.home,
          AppRoutes.transactions,
          AppRoutes.addTransaction,
          AppRoutes.transactionDetail,
          AppRoutes.reports,
          AppRoutes.budgets,
          AppRoutes.settings,
        ]));
  });
}
