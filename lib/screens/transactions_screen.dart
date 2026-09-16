import 'package:flutter/material.dart';
import '../app/app_routes.dart';
import '../data/demo_data.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/section_title.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _filter = 0;

  void _goToTab(BuildContext context, int index) {
    final routes = [
      AppRoutes.home,
      AppRoutes.transactions,
      AppRoutes.reports,
      AppRoutes.settings
    ];
    if (index != 1) Navigator.pushReplacementNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['Tất cả', 'Chi tiêu', 'Thu nhập'];
    return Scaffold(
      appBar: AppBar(title: const Text('Giao dịch'), actions: [
        IconButton(
            onPressed: () {}, icon: const Icon(Icons.calendar_month_outlined))
      ]),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            TextField(
                decoration: InputDecoration(
                    hintText: 'Tìm kiếm giao dịch',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.tune_rounded)))),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  filters.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filters[index]),
                      selected: _filter == index,
                      onSelected: (_) => setState(() => _filter = index),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            SectionTitle(title: 'Tháng 9, 2026', actionLabel: '5 giao dịch'),
            const SizedBox(height: 6),
            ...demoTransactions.map((item) => TransactionTile(
                transaction: item,
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.transactionDetail,
                    arguments: item.title))),
          ]),
      floatingActionButton: FloatingActionButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.addTransaction),
          child: const Icon(Icons.add_rounded)),
      bottomNavigationBar: AppBottomNav(
          currentIndex: 1, onSelected: (index) => _goToTab(context, index)),
    );
  }
}
