String formatVnd(int value) {
  final digits = value.abs().toString();
  final parts = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = end < 3 ? 0 : end - 3;
    parts.insert(0, digits.substring(start, end));
  }
  return '${value < 0 ? '-' : ''}${parts.join('.')} ₫';
}

int? parseVnd(String input) {
  final digits = input.trim().replaceAll(RegExp(r'[.\s]'), '');
  if (!RegExp(r'^\d+$').hasMatch(digits)) return null;
  final value = int.tryParse(digits);
  return value != null && value > 0 ? value : null;
}

String formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String formatMonth(DateTime date) => 'Tháng ${date.month}, ${date.year}';

String monthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';
