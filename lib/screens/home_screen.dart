import 'package:flutter/material.dart';
import '../app/app_routes.dart';
import '../app/app_theme.dart';
import '../data/demo_data.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/finance_card.dart';
import '../widgets/section_title.dart';
import '../widgets/transaction_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _OfflineBanner(textTheme: textTheme)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: SliverList(
                  delegate: SliverChildListDelegate([
                Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Thứ tư, 16 tháng 9', style: textTheme.bodySmall),
                        const SizedBox(height: 5),
                        Text('Xin chào, Minh Anh',
                            style: textTheme.headlineMedium)
                      ])),
                  CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.mintSoft,
                      child: Text('MA',
                          style: textTheme.labelLarge
                              ?.copyWith(color: AppColors.mintDark))),
                ]),
                const SizedBox(height: 24),
                FinanceCard(child: _BalanceCard(textTheme: textTheme)),
                const SizedBox(height: 28),
                SectionTitle(
                    title: 'Ngân sách tháng này',
                    actionLabel: 'Xem tất cả',
                    onAction: () =>
                        Navigator.pushNamed(context, AppRoutes.budgets)),
                const SizedBox(height: 12),
                FinanceCard(child: _BudgetCard(textTheme: textTheme)),
                const SizedBox(height: 28),
                SectionTitle(
                    title: 'Giao dịch gần đây',
                    actionLabel: 'Xem tất cả',
                    onAction: () =>
                        Navigator.pushNamed(context, AppRoutes.transactions)),
                const SizedBox(height: 8),
                ...demoTransactions.take(3).map((item) => TransactionTile(
                    transaction: item,
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.transactionDetail,
                        arguments: item.title))),
              ])),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addTransaction),
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomNav(
          currentIndex: 0, onSelected: (index) => _goToTab(context, index)),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: AppColors.ink,
      child: Row(children: [
        const Icon(Icons.cloud_off_rounded, size: 14, color: Colors.white70),
        const SizedBox(width: 8),
        Text('Bạn đang xem dữ liệu mẫu ngoại tuyến',
            style: textTheme.labelSmall?.copyWith(color: Colors.white70))
      ]),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text('Số dư hiện tại',
                style:
                    textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk))),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.mintSoft,
                borderRadius: BorderRadius.circular(20)),
            child: Text('+ 8,4%',
                style:
                    textTheme.labelSmall?.copyWith(color: AppColors.mintDark)))
      ]),
      const SizedBox(height: 10),
      Text('12.580.000 ₫', style: textTheme.headlineLarge),
      const SizedBox(height: 20),
      const Divider(),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
            child: _BalanceStat(
                icon: Icons.arrow_downward_rounded,
                label: 'Chi tiêu',
                value: '5.920.000 ₫',
                color: AppColors.coral)),
        Expanded(
            child: _BalanceStat(
                icon: Icons.arrow_upward_rounded,
                label: 'Thu nhập',
                value: '18.500.000 ₫',
                color: AppColors.mint))
      ]),
    ]);
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration:
              BoxDecoration(color: color.withAlpha(24), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 3),
              Text(value, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text('Tổng chi tiêu',
                style:
                    textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk))),
        Text('62%',
            style: textTheme.titleMedium?.copyWith(color: AppColors.mintDark))
      ]),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('5.920.000 ₫', style: textTheme.titleLarge),
        const SizedBox(width: 8),
        Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('/ 9.500.000 ₫', style: textTheme.bodySmall))
      ]),
      const SizedBox(height: 14),
      ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: const LinearProgressIndicator(
              value: .62,
              minHeight: 9,
              backgroundColor: AppColors.mintSoft,
              valueColor: AlwaysStoppedAnimation(AppColors.mint))),
      const SizedBox(height: 10),
      Text('Bạn vẫn còn 3.580.000 ₫ cho đến cuối tháng.',
          style: textTheme.bodySmall),
    ]);
  }
}
