import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../app/app_theme.dart';
import '../auth/auth_service.dart';
import '../finance/finance_format.dart';
import '../finance/finance_models.dart';
import '../finance/finance_repository.dart';
import '../finance/finance_statistics.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/cache_status_banner.dart';
import '../widgets/finance_card.dart';
import '../widgets/section_title.dart';
import '../widgets/state_panel.dart';
import '../widgets/transaction_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    this.repository,
    this.now,
    this.clock,
    this.displayName,
    super.key,
  });
  final FinanceRepository? repository;
  final DateTime? now;
  final DateTime Function()? clock;
  final String? displayName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _dayTimer;
  DateTime get _currentTime =>
      widget.clock?.call() ?? widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _scheduleNextDay();
  }

  void _scheduleNextDay() {
    if (widget.now != null && widget.clock == null) return;
    final time = _currentTime;
    final midnight = DateTime(time.year, time.month, time.day + 1);
    _dayTimer = Timer(midnight.difference(time), () {
      if (!mounted) return;
      setState(() {});
      _scheduleNextDay();
    });
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    super.dispose();
  }

  late final FinanceRepository _repository =
      widget.repository ?? FinanceRepository();
  late Stream<FinanceTransactionSnapshot> _transactions = _repository
      .watchTransactionsWithSource();
  late Stream<List<FinanceBudget>> _budgets = _repository.watchBudgets();

  void _retry() => setState(() {
    _transactions = _repository.watchTransactionsWithSource();
    _budgets = _repository.watchBudgets();
  });

  Future<void> _addTransaction() async {
    final saved = await Navigator.pushNamed(context, AppRoutes.addTransaction);
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu giao dịch.')));
    }
  }

  Future<void> _openTransaction(String id) async {
    final deleted = await Navigator.pushNamed(
      context,
      AppRoutes.transactionDetail,
      arguments: id,
    );
    if (deleted == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã xóa giao dịch.')));
    }
  }

  void _goToTab(int index) {
    const routes = [
      AppRoutes.home,
      AppRoutes.transactions,
      AppRoutes.reports,
      AppRoutes.settings,
    ];
    if (index != 0) Navigator.pushReplacementNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.displayName ?? AuthService().currentUser?.displayName)
        ?.trim();
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<FinanceTransactionSnapshot>(
          stream: _transactions,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: StatePanel(type: StatePanelType.error, onAction: _retry),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data!.items;
            final now = _currentTime;
            final summary = summarizeHome(items, const [], now);
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
              children: [
                Column(
                  children: [
                    if (snapshot.data!.isFromCache) ...[
                      const CacheStatusBanner(),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
                Text(
                  formatDate(now),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  name == null || name.isEmpty
                      ? 'Xin chào!'
                      : 'Xin chào, $name',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Cùng theo dõi hành trình tài chính của bạn.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                FinanceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số dư hiện tại',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatVnd(summary.balance),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _BalanceStat(
                              label: 'Thu nhập tháng này',
                              amount: summary.monthIncome,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context).colorScheme.primary
                                  : AppColors.mintDark,
                            ),
                          ),
                          Expanded(
                            child: _BalanceStat(
                              label: 'Chi tiêu tháng này',
                              amount: summary.monthExpense,
                              color: AppColors.coral,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SectionTitle(
                  title: 'Ngân sách tháng này',
                  actionLabel: 'Xem tất cả',
                  onAction: () =>
                      Navigator.pushNamed(context, AppRoutes.budgets),
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<FinanceBudget>>(
                  stream: _budgets,
                  builder: (context, budgetSnapshot) {
                    if (budgetSnapshot.hasError) {
                      return TextButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Không thể tải ngân sách. Thử lại'),
                      );
                    }
                    if (!budgetSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final current = budgetSnapshot.data!
                        .where((item) => item.month == monthKey(now))
                        .toList();
                    if (current.isEmpty) {
                      return FinanceCard(
                        child: TextButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.budgets),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            'Chưa có ngân sách. Tạo ngân sách tháng này',
                          ),
                        ),
                      );
                    }
                    final budgetSummary = summarizeHome(items, current, now);
                    final limit = budgetSummary.budgetLimit;
                    final spent = budgetSummary.budgetSpent;
                    return FinanceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${formatVnd(spent)} / ${formatVnd(limit)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 8),
                          Text(
                            '${(spent * 100 / limit).round()}% ngân sách đã dùng',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            spent > limit
                                ? 'Đã vượt ${formatVnd(spent - limit)}'
                                : spent == limit
                                ? 'Đã dùng hết ngân sách'
                                : 'Còn ${formatVnd(limit - spent)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 26),
                SectionTitle(
                  title: 'Giao dịch gần đây',
                  actionLabel: 'Xem tất cả',
                  onAction: () =>
                      Navigator.pushNamed(context, AppRoutes.transactions),
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: TextButton.icon(
                      onPressed: _addTransaction,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Chưa có giao dịch. Hãy thêm giao dịch đầu tiên.',
                      ),
                    ),
                  ),
                ...items
                    .take(5)
                    .map(
                      (item) => TransactionTile(
                        transaction: item,
                        onTap: () => _openTransaction(item.id),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomNav(currentIndex: 0, onSelected: _goToTab),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({
    required this.label,
    required this.amount,
    required this.color,
  });
  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          formatVnd(amount),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
        ),
      ),
    ],
  );
}
