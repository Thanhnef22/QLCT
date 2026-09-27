import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/finance/finance_format.dart';
import 'package:flutter_qlct/finance/finance_models.dart';
import 'package:flutter_qlct/finance/finance_rules.dart';

void main() {
  test('formats and parses Vietnamese money and dates', () {
    expect(formatVnd(1250000), '1.250.000 ₫');
    expect(parseVnd('1.250.000'), 1250000);
    expect(parseVnd('0'), isNull);
    expect(parseVnd('abc'), isNull);
    expect(formatDate(DateTime(2026, 9, 26)), '26/09/2026');
    expect(formatMonth(DateTime(2026, 9)), 'Tháng 9, 2026');
    expect(monthKey(DateTime(2026, 9)), '2026-09');
  });

  test('budget status changes at 80 and 100 percent', () {
    expect(budgetStatus(799, 1000), BudgetStatus.safe);
    expect(budgetStatus(800, 1000), BudgetStatus.warning);
    expect(budgetStatus(999, 1000), BudgetStatus.warning);
    expect(budgetStatus(1000, 1000), BudgetStatus.exceeded);
    expect(budgetStatus(1500, 1000), BudgetStatus.exceeded);
  });

  test('budget spending follows expense category and local month', () {
    final budget = FinanceBudget(
      id: '2026-09-food',
      categoryId: 'food',
      categoryName: 'Ăn uống',
      limitAmount: 3000000,
      month: '2026-09',
    );
    final transactions = [
      _transaction('a', 85000, 'food', 'expense', DateTime(2026, 9, 1)),
      _transaction('b', 200000, 'food', 'expense', DateTime(2026, 9, 30)),
      _transaction('c', 50000, 'food', 'expense', DateTime(2026, 10, 1)),
      _transaction('d', 500000, 'food', 'income', DateTime(2026, 9, 2)),
      _transaction('e', 30000, 'travel', 'expense', DateTime(2026, 9, 2)),
    ];
    expect(spentForBudget(transactions, budget), 285000);
  });

  test('transaction filters combine search, type and date', () {
    final transactions = [
      _transaction(
        'a',
        85000,
        'food',
        'expense',
        DateTime(2026, 9, 26),
        note: 'Bữa trưa',
      ),
      _transaction('b', 200000, 'food', 'expense', DateTime(2026, 8, 26)),
      _transaction('c', 85000, 'food', 'income', DateTime(2026, 9, 26)),
    ];
    final result = filterTransactions(
      transactions,
      TransactionFilter(
        search: 'trưa',
        type: 'expense',
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      ),
    );
    expect(result.map((item) => item.id), ['a']);
  });
}

FinanceTransaction _transaction(
  String id,
  int amount,
  String categoryId,
  String type,
  DateTime date, {
  String note = '',
}) => FinanceTransaction(
  id: id,
  amount: amount,
  categoryId: categoryId,
  categoryName: 'Ăn uống',
  categoryIcon: 'restaurant',
  categoryColor: '#FF796B',
  type: type,
  note: note,
  date: date,
);
