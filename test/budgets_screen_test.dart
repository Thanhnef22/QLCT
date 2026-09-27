import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/app/app_theme.dart';
import 'package:flutter_qlct/finance/finance_models.dart';
import 'package:flutter_qlct/finance/finance_repository.dart';
import 'package:flutter_qlct/screens/budgets_screen.dart';

class _Repository implements FinanceRepository {
  @override
  Stream<List<FinanceBudget>> watchBudgets() => Stream.value([
    const FinanceBudget(
      id: 'b',
      categoryId: 'food',
      categoryName: 'Ăn uống',
      limitAmount: 1000000,
      month: '2026-09',
    ),
  ]);
  @override
  Stream<List<FinanceTransaction>> watchTransactions() => Stream.value([
    FinanceTransaction(
      id: 't',
      amount: 850000,
      categoryId: 'food',
      categoryName: 'Ăn uống',
      categoryIcon: 'restaurant',
      categoryColor: '#FF796B',
      type: 'expense',
      note: '',
      date: DateTime(2026, 9, 26),
    ),
  ]);
  @override
  Stream<List<FinanceCategory>> watchCategories() => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RenamedRepository extends _Repository {
  @override
  Stream<List<FinanceCategory>> watchCategories() => Stream.value([
    const FinanceCategory(
      id: 'food',
      name: 'Ăn uống mới',
      icon: 'restaurant',
      color: '#FF796B',
      type: 'expense',
    ),
  ]);
  @override
  Stream<List<FinanceTransaction>> watchTransactions() => Stream.value([
    FinanceTransaction(
      id: 't',
      amount: 995000,
      categoryId: 'food',
      categoryName: 'Ăn uống',
      categoryIcon: 'restaurant',
      categoryColor: '#FF796B',
      type: 'expense',
      note: '',
      date: DateTime(2026, 9, 26),
    ),
  ]);
}

void main() {
  testWidgets('dark budget progress uses a subdued dark track', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: BudgetsScreen(
          repository: _Repository(),
          initialMonth: DateTime(2026, 9),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final tracks = tester.widgetList<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(
      tracks.first.backgroundColor,
      AppTheme.dark.colorScheme.surfaceContainerHighest,
    );
  });

  testWidgets('budget shows spent and warning for selected month', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BudgetsScreen(
          repository: _Repository(),
          initialMonth: DateTime(2026, 9),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Sắp vượt'), findsOneWidget);
    expect(find.textContaining('850.000 ₫'), findsWidgets);
  });

  testWidgets(
    'budget reflects renamed category without showing 100 percent early',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BudgetsScreen(
            repository: _RenamedRepository(),
            initialMonth: DateTime(2026, 9),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('Ăn uống mới'), findsOneWidget);
      expect(find.text('Sắp vượt'), findsOneWidget);
      expect(find.text('99%'), findsOneWidget);
    },
  );
}
