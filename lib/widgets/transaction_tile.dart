import 'package:flutter/material.dart';
import '../data/demo_data.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, this.onTap, super.key});

  final DemoTransaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                color: transaction.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(transaction.icon, color: Colors.black54, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.title, style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('${transaction.category} • ${transaction.date}',
                      style: textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              transaction.amount,
              textAlign: TextAlign.right,
              style: textTheme.labelLarge?.copyWith(
                color: transaction.isIncome ? const Color(0xFF07936E) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
