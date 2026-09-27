import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/app/app_theme.dart';
import 'package:flutter_qlct/finance/finance_models.dart';
import 'package:flutter_qlct/finance/finance_repository.dart';
import 'package:flutter_qlct/screens/transaction_detail_screen.dart';

class _Repository implements FinanceRepository {
  _Repository(this.item);
  final FinanceTransaction item;
  @override
  Stream<FinanceTransaction?> watchTransaction(String id) => Stream.value(item);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('dark transaction detail uses a dark hero surface', (
    tester,
  ) async {
    final item = FinanceTransaction(
      id: 'dark',
      amount: 85000,
      categoryId: 'food',
      categoryName: 'Ăn uống',
      categoryIcon: 'restaurant',
      categoryColor: '#FF796B',
      type: 'expense',
      note: '',
      date: DateTime(2026, 9, 26),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: TransactionDetailScreen(
          transactionId: 'dark',
          repository: _Repository(item),
        ),
      ),
    );
    await tester.pump();
    final hero = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere(
          (container) =>
              (container.decoration as BoxDecoration?)?.borderRadius ==
              BorderRadius.circular(24),
        );
    expect(
      (hero.decoration as BoxDecoration).color!.computeLuminance(),
      lessThan(0.2),
    );
  });

  testWidgets('detail displays actual transaction fields', (tester) async {
    final item = FinanceTransaction(
      id: 'a',
      amount: 85000,
      categoryId: 'food',
      categoryName: 'Ăn uống',
      categoryIcon: 'restaurant',
      categoryColor: '#FF796B',
      type: 'expense',
      note: 'Bữa trưa',
      date: DateTime(2026, 9, 26),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionDetailScreen(
          transactionId: 'a',
          repository: _Repository(item),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('-85.000 ₫'), findsOneWidget);
    expect(find.text('26/09/2026'), findsOneWidget);
    expect(find.text('Bữa trưa'), findsOneWidget);
  });
}
