import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/finance/finance_models.dart';
import 'package:flutter_qlct/finance/finance_repository.dart';
import 'package:flutter_qlct/screens/categories_screen.dart';

class _Repository implements FinanceRepository {
  String? savedType;
  @override
  Stream<List<FinanceCategory>> watchCategories() => Stream.value([
    const FinanceCategory(
      id: 'food',
      name: 'Ăn uống',
      icon: 'restaurant',
      color: '#FF796B',
      type: 'expense',
    ),
    const FinanceCategory(
      id: 'salary',
      name: 'Lương',
      icon: 'payments',
      color: '#18B892',
      type: 'income',
    ),
  ]);
  @override
  Future<String> saveCategory({
    String? id,
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    savedType = type;
    return id ?? 'new';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RetryRepository extends _Repository {
  int attempts = 0;
  @override
  Stream<List<FinanceCategory>> watchCategories() {
    attempts++;
    return attempts == 1
        ? Stream.error(Exception('offline'))
        : super.watchCategories();
  }
}

void main() {
  testWidgets('category tabs separate expense and income', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CategoriesScreen(repository: _Repository())),
    );
    await tester.pump();
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Lương'), findsNothing);
    await tester.tap(find.text('Thu nhập'));
    await tester.pump();
    expect(find.text('Lương'), findsOneWidget);
    expect(find.text('Ăn uống'), findsNothing);
  });

  testWidgets('editing an unused category can change its type', (tester) async {
    final repository = _Repository();
    await tester.pumpWidget(
      MaterialApp(home: CategoriesScreen(repository: repository)),
    );
    await tester.pump();
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chỉnh sửa'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Thu nhập'),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(repository.savedType, 'income');
  });

  testWidgets('category retry opens a fresh stream', (tester) async {
    final repository = _RetryRepository();
    await tester.pumpWidget(
      MaterialApp(home: CategoriesScreen(repository: repository)),
    );
    await tester.pump();
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();
    expect(repository.attempts, 2);
    expect(find.text('Ăn uống'), findsOneWidget);
  });
}
