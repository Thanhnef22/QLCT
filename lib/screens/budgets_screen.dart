import 'package:flutter/material.dart';
import '../app/app_routes.dart';
import '../app/app_theme.dart';
import '../data/demo_data.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/finance_card.dart';
import '../widgets/section_title.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  void _goToTab(BuildContext context, int index) {
    final routes = [
      AppRoutes.home,
      AppRoutes.transactions,
      AppRoutes.reports,
      AppRoutes.settings
    ];
    if (index != 0) Navigator.pushReplacementNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ngân sách & Cảnh báo'), actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.add_rounded))
      ]),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            FinanceCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Ngân sách tháng 9',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.mutedInk)),
                  const SizedBox(height: 10),
                  Text('5.920.000 ₫',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('đã sử dụng trong 9.500.000 ₫',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const LinearProgressIndicator(
                          value: .62,
                          minHeight: 10,
                          backgroundColor: AppColors.mintSoft,
                          valueColor: AlwaysStoppedAnimation(AppColors.mint)))
                ])),
            const SizedBox(height: 28),
            SectionTitle(
                title: 'Danh mục ngân sách',
                actionLabel: 'Chỉnh sửa',
                onAction: () {}),
            const SizedBox(height: 10),
            ...budgetItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BudgetItem(item: item))),
            const SizedBox(height: 18),
            SectionTitle(title: 'Cảnh báo sắp tới'),
            const SizedBox(height: 12),
            FinanceCard(
                child: Row(children: [
              Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: AppColors.coralSoft,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: AppColors.coral)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Ăn uống đang tăng nhanh',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Bạn đã dùng 62% ngân sách chỉ sau nửa tháng.',
                        style: Theme.of(context).textTheme.bodySmall)
                  ]))
            ])),
          ]),
      bottomNavigationBar: AppBottomNav(
          currentIndex: 0, onSelected: (index) => _goToTab(context, index)),
    );
  }
}

class _BudgetItem extends StatelessWidget {
  const _BudgetItem({required this.item});

  final Map<String, Object> item;

  @override
  Widget build(BuildContext context) {
    final color = Color(item['color']! as int);
    final progress = item['progress']! as double;
    return FinanceCard(
        child: Column(children: [
      Row(children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(item['name']! as String,
                style: Theme.of(context).textTheme.titleMedium)),
        Text('${(progress * 100).round()}%',
            style:
                Theme.of(context).textTheme.labelLarge?.copyWith(color: color))
      ]),
      const SizedBox(height: 14),
      ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withAlpha(35),
              valueColor: AlwaysStoppedAnimation(color))),
      const SizedBox(height: 10),
      Row(children: [
        Text(item['spent']! as String,
            style: Theme.of(context).textTheme.labelLarge),
        const Spacer(),
        Text('trên ${item['limit']!}',
            style: Theme.of(context).textTheme.bodySmall)
      ])
    ]));
  }
}
