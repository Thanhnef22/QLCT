import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../finance/finance_format.dart';
import '../finance/finance_models.dart';
import '../finance/finance_visuals.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, this.onTap, super.key});

  final FinanceTransaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final income = transaction.type == 'income';
    final color = financeColor(transaction.categoryColor);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(financeIcon(transaction.categoryIcon), color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.categoryName, style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.note.isEmpty ? (income ? 'Thu nhập' : 'Chi tiêu') : transaction.note} • ${formatDate(transaction.date)}',
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${income ? '+' : '-'}${formatVnd(transaction.amount)}',
              textAlign: TextAlign.right,
              style: textTheme.labelLarge?.copyWith(
                color: income
                    ? (Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.primary
                          : AppColors.mintDark)
                    : AppColors.coral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
