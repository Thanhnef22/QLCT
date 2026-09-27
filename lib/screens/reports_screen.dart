import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../finance/finance_format.dart';
import '../finance/finance_repository.dart';
import '../finance/finance_statistics.dart';
import '../finance/finance_visuals.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/cache_status_banner.dart';
import '../widgets/finance_card.dart';
import '../widgets/report_charts.dart';
import '../widgets/section_title.dart';
import '../widgets/state_panel.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({this.repository, this.now, this.clock, super.key});

  final FinanceRepository? repository;
  final DateTime? now;
  final DateTime Function()? clock;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
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
  ReportPeriod _period = ReportPeriod.month;

  void _retry() =>
      setState(() => _transactions = _repository.watchTransactionsWithSource());

  void _goToTab(int index) {
    const routes = [
      AppRoutes.home,
      AppRoutes.transactions,
      AppRoutes.reports,
      AppRoutes.settings,
    ];
    if (index != 2) Navigator.pushReplacementNamed(context, routes[index]);
  }

  void _export() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Tính năng xuất báo cáo sẽ được hoàn thiện sau.'),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Báo cáo tài chính')),
    body: StreamBuilder<FinanceTransactionSnapshot>(
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
        final transactions = snapshot.data!.items;
        final now = _currentTime;
        final report = summarizeReport(transactions, _period, now);
        final comparison = compareCurrentMonth(transactions, now);
        final range = reportRange(_period, now);
        final colors = Theme.of(context).colorScheme;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (snapshot.data!.isFromCache) ...[
              const CacheStatusBanner(),
              const SizedBox(height: 16),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _export,
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: const Text('Xuất báo cáo'),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ReportPeriod>(
              segments: const [
                ButtonSegment(value: ReportPeriod.week, label: Text('Tuần')),
                ButtonSegment(value: ReportPeriod.month, label: Text('Tháng')),
                ButtonSegment(value: ReportPeriod.year, label: Text('Năm')),
              ],
              selected: {_period},
              onSelectionChanged: (selection) =>
                  setState(() => _period = selection.first),
            ),
            const SizedBox(height: 12),
            Text(
              '${formatDate(range.start)} – ${formatDate(DateTime(range.endExclusive.year, range.endExclusive.month, range.endExclusive.day - 1))}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FinanceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng chi tiêu',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatVnd(report.expense),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: colors.outlineVariant),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ReportStat(
                          label: 'Thu nhập',
                          amount: report.income,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReportStat(
                          label: 'Tiết kiệm',
                          amount: report.savings,
                          color: report.savings < 0
                              ? colors.error
                              : colors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            if (report.income == 0 && report.expense == 0)
              const FinanceCard(child: Text('Chưa đủ dữ liệu để tạo báo cáo'))
            else if (report.expense == 0)
              const FinanceCard(
                child: Text('Chưa có chi tiêu trong khoảng này để vẽ biểu đồ.'),
              )
            else ...[
              const SectionTitle(title: 'Phân bổ chi tiêu'),
              const SizedBox(height: 12),
              FinanceCard(
                child: Column(
                  children: [
                    ReportDonutChart(
                      categories: report.categories,
                      total: report.expense,
                    ),
                    const SizedBox(height: 18),
                    for (final category in report.categories)
                      _CategoryRow(category: category, total: report.expense),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const SectionTitle(title: 'Xu hướng chi tiêu'),
              const SizedBox(height: 12),
              FinanceCard(
                child: Column(
                  children: [
                    ReportTrendChart(points: report.trend),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_trendLabel(report.trend.first.start, _period)),
                        Text(_trendLabel(report.trend.last.start, _period)),
                      ],
                    ),
                    ExpansionTile(
                      title: const Text('Chi tiết xu hướng'),
                      tilePadding: EdgeInsets.zero,
                      children: [
                        for (final point in report.trend)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${_trendLabel(point.start, _period)} • ${formatVnd(point.expense)}',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 26),
            const SectionTitle(title: 'So sánh với tháng trước'),
            const SizedBox(height: 12),
            FinanceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _comparisonLabel(comparison),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _ComparisonBar(
                    label: 'Tháng này',
                    amount: comparison.currentExpense,
                    maximum: _barMaximum(comparison),
                  ),
                  const SizedBox(height: 14),
                  _ComparisonBar(
                    label: 'Tháng trước',
                    amount: comparison.previousExpense,
                    maximum: _barMaximum(comparison),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const SectionTitle(title: 'Thu nhập và chi tiêu'),
            const SizedBox(height: 12),
            FinanceCard(
              child: Column(
                children: [
                  _ComparisonBar(
                    label: 'Thu nhập',
                    amount: report.income,
                    maximum: _max(report.income, report.expense),
                  ),
                  const SizedBox(height: 14),
                  _ComparisonBar(
                    label: 'Chi tiêu',
                    amount: report.expense,
                    maximum: _max(report.income, report.expense),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
    bottomNavigationBar: AppBottomNav(currentIndex: 2, onSelected: _goToTab),
  );
}

String _trendLabel(DateTime date, ReportPeriod period) =>
    period == ReportPeriod.year
    ? 'Tháng ${date.month}'
    : '${date.day}/${date.month}';

int _max(int a, int b) => a > b ? a : b;

int _barMaximum(MonthComparison comparison) =>
    _max(comparison.currentExpense, comparison.previousExpense);

String _comparisonLabel(MonthComparison comparison) {
  if (comparison.previousExpense == 0) {
    return comparison.currentExpense == 0
        ? 'Chưa có chi tiêu trong hai tháng'
        : 'Chưa có dữ liệu tháng trước để so sánh';
  }
  final change = comparison.changePercent!;
  if (comparison.currentExpense == comparison.previousExpense) {
    return 'Chi tiêu không đổi so với tháng trước';
  }
  if (change.abs() < 0.05) {
    return '${comparison.currentExpense > comparison.previousExpense ? 'Tăng' : 'Giảm'} dưới 0,1% so với tháng trước';
  }
  final amount = change.abs().toStringAsFixed(1).replaceAll('.', ',');
  return '${change > 0 ? 'Tăng' : 'Giảm'} $amount% so với tháng trước';
}

class _ReportStat extends StatelessWidget {
  const _ReportStat({
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.total});

  final CategoryExpense category;
  final int total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        CircleAvatar(radius: 5, backgroundColor: financeColor(category.color)),
        const SizedBox(width: 10),
        Expanded(child: Text(category.name, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            formatVnd(category.amount),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text('${(category.amount * 100 / total).round()}%'),
      ],
    ),
  );
}

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.label,
    required this.amount,
    required this.maximum,
  });

  final String label;
  final int amount;
  final int maximum;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            formatVnd(amount),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: maximum == 0 ? 0 : amount / maximum,
          minHeight: 8,
          backgroundColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
          color: label == 'Chi tiêu' || label == 'Tháng này'
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
        ),
      ),
    ],
  );
}
