import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/finance/finance_models.dart';
import 'package:flutter_qlct/finance/finance_repository.dart';
import 'package:flutter_qlct/screens/add_transaction_screen.dart';
import 'package:flutter_qlct/screens/budgets_screen.dart';
import 'package:flutter_qlct/screens/categories_screen.dart';
import 'package:flutter_qlct/screens/transaction_detail_screen.dart';
import 'package:flutter_qlct/screens/transactions_screen.dart';

class FeedbackRepository implements FinanceRepository {
  bool failDelete = false;

  @override
  Stream<List<FinanceCategory>> watchCategories() => Stream.multi((controller) {
    controller.add([
      const FinanceCategory(
        id: 'food',
        name: 'Ăn uống',
        icon: 'restaurant',
        color: '#FF796B',
        type: 'expense',
      ),
    ]);
    controller.close();
  }, isBroadcast: true);

  @override
  Stream<List<FinanceBudget>> watchBudgets() => Stream.value([
    const FinanceBudget(
      id: '2026-09-food',
      categoryId: 'food',
      categoryName: 'Ăn uống',
      limitAmount: 100000,
      month: '2026-09',
    ),
  ]);

  @override
  Stream<List<FinanceTransaction>> watchTransactions() => Stream.value([
    FinanceTransaction(
      id: 't',
      amount: 85000,
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
  Stream<FinanceTransaction?> watchTransaction(String id) =>
      watchTransactions().map((items) => items.first);

  @override
  Future<String> saveCategory({
    String? id,
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async => id ?? 'new';

  @override
  Future<void> deleteCategory(String id) async {
    if (failDelete) throw const FinanceFailure('Không thể xóa danh mục.');
  }

  @override
  Future<String> saveBudget({
    String? id,
    required String categoryId,
    required String month,
    required int limitAmount,
  }) async => id ?? 'b';

  @override
  Future<void> deleteBudget(String id) async {}

  @override
  Future<String> saveTransaction({
    String? id,
    required int amount,
    required String categoryId,
    required DateTime date,
    String note = '',
  }) async => id ?? 't';

  @override
  Future<void> deleteTransaction(String id) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('category save shows success on the parent screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: CategoriesScreen(repository: FeedbackRepository())),
    );
    await tester.pump();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Cà phê');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Đã lưu danh mục.'), findsOneWidget);
  });

  testWidgets('category cancelled or failed delete never shows success', (
    tester,
  ) async {
    final repository = FeedbackRepository();
    await tester.pumpWidget(
      MaterialApp(home: CategoriesScreen(repository: repository)),
    );
    await tester.pump();
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(find.text('Đã xóa danh mục.'), findsNothing);
    repository.failDelete = true;
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa').last);
    await tester.pumpAndSettle();
    expect(find.text('Đã xóa danh mục.'), findsNothing);
    expect(find.text('Không thể xóa danh mục.'), findsOneWidget);
  });

  testWidgets('budget save and delete show success after completion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BudgetsScreen(
          repository: FeedbackRepository(),
          initialMonth: DateTime(2026, 9),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ăn uống').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '100000');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Đã lưu ngân sách.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa').last);
    await tester.pumpAndSettle();
    expect(find.text('Đã xóa ngân sách.'), findsOneWidget);
  });

  testWidgets('transaction save and delete acknowledge on visible list', (
    tester,
  ) async {
    final repository = FeedbackRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionsScreen(repository: repository),
        onGenerateRoute: (settings) {
          if (settings.name == '/transactions/add') {
            return MaterialPageRoute<bool>(
              builder: (_) => AddTransactionScreen(repository: repository),
            );
          }
          if (settings.name == '/transactions/detail') {
            return MaterialPageRoute<bool>(
              builder: (_) => TransactionDetailScreen(
                transactionId: 't',
                repository: repository,
              ),
            );
          }
          return null;
        },
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '85000');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ăn uống').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn ngày'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu giao dịch'));
    await tester.pumpAndSettle();
    expect(find.text('Đã lưu giao dịch.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ăn uống').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Xóa giao dịch'));
    await tester.tap(find.text('Xóa giao dịch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa').last);
    await tester.pumpAndSettle();
    expect(find.text('Đã xóa giao dịch.'), findsOneWidget);
  });
}
