import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/app/app_theme.dart';
import 'package:flutter_qlct/finance/finance_models.dart';
import 'package:flutter_qlct/widgets/transaction_tile.dart';

void main() {
  testWidgets('income tile uses legible accent in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: TransactionTile(
            transaction: FinanceTransaction(
              id: 'income',
              amount: 85000,
              categoryId: 'salary',
              categoryName: 'Lương',
              categoryIcon: 'payments',
              categoryColor: '#18B892',
              type: 'income',
              note: '',
              date: DateTime(2026, 9, 26),
            ),
          ),
        ),
      ),
    );
    final amount = tester.widget<Text>(find.text('+85.000 ₫'));
    expect(amount.style?.color, AppTheme.dark.colorScheme.primary);
  });

  testWidgets('transaction tile shows real expense with Vietnamese amount', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionTile(
            transaction: FinanceTransaction(
              id: 'lunch',
              amount: 85000,
              categoryId: 'food',
              categoryName: 'Ăn uống',
              categoryIcon: 'restaurant',
              categoryColor: '#FF796B',
              type: 'expense',
              note: 'Bữa trưa',
              date: DateTime(2026, 9, 26),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('-85.000 ₫'), findsOneWidget);
    expect(find.text('Bữa trưa • 26/09/2026'), findsOneWidget);
  });
}
