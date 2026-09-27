import 'finance_format.dart';
import 'finance_models.dart';
import 'finance_rules.dart';

enum ReportPeriod { week, month, year }

class DateRange {
  const DateRange(this.start, this.endExclusive);

  final DateTime start;
  final DateTime endExclusive;

  bool contains(DateTime date) =>
      !date.isBefore(start) && date.isBefore(endExclusive);
}

DateRange reportRange(ReportPeriod period, DateTime now) => switch (period) {
  ReportPeriod.week => DateRange(
    DateTime(now.year, now.month, now.day - now.weekday + 1),
    DateTime(now.year, now.month, now.day - now.weekday + 8),
  ),
  ReportPeriod.month => DateRange(
    DateTime(now.year, now.month),
    DateTime(now.year, now.month + 1),
  ),
  ReportPeriod.year => DateRange(DateTime(now.year), DateTime(now.year + 1)),
};

class HomeSummary {
  const HomeSummary({
    required this.balance,
    required this.monthIncome,
    required this.monthExpense,
    required this.budgetLimit,
    required this.budgetSpent,
    required this.recent,
  });

  final int balance;
  final int monthIncome;
  final int monthExpense;
  final int budgetLimit;
  final int budgetSpent;
  final List<FinanceTransaction> recent;
}

HomeSummary summarizeHome(
  List<FinanceTransaction> transactions,
  List<FinanceBudget> budgets,
  DateTime now,
) {
  final month = reportRange(ReportPeriod.month, now);
  var balance = 0;
  var monthIncome = 0;
  var monthExpense = 0;
  for (final item in transactions) {
    if (item.type == 'income') {
      balance += item.amount;
      if (month.contains(item.date)) monthIncome += item.amount;
    } else if (item.type == 'expense') {
      balance -= item.amount;
      if (month.contains(item.date)) monthExpense += item.amount;
    }
  }

  var budgetLimit = 0;
  var budgetSpent = 0;
  for (final budget in budgets) {
    if (budget.month != monthKey(now)) continue;
    budgetLimit += budget.limitAmount;
    budgetSpent += spentForBudget(transactions, budget);
  }
  return HomeSummary(
    balance: balance,
    monthIncome: monthIncome,
    monthExpense: monthExpense,
    budgetLimit: budgetLimit,
    budgetSpent: budgetSpent,
    recent: transactions.take(5).toList(),
  );
}

class CategoryExpense {
  const CategoryExpense({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.amount,
  });

  final String categoryId;
  final String name;
  final String color;
  final int amount;
}

class TrendPoint {
  const TrendPoint(this.start, this.expense);

  final DateTime start;
  final int expense;
}

class ReportSummary {
  const ReportSummary({
    required this.income,
    required this.expense,
    required this.categories,
    required this.trend,
  });

  final int income;
  final int expense;
  int get savings => income - expense;
  final List<CategoryExpense> categories;
  final List<TrendPoint> trend;
}

ReportSummary summarizeReport(
  List<FinanceTransaction> transactions,
  ReportPeriod period,
  DateTime now,
) {
  final range = reportRange(period, now);
  final buckets = <DateTime>[];
  if (period == ReportPeriod.year) {
    for (var month = 1; month <= 12; month++) {
      buckets.add(DateTime(now.year, month));
    }
  } else {
    for (
      var day = range.start;
      day.isBefore(range.endExclusive);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      buckets.add(day);
    }
  }
  final totals = {for (final day in buckets) day: 0};
  final categories = <String, CategoryExpense>{};
  var income = 0;
  var expense = 0;
  for (final item in transactions) {
    if (!range.contains(item.date)) continue;
    if (item.type == 'income') {
      income += item.amount;
    } else if (item.type == 'expense') {
      expense += item.amount;
      final previous = categories[item.categoryId];
      categories[item.categoryId] = CategoryExpense(
        categoryId: item.categoryId,
        name: previous?.name ?? item.categoryName,
        color: previous?.color ?? item.categoryColor,
        amount: (previous?.amount ?? 0) + item.amount,
      );
      final start = period == ReportPeriod.year
          ? DateTime(item.date.year, item.date.month)
          : DateTime(item.date.year, item.date.month, item.date.day);
      totals[start] = (totals[start] ?? 0) + item.amount;
    }
  }
  final grouped = categories.values.toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  return ReportSummary(
    income: income,
    expense: expense,
    categories: grouped,
    trend: [for (final day in buckets) TrendPoint(day, totals[day]!)],
  );
}

class MonthComparison {
  const MonthComparison({
    required this.currentExpense,
    required this.previousExpense,
    required this.changePercent,
  });

  final int currentExpense;
  final int previousExpense;
  final double? changePercent;
}

MonthComparison compareCurrentMonth(
  List<FinanceTransaction> transactions,
  DateTime now,
) {
  final current = reportRange(ReportPeriod.month, now);
  final previous = reportRange(
    ReportPeriod.month,
    DateTime(now.year, now.month - 1),
  );
  var currentExpense = 0;
  var previousExpense = 0;
  for (final item in transactions) {
    if (item.type != 'expense') continue;
    if (current.contains(item.date)) currentExpense += item.amount;
    if (previous.contains(item.date)) previousExpense += item.amount;
  }
  return MonthComparison(
    currentExpense: currentExpense,
    previousExpense: previousExpense,
    changePercent: previousExpense == 0
        ? null
        : ((currentExpense - previousExpense) * 1000 / previousExpense)
                  .round() /
              10,
  );
}
