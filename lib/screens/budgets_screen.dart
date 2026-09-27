import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_theme.dart';
import '../finance/finance_format.dart';
import '../finance/finance_models.dart';
import '../finance/finance_repository.dart';
import '../finance/finance_rules.dart';
import '../widgets/finance_card.dart';
import '../widgets/state_panel.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({this.repository, this.initialMonth, super.key});
  final FinanceRepository? repository;
  final DateTime? initialMonth;

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late final FinanceRepository _repository =
      widget.repository ?? FinanceRepository();
  late Stream<List<FinanceBudget>> _budgets = _repository.watchBudgets();
  late Stream<List<FinanceTransaction>> _transactions = _repository
      .watchTransactions();
  late final Stream<List<FinanceCategory>> _categories = _repository
      .watchCategories();
  late DateTime _month = DateTime(
    (widget.initialMonth ?? DateTime.now()).year,
    (widget.initialMonth ?? DateTime.now()).month,
  );

  void _retry() => setState(() {
    _budgets = _repository.watchBudgets();
    _transactions = _repository.watchTransactions();
  });

  void _changeMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  Future<void> _showForm([FinanceBudget? budget]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _BudgetDialog(
        repository: _repository,
        categories: _categories,
        month: monthKey(_month),
        budget: budget,
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu ngân sách.')));
    }
  }

  Future<void> _delete(FinanceBudget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ngân sách?'),
        content: Text(
          'Xóa ngân sách “${budget.categoryName}” trong ${formatMonth(_month)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deleteBudget(budget.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã xóa ngân sách.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(financeErrorMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ngân sách')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Tháng trước',
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                formatMonth(_month),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                tooltip: 'Tháng sau',
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<FinanceBudget>>(
            stream: _budgets,
            builder: (context, budgetSnapshot) {
              if (budgetSnapshot.hasError) {
                return Center(
                  child: StatePanel(
                    type: StatePanelType.error,
                    onAction: _retry,
                  ),
                );
              }
              if (!budgetSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return StreamBuilder<List<FinanceTransaction>>(
                stream: _transactions,
                builder: (context, transactionSnapshot) {
                  if (transactionSnapshot.hasError) {
                    return Center(
                      child: StatePanel(
                        type: StatePanelType.error,
                        onAction: _retry,
                      ),
                    );
                  }
                  if (!transactionSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final budgets = budgetSnapshot.data!
                      .where((item) => item.month == monthKey(_month))
                      .toList();
                  final transactions = transactionSnapshot.data!;
                  if (budgets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 52,
                            color: AppColors.mutedInk,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có ngân sách',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Tạo ngân sách cho ${formatMonth(_month)}.'),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _showForm,
                            icon: const Icon(Icons.add),
                            label: const Text('Tạo ngân sách'),
                          ),
                        ],
                      ),
                    );
                  }
                  final spent = budgets.fold<int>(
                    0,
                    (sum, budget) => sum + spentForBudget(transactions, budget),
                  );
                  final limit = budgets.fold<int>(
                    0,
                    (sum, budget) => sum + budget.limitAmount,
                  );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                    children: [
                      FinanceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tổng ngân sách ${formatMonth(_month)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatVnd(limit),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đã dùng ${formatVnd(spent)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (spent / limit).clamp(0.0, 1.0),
                                minHeight: 9,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                color: spent >= limit
                                    ? AppColors.coral
                                    : AppColors.mint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Theo danh mục',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<FinanceCategory>>(
                        stream: _categories,
                        builder: (context, categorySnapshot) {
                          final names = {
                            for (final category
                                in categorySnapshot.data ?? <FinanceCategory>[])
                              category.id: category.name,
                          };
                          return Column(
                            children: budgets
                                .map(
                                  (budget) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _BudgetCard(
                                      budget: budget,
                                      categoryName:
                                          names[budget.categoryId] ??
                                          budget.categoryName,
                                      spent: spentForBudget(
                                        transactions,
                                        budget,
                                      ),
                                      onEdit: () => _showForm(budget),
                                      onDelete: () => _delete(budget),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _showForm,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Tạo ngân sách'),
    ),
  );
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.categoryName,
    required this.spent,
    required this.onEdit,
    required this.onDelete,
  });
  final FinanceBudget budget;
  final String categoryName;
  final int spent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = budgetStatus(spent, budget.limitAmount);
    final color = switch (status) {
      BudgetStatus.safe => AppColors.mintDark,
      BudgetStatus.warning => AppColors.amber,
      BudgetStatus.exceeded => AppColors.coral,
    };
    final label = switch (status) {
      BudgetStatus.safe => 'An toàn',
      BudgetStatus.warning => 'Sắp vượt',
      BudgetStatus.exceeded => 'Đã vượt',
    };
    final percent = spent * 100 ~/ budget.limitAmount;
    return FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  categoryName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Tùy chọn ngân sách',
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                  PopupMenuItem(value: 'delete', child: Text('Xóa')),
                ],
              ),
            ],
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: color),
          ),
          const SizedBox(height: 10),
          Text(
            'Đã dùng ${formatVnd(spent)} / ${formatVnd(budget.limitAmount)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (spent / budget.limitAmount).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: color.withAlpha(30),
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  spent > budget.limitAmount
                      ? 'Đã vượt ${formatVnd(spent - budget.limitAmount)}'
                      : 'Còn ${formatVnd(budget.limitAmount - spent)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({
    required this.repository,
    required this.categories,
    required this.month,
    this.budget,
  });
  final FinanceRepository repository;
  final Stream<List<FinanceCategory>> categories;
  final String month;
  final FinanceBudget? budget;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  final _form = GlobalKey<FormState>();
  late Stream<List<FinanceCategory>> _categories = widget.categories;
  late final _amount = TextEditingController(
    text: widget.budget?.limitAmount.toString() ?? '',
  );
  late String? _categoryId = widget.budget?.categoryId;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _busy || _categoryId == null) return;
    setState(() => _busy = true);
    try {
      await widget.repository.saveBudget(
        id: widget.budget?.id,
        categoryId: _categoryId!,
        month: widget.month,
        limitAmount: parseVnd(_amount.text)!,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(financeErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.budget == null ? 'Tạo ngân sách' : 'Sửa ngân sách'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tháng ${widget.month.substring(5)}/${widget.month.substring(0, 4)}',
          ),
          const SizedBox(height: 14),
          StreamBuilder<List<FinanceCategory>>(
            stream: _categories,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return TextButton(
                  onPressed: () => setState(() {
                    _categories = widget.repository.watchCategories();
                  }),
                  child: const Text('Không thể tải danh mục. Thử lại'),
                );
              }
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final items = snapshot.data!
                  .where((item) => item.type == 'expense')
                  .toList();
              return DropdownButtonFormField<String>(
                initialValue: items.any((item) => item.id == _categoryId)
                    ? _categoryId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Danh mục chi tiêu',
                ),
                items: items
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: widget.budget != null || _busy
                    ? null
                    : (value) => setState(() => _categoryId = value),
                validator: (value) =>
                    value == null ? 'Vui lòng chọn danh mục.' : null,
              );
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Hạn mức',
              suffixText: '₫',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Vui lòng nhập hạn mức.'
                : parseVnd(value) == null
                ? 'Hạn mức phải lớn hơn 0.'
                : null,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: _busy ? null : _save,
        child: Text(_busy ? 'Đang lưu...' : 'Lưu'),
      ),
    ],
  );
}
