import 'package:flutter/material.dart';
import '../app/app_theme.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool _isExpense = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm giao dịch'), actions: [
        IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded))
      ]),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                      value: true,
                      label: Text('Chi tiêu'),
                      icon: Icon(Icons.arrow_upward_rounded)),
                  ButtonSegment(
                      value: false,
                      label: Text('Thu nhập'),
                      icon: Icon(Icons.arrow_downward_rounded))
                ],
                selected: {
                  _isExpense
                },
                onSelectionChanged: (value) =>
                    setState(() => _isExpense = value.first)),
            const SizedBox(height: 28),
            Text('Số tiền', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.line)),
                child: Row(children: [
                  Text(_isExpense ? '-' : '+',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                              color: _isExpense
                                  ? AppColors.coral
                                  : AppColors.mint)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('0',
                          style: Theme.of(context).textTheme.headlineLarge)),
                  Text('₫',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppColors.mutedInk))
                ])),
            const SizedBox(height: 20),
            const TextField(
                decoration: InputDecoration(
                    labelText: 'Danh mục',
                    hintText: 'Chọn danh mục',
                    prefixIcon: Icon(Icons.category_outlined),
                    suffixIcon: Icon(Icons.chevron_right_rounded))),
            const SizedBox(height: 16),
            const TextField(
                decoration: InputDecoration(
                    labelText: 'Mô tả',
                    hintText: 'Ví dụ: Bữa trưa văn phòng',
                    prefixIcon: Icon(Icons.notes_rounded))),
            const SizedBox(height: 16),
            const TextField(
                decoration: InputDecoration(
                    labelText: 'Ngày giao dịch',
                    hintText: '16/09/2026',
                    prefixIcon: Icon(Icons.calendar_today_outlined))),
            const SizedBox(height: 16),
            const TextField(
                maxLines: 3,
                decoration: InputDecoration(
                    labelText: 'Ghi chú',
                    hintText: 'Thêm ghi chú nếu cần',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                    alignLabelWithHint: true)),
            const SizedBox(height: 28),
            FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Lưu giao dịch')),
          ]),
    );
  }
}
