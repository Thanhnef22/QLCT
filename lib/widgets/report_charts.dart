import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../finance/finance_format.dart';
import '../finance/finance_statistics.dart';
import '../finance/finance_visuals.dart';

class ReportDonutChart extends StatelessWidget {
  const ReportDonutChart({
    required this.categories,
    required this.total,
    super.key,
  });

  final List<CategoryExpense> categories;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Biểu đồ phân bổ chi tiêu theo danh mục',
    child: SizedBox.square(
      dimension: 156,
      child: CustomPaint(
        painter: _DonutPainter(
          categories: categories,
          total: total,
          track: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    ),
  );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.categories,
    required this.total,
    required this.track,
  });

  final List<CategoryExpense> categories;
  final int total;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      bounds.deflate(12),
      0,
      math.pi * 2,
      false,
      stroke..color = track,
    );
    var start = -math.pi / 2;
    for (final category in categories) {
      final sweep = category.amount / total * math.pi * 2;
      canvas.drawArc(
        bounds.deflate(12),
        start,
        sweep,
        false,
        stroke..color = financeColor(category.color),
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.categories != categories ||
      oldDelegate.total != total ||
      oldDelegate.track != track;
}

class ReportTrendChart extends StatelessWidget {
  const ReportTrendChart({required this.points, super.key});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Biểu đồ xu hướng chi tiêu theo thời gian. ${points.map((point) => '${formatDate(point.start)}: ${formatVnd(point.expense)}').join('; ')}',
    child: SizedBox(
      width: double.infinity,
      height: 130,
      child: CustomPaint(
        painter: _TrendPainter(
          points: points,
          line: Theme.of(context).colorScheme.primary,
          grid: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    ),
  );
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.points, required this.line, required this.grid});

  final List<TrendPoint> points;
  final Color line;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = grid;
    for (var row = 1; row <= 3; row++) {
      final y = size.height * row / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (points.isEmpty) return;
    final peak = points.map((point) => point.expense).reduce(math.max);
    if (peak <= 0) return;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * i / (points.length - 1);
      final y =
          size.height - 12 - (points[i].expense / peak) * (size.height - 24);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.line != line ||
      oldDelegate.grid != grid;
}
