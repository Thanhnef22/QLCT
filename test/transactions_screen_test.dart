import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/finance/finance_models.dart';
import 'package:flutter_qlct/finance/finance_repository.dart';
import 'package:flutter_qlct/screens/transactions_screen.dart';

class _Repository implements FinanceRepository {
  _Repository(this.items);
  final List<FinanceTransaction> items;

  @override
  Stream<List<FinanceTransaction>> watchTransactions() => Stream.value(items);

  @override
  Stream<List<FinanceCategory>> watchCategories() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RetryRepository extends _Repository {
  _RetryRepository() : super([]);
  int attempts = 0;
  @override
  Stream<List<FinanceTransaction>> watchTransactions() {
    attempts++;
    return attempts == 1
        ? Stream.error(Exception('offline'))
        : Stream.value([]);
  }
}

void main() {
  testWidgets('empty transactions offer add action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TransactionsScreen(repository: _Repository([]))),
    );
    await tester.pump();
    expect(find.text('Chưa có giao dịch'), findsOneWidget);
    expect(find.text('Thêm giao dịch'), findsWidgets);
  });

  testWidgets('search filters real transactions by note', (tester) async {
    final items = [
      FinanceTransaction(
        id: 'a',
        amount: 85000,
        categoryId: 'food',
        categoryName: 'Ăn uống',
        categoryIcon: 'restaurant',
        categoryColor: '#FF796B',
        type: 'expense',
        note: 'Bữa trưa',
        date: DateTime(2026, 9, 26),
      ),
      FinanceTransaction(
        id: 'b',
        amount: 2000000,
        categoryId: 'salary',
        categoryName: 'Lương',
        categoryIcon: 'payments',
        categoryColor: '#18B892',
        type: 'income',
        note: 'Tháng này',
        date: DateTime(2026, 9, 25),
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(home: TransactionsScreen(repository: _Repository(items))),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'trưa');
    await tester.pump();
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Lương'), findsNothing);
  });

  testWidgets('filter sheet can apply and reset', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TransactionsScreen(repository: _Repository([]))),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Bộ lọc'));
    await tester.pumpAndSettle();
    expect(find.text('Lọc giao dịch'), findsOneWidget);
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry recreates a failed transaction stream', (tester) async {
    final repository = _RetryRepository();
    await tester.pumpWidget(
      MaterialApp(home: TransactionsScreen(repository: repository)),
    );
    await tester.pump();
    expect(find.textContaining('Không thể tải dữ liệu'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();
    expect(repository.attempts, 2);
    expect(find.text('Chưa có giao dịch'), findsOneWidget);
  });
}
