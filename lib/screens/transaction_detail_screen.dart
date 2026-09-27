import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../app/app_theme.dart';
import '../finance/finance_format.dart';
import '../finance/finance_models.dart';
import '../finance/finance_repository.dart';
import '../finance/finance_visuals.dart';
import '../widgets/state_panel.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({
    required this.transactionId,
    this.repository,
    super.key,
  });
  final String transactionId;
  final FinanceRepository? repository;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late final FinanceRepository _repository =
      widget.repository ?? FinanceRepository();
  late Stream<FinanceTransaction?> _transaction = _repository.watchTransaction(
    widget.transactionId,
  );
  bool _deleting = false;

  void _retry() => setState(() {
    _transaction = _repository.watchTransaction(widget.transactionId);
  });

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giao dịch?'),
        content: const Text('Giao dịch sẽ bị xóa vĩnh viễn.'),
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
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await _repository.deleteTransaction(widget.transactionId);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(financeErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _edit() async {
    final saved = await Navigator.pushNamed(
      context,
      AppRoutes.addTransaction,
      arguments: widget.transactionId,
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu giao dịch.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chi tiết giao dịch')),
    body: StreamBuilder<FinanceTransaction?>(
      stream: _transaction,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: StatePanel(type: StatePanelType.error, onAction: _retry),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final item = snapshot.data;
        if (item == null) {
          return const Center(child: Text('Giao dịch không còn tồn tại.'));
        }
        final income = item.type == 'income';
        final scheme = Theme.of(context).colorScheme;
        final dark = Theme.of(context).brightness == Brightness.dark;
        final color = income
            ? (dark ? scheme.primary : AppColors.mintDark)
            : AppColors.coral;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: dark
                    ? scheme.surfaceContainerHighest
                    : (income ? AppColors.mintSoft : AppColors.coralSoft),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: scheme.surface,
                    child: Icon(
                      financeIcon(item.categoryIcon),
                      color: financeColor(item.categoryColor),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.categoryName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${income ? '+' : '-'}${formatVnd(item.amount)}',
                    style: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(color: color),
                  ),
                  Text(income ? 'Thu nhập' : 'Chi tiêu'),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'Thông tin giao dịch',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _DetailRow(
              label: 'Danh mục',
              value: item.categoryName,
              icon: Icons.category_outlined,
            ),
            _DetailRow(
              label: 'Ngày',
              value: formatDate(item.date),
              icon: Icons.calendar_today_outlined,
            ),
            if (item.note.isNotEmpty)
              _DetailRow(
                label: 'Ghi chú',
                value: item.note,
                icon: Icons.notes_rounded,
              ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _deleting ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Chỉnh sửa giao dịch'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _deleting ? null : _delete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.coral,
              ),
              label: Text(
                _deleting ? 'Đang xóa...' : 'Xóa giao dịch',
                style: const TextStyle(color: AppColors.coral),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    ),
  );
}
