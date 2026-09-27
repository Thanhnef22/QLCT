import 'finance_format.dart';
import 'finance_models.dart';

enum BudgetStatus { safe, warning, exceeded }

BudgetStatus budgetStatus(int spent, int limit) {
  if (limit <= 0) throw ArgumentError.value(limit, 'limit');
  if (spent >= limit) return BudgetStatus.exceeded;
  if (spent * 100 >= limit * 80) return BudgetStatus.warning;
  return BudgetStatus.safe;
}

int spentForBudget(
  List<FinanceTransaction> transactions,
  FinanceBudget budget,
) => transactions
    .where(
      (item) =>
          item.type == 'expense' &&
          item.categoryId == budget.categoryId &&
          monthKey(item.date) == budget.month,
    )
    .fold(0, (sum, item) => sum + item.amount);

class TransactionFilter {
  const TransactionFilter({
    this.search = '',
    this.type,
    this.categoryId,
    this.from,
    this.to,
    this.minAmount,
    this.maxAmount,
  });

  final String search;
  final String? type;
  final String? categoryId;
  final DateTime? from;
  final DateTime? to;
  final int? minAmount;
  final int? maxAmount;
}

List<FinanceTransaction> filterTransactions(
  List<FinanceTransaction> transactions,
  TransactionFilter filter,
) {
  final query = filter.search.trim().toLowerCase();
  final from = filter.from == null
      ? null
      : DateTime(filter.from!.year, filter.from!.month, filter.from!.day);
  final toExclusive = filter.to == null
      ? null
      : DateTime(filter.to!.year, filter.to!.month, filter.to!.day + 1);
  return transactions.where((item) {
    if (filter.type != null && item.type != filter.type) return false;
    if (filter.categoryId != null && item.categoryId != filter.categoryId) {
      return false;
    }
    if (from != null && item.date.isBefore(from)) return false;
    if (toExclusive != null && !item.date.isBefore(toExclusive)) return false;
    if (filter.minAmount != null && item.amount < filter.minAmount!) {
      return false;
    }
    if (filter.maxAmount != null && item.amount > filter.maxAmount!) {
      return false;
    }
    return query.isEmpty ||
        item.note.toLowerCase().contains(query) ||
        item.categoryName.toLowerCase().contains(query) ||
        item.amount.toString().contains(query.replaceAll('.', ''));
  }).toList();
}
