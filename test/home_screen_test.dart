import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/app/app_theme.dart';
import 'package:flutter_qlct/finance/finance_models.dart';
import 'package:flutter_qlct/finance/finance_repository.dart';
import 'package:flutter_qlct/screens/home_screen.dart';

FinanceTransaction transaction(
  String id,
  int amount,
  String type,
  DateTime date,
) => FinanceTransaction(
  id: id,
  amount: amount,
  categoryId: 'food',
  categoryName: 'Ăn uống',
  categoryIcon: 'restaurant',
  categoryColor: '#FF796B',
  type: type,
  note: '',
  date: date,
);

class HomeRepository implements FinanceRepository {
  HomeRepository(this.transactions, this.budgets);

  final List<FinanceTransaction> transactions;
  final List<FinanceBudget> budgets;

  @override
  Stream<List<FinanceTransaction>> watchTransactions() =>
      Stream.value(transactions);

  @override
  Stream<FinanceTransactionSnapshot> watchTransactionsWithSource() =>
      Stream.value(
        FinanceTransactionSnapshot(items: transactions, isFromCache: false),
      );

  @override
  Stream<List<FinanceBudget>> watchBudgets() => Stream.value(budgets);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime(2026, 9, 27);

  testWidgets('home moves to the new month while left open', (tester) async {
    var current = DateTime(2026, 9, 30, 23, 59, 59);
    final repository = HomeRepository([
      transaction('oct', 200000, 'expense', DateTime(2026, 10, 1)),
      transaction('sep', 100000, 'expense', DateTime(2026, 9, 30)),
    ], []);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: repository,
          clock: () => current,
          displayName: 'An',
        ),
      ),
    );
    await tester.pump();
    expect(find.text('100.000 ₫'), findsWidgets);
    current = DateTime(2026, 10, 1, 0, 0, 1);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('200.000 ₫'), findsWidgets);
    expect(find.text('01/10/2026'), findsOneWidget);
  });

  testWidgets('home does not call exactly-used budget an overrun', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: HomeRepository(
            [transaction('exact', 1000000, 'expense', DateTime(2026, 9, 26))],
            const [
              FinanceBudget(
                id: 'b',
                categoryId: 'food',
                categoryName: 'Ăn uống',
                limitAmount: 1000000,
                month: '2026-09',
              ),
            ],
          ),
          now: now,
          displayName: 'An',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đã dùng hết ngân sách'), findsOneWidget);
    expect(find.textContaining('Đã vượt 0 ₫'), findsNothing);
  });

  testWidgets('home income accent stays legible in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: HomeScreen(
          repository: HomeRepository([
            transaction('income', 100000, 'income', DateTime(2026, 9, 26)),
          ], []),
          now: now,
          displayName: 'An',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final income = tester
        .widgetList<Text>(find.text('100.000 ₫'))
        .firstWhere(
          (text) =>
              text.style?.fontSize ==
              AppTheme.dark.textTheme.labelLarge?.fontSize,
        );
    expect(income.style?.color, AppTheme.dark.colorScheme.primary);
  });

  testWidgets(
    'home shows all-time balance but current-month income and expense',
    (tester) async {
      final repository = HomeRepository([
        transaction('sep-expense', 200000, 'expense', DateTime(2026, 9, 26)),
        transaction('sep-income', 1000000, 'income', DateTime(2026, 9, 25)),
        transaction('aug-expense', 100000, 'expense', DateTime(2026, 8, 25)),
        transaction('aug-income', 500000, 'income', DateTime(2026, 8, 24)),
      ], []);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(repository: repository, now: now, displayName: 'An'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Xin chào, An'), findsOneWidget);
      expect(find.text('1.200.000 ₫'), findsOneWidget);
      expect(find.text('Thu nhập tháng này'), findsOneWidget);
      expect(find.text('1.000.000 ₫'), findsOneWidget);
      expect(find.text('Chi tiêu tháng này'), findsOneWidget);
      expect(find.text('200.000 ₫'), findsOneWidget);
    },
  );

  testWidgets(
    'home shows five recent transactions and actual over-budget amount',
    (tester) async {
      final repository = HomeRepository(
        [
          for (var day = 26; day >= 20; day--)
            transaction('$day', 250000, 'expense', DateTime(2026, 9, day)),
        ],
        const [
          FinanceBudget(
            id: 'b',
            categoryId: 'food',
            categoryName: 'Ăn uống',
            limitAmount: 1000000,
            month: '2026-09',
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(repository: repository, now: now, displayName: 'An'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Đã vượt 750.000 ₫'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        1,
      );
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();
      expect(find.textContaining('26/09/2026'), findsOneWidget);
      expect(find.textContaining('22/09/2026'), findsOneWidget);
      expect(find.textContaining('21/09/2026'), findsNothing);
    },
  );

  testWidgets('empty home offers budget and transaction actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: HomeRepository([], []),
          now: now,
          displayName: '',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Xin chào!'), findsOneWidget);
    expect(find.textContaining('Tạo ngân sách tháng này'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hãy thêm giao dịch đầu tiên'), findsOneWidget);
  });

  testWidgets('home has no overflow on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: HomeRepository([
            transaction('a', 123456789, 'income', DateTime(2026, 9, 26)),
          ], []),
          now: now,
          displayName: 'Nguyễn Văn An',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
