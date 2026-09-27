import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/finance/finance_models.dart';
import 'package:flutter_qlct/finance/finance_statistics.dart';

FinanceTransaction entry(
  String id,
  int amount,
  String type,
  DateTime date, {
  String categoryId = 'food',
  String categoryName = 'Ăn uống',
}) => FinanceTransaction(
  id: id,
  amount: amount,
  categoryId: categoryId,
  categoryName: categoryName,
  categoryIcon: 'restaurant',
  categoryColor: '#FF796B',
  type: type,
  note: '',
  date: date,
);

void main() {
  test('week range starts Monday and excludes next Monday', () {
    final transactions = [
      entry('sun', 20, 'expense', DateTime(2026, 9, 27, 23, 59)),
      entry('mon', 50, 'expense', DateTime(2026, 9, 28)),
    ];
    final range = reportRange(ReportPeriod.week, DateTime(2026, 9, 27));
    expect(range.start, DateTime(2026, 9, 21));
    expect(range.endExclusive, DateTime(2026, 9, 28));
    expect(
      summarizeReport(
        transactions,
        ReportPeriod.week,
        DateTime(2026, 9, 27),
      ).expense,
      20,
    );
  });

  test('month and year ranges cross December to January', () {
    expect(
      reportRange(ReportPeriod.month, DateTime(2026, 12, 31)).endExclusive,
      DateTime(2027, 1),
    );
    expect(
      reportRange(ReportPeriod.year, DateTime(2026, 12, 31)).endExclusive,
      DateTime(2027),
    );
  });

  test(
    'home separates all-time balance from current month and keeps five recent',
    () {
      final transactions = [
        entry('a', 200, 'expense', DateTime(2026, 9, 30)),
        entry('b', 1000, 'income', DateTime(2026, 9, 29)),
        entry('c', 150, 'expense', DateTime(2026, 9, 28)),
        entry('d', 100, 'expense', DateTime(2026, 9, 27)),
        entry('e', 50, 'expense', DateTime(2026, 9, 26)),
        entry('f', 30, 'expense', DateTime(2026, 9, 25)),
        entry('old', 500, 'income', DateTime(2026, 8, 31)),
      ];
      final summary = summarizeHome(transactions, [], DateTime(2026, 9, 30));
      expect(summary.balance, 970);
      expect(summary.monthIncome, 1000);
      expect(summary.monthExpense, 530);
      expect(summary.recent.map((item) => item.id), ['a', 'b', 'c', 'd', 'e']);
    },
  );

  test('home budget uses matching expense, category and month only', () {
    final transactions = [
      entry('a', 850, 'expense', DateTime(2026, 9, 1)),
      entry('b', 90, 'income', DateTime(2026, 9, 2)),
      entry('c', 30, 'expense', DateTime(2026, 10, 1)),
      entry('d', 200, 'expense', DateTime(2026, 9, 2), categoryId: 'travel'),
    ];
    const budgets = [
      FinanceBudget(
        id: 'b',
        categoryId: 'food',
        categoryName: 'Ăn uống',
        limitAmount: 1000,
        month: '2026-09',
      ),
      FinanceBudget(
        id: 'old',
        categoryId: 'food',
        categoryName: 'Ăn uống',
        limitAmount: 2000,
        month: '2026-08',
      ),
    ];
    final summary = summarizeHome(transactions, budgets, DateTime(2026, 9, 27));
    expect(summary.budgetLimit, 1000);
    expect(summary.budgetSpent, 850);
    expect(summarizeHome([], [], DateTime(2026, 9)).budgetLimit, 0);
  });

  test(
    'report groups by category id and fills missing trend days with zero',
    () {
      final transactions = [
        entry(
          'a',
          20,
          'expense',
          DateTime(2026, 9, 21),
          categoryName: 'Ăn uống mới',
        ),
        entry(
          'b',
          30,
          'expense',
          DateTime(2026, 9, 23),
          categoryName: 'Ăn uống cũ',
        ),
      ];
      final summary = summarizeReport(
        transactions,
        ReportPeriod.week,
        DateTime(2026, 9, 23),
      );
      expect(summary.categories, hasLength(1));
      expect(summary.categories.single.amount, 50);
      expect(summary.categories.single.name, 'Ăn uống mới');
      expect(summary.trend, hasLength(7));
      expect(summary.trend[1].expense, 0);
      expect(summary.trend[2].expense, 30);
      expect(
        summarizeReport(
          transactions,
          ReportPeriod.year,
          DateTime(2026, 9, 23),
        ).trend,
        hasLength(12),
      );
    },
  );

  test('income-only and empty reports have no expense categories', () {
    final onlyIncome = summarizeReport(
      [entry('income', 100, 'income', DateTime(2026, 9, 1))],
      ReportPeriod.month,
      DateTime(2026, 9, 27),
    );
    expect(
      (onlyIncome.income, onlyIncome.expense, onlyIncome.savings),
      (100, 0, 100),
    );
    expect(onlyIncome.categories, isEmpty);
    final empty = summarizeReport(
      [],
      ReportPeriod.month,
      DateTime(2026, 9, 27),
    );
    expect((empty.income, empty.expense, empty.savings), (0, 0, 0));
    final negative = summarizeReport(
      [entry('expense', 120, 'expense', DateTime(2026, 9, 1))],
      ReportPeriod.month,
      DateTime(2026, 9, 27),
    );
    expect(negative.savings, -120);
  });

  test('month comparison handles zero previous expense and year turn', () {
    final noPrevious = compareCurrentMonth([
      entry('current', 200, 'expense', DateTime(2027, 1, 2)),
    ], DateTime(2027, 1, 10));
    expect(noPrevious.changePercent, isNull);
    expect(noPrevious.currentExpense, 200);
    final comparison = compareCurrentMonth([
      entry('current', 200, 'expense', DateTime(2027, 1, 2)),
      entry('previous', 160, 'expense', DateTime(2026, 12, 31)),
    ], DateTime(2027, 1, 10));
    expect(comparison.previousExpense, 160);
    expect(comparison.changePercent, 25.0);
    expect(compareCurrentMonth([], DateTime(2027, 1)).changePercent, isNull);
  });
}
