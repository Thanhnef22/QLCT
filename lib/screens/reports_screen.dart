import 'package:flutter/material.dart';
import '../app/app_routes.dart';
import '../app/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/finance_card.dart';
import '../widgets/section_title.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  void _goToTab(BuildContext context, int index) {
    final routes = [
      AppRoutes.home,
      AppRoutes.transactions,
      AppRoutes.reports,
      AppRoutes.settings
    ];
    if (index != 2) Navigator.pushReplacementNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo tài chính'), actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.ios_share_rounded))
      ]),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            SegmentedButton<String>(segments: const [
              ButtonSegment(value: 'Tuần', label: Text('Tuần')),
              ButtonSegment(value: 'Tháng', label: Text('Tháng')),
              ButtonSegment(value: 'Năm', label: Text('Năm'))
            ], selected: const {
              'Tháng'
            }, onSelectionChanged: (_) {}),
            const SizedBox(height: 24),
            FinanceCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Tổng chi tiêu tháng 9',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.mutedInk)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text('5.920.000 ₫',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(width: 10),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                            color: AppColors.mintSoft,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('- 12,5%',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.mintDark)))
                  ]),
                  const SizedBox(height: 24),
                  const _WeeklyBars()
                ])),
            const SizedBox(height: 28),
            SectionTitle(title: 'Phân bổ chi tiêu'),
            const SizedBox(height: 12),
            FinanceCard(
                child: Column(children: const [
              _CategoryRow(
                  color: AppColors.coral,
                  label: 'Ăn uống',
                  amount: '1.850.000 ₫',
                  percent: '31%'),
              _CategoryRow(
                  color: Color(0xFF8B7CFF),
                  label: 'Mua sắm',
                  amount: '1.420.000 ₫',
                  percent: '24%'),
              _CategoryRow(
                  color: AppColors.amber,
                  label: 'Di chuyển',
                  amount: '780.000 ₫',
                  percent: '13%'),
              _CategoryRow(
                  color: AppColors.mint,
                  label: 'Khác',
                  amount: '1.870.000 ₫',
                  percent: '32%')
            ])),
          ]),
      bottomNavigationBar: AppBottomNav(
          currentIndex: 2, onSelected: (index) => _goToTab(context, index)),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars();

  @override
  Widget build(BuildContext context) {
    const values = [0.38, 0.58, 0.42, 0.78, 0.60, 0.30, 0.50];
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return SizedBox(
        height: 150,
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
                values.length,
                (index) =>
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Container(
                          width: 22,
                          height: 110 * values[index],
                          decoration: BoxDecoration(
                              color: index == 3
                                  ? AppColors.mint
                                  : AppColors.mintSoft,
                              borderRadius: BorderRadius.circular(8))),
                      const SizedBox(height: 8),
                      Text(labels[index],
                          style: Theme.of(context).textTheme.labelSmall)
                    ]))));
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow(
      {required this.color,
      required this.label,
      required this.amount,
      required this.percent});

  final Color color;
  final String label;
  final String amount;
  final String percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
              child:
                  Text(label, style: Theme.of(context).textTheme.labelLarge)),
          Text(amount, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 12),
          SizedBox(
              width: 32,
              child: Text(percent,
                  textAlign: TextAlign.right,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: AppColors.mutedInk)))
        ]));
  }
}
