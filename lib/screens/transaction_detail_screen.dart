import 'package:flutter/material.dart';
import '../app/app_theme.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final name = title ?? 'Ăn uống';
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết giao dịch'), actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz_rounded))
      ]),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Container(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
                decoration: BoxDecoration(
                    color: AppColors.coralSoft,
                    borderRadius: BorderRadius.circular(24)),
                child: Column(children: [
                  Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.restaurant_rounded,
                          color: AppColors.coral, size: 28)),
                  const SizedBox(height: 14),
                  Text(name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 5),
                  Text('- 85.000 ₫',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(color: AppColors.coral)),
                  const SizedBox(height: 4),
                  Text('Chi tiêu', style: Theme.of(context).textTheme.bodySmall)
                ])),
            const SizedBox(height: 28),
            Text('Thông tin giao dịch',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _DetailRow(
                label: 'Danh mục',
                value: 'Ăn uống',
                icon: Icons.category_outlined),
            _DetailRow(
                label: 'Thời gian',
                value: '16/09/2026, 12:30',
                icon: Icons.schedule_rounded),
            _DetailRow(
                label: 'Tài khoản',
                value: 'Ví tiền mặt',
                icon: Icons.account_balance_wallet_outlined),
            _DetailRow(
                label: 'Ghi chú',
                value: 'Bữa trưa tại văn phòng',
                icon: Icons.notes_rounded),
            const SizedBox(height: 24),
            OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Chỉnh sửa giao dịch')),
            const SizedBox(height: 10),
            TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.coral),
                label: const Text('Xóa giao dịch',
                    style: TextStyle(color: AppColors.coral))),
          ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Icon(icon, color: AppColors.mutedInk, size: 20),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.mutedInk))),
          Text(value, style: Theme.of(context).textTheme.labelLarge)
        ]));
  }
}
