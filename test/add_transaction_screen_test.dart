import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/finance/finance_models.dart';
import 'package:flutter_qlct/finance/finance_repository.dart';
import 'package:flutter_qlct/screens/add_transaction_screen.dart';

class _Repository implements FinanceRepository {
  @override
  Stream<List<FinanceCategory>> watchCategories() => Stream.value([
    const FinanceCategory(
      id: 'food',
      name: 'Ăn uống',
      icon: 'restaurant',
      color: '#FF796B',
      type: 'expense',
    ),
  ]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'transaction form validates amount, category and date in Vietnamese',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AddTransactionScreen(repository: _Repository())),
      );
      await tester.pump();
      await tester.tap(find.text('Lưu giao dịch'));
      await tester.pump();
      expect(find.text('Vui lòng nhập số tiền.'), findsOneWidget);
      expect(find.text('Vui lòng chọn danh mục.'), findsOneWidget);
      expect(find.text('Vui lòng chọn ngày giao dịch.'), findsOneWidget);
    },
  );
}
