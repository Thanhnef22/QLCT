import 'package:flutter/material.dart';

class CacheStatusBanner extends StatelessWidget {
  const CacheStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_outlined,
            size: 20,
            color: colors.onTertiaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đang hiển thị dữ liệu đã lưu; có thể chưa đồng bộ.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
