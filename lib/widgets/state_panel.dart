import 'package:flutter/material.dart';

enum StatePanelType { loading, empty, error }

class StatePanel extends StatelessWidget {
  const StatePanel({required this.type, this.onAction, super.key});

  final StatePanelType type;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final content = switch (type) {
      StatePanelType.loading => (
          Icons.hourglass_top_rounded,
          'Đang tải dữ liệu',
          'Một chút thôi, dữ liệu của bạn sắp sẵn sàng.'
        ),
      StatePanelType.empty => (
          Icons.inbox_rounded,
          'Chưa có dữ liệu',
          'Bắt đầu thêm giao dịch đầu tiên để theo dõi tài chính.'
        ),
      StatePanelType.error => (
          Icons.cloud_off_rounded,
          'Không thể tải dữ liệu',
          'Kiểm tra kết nối và thử lại sau.'
        ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(content.$1,
            size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(content.$2, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(content.$3,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium),
        if (type != StatePanelType.loading) ...[
          const SizedBox(height: 18),
          FilledButton.tonal(
              onPressed: onAction,
              child: Text(
                  type == StatePanelType.empty ? 'Thêm giao dịch' : 'Thử lại')),
        ],
      ],
    );
  }
}
