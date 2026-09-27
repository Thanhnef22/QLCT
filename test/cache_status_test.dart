import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/finance/finance_models.dart';
import 'package:flutter_qlct/finance/finance_repository.dart';
import 'package:flutter_qlct/screens/home_screen.dart';
import 'package:flutter_qlct/screens/reports_screen.dart';

class CacheRepository implements FinanceRepository {
  CacheRepository(this.snapshots);
  final Stream<FinanceTransactionSnapshot> snapshots;

  @override
  Stream<FinanceTransactionSnapshot> watchTransactionsWithSource() => snapshots;

  @override
  Stream<List<FinanceBudget>> watchBudgets() => Stream.value([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const copy = 'Đang hiển thị dữ liệu đã lưu; có thể chưa đồng bộ.';

  testWidgets(
    'cached Home snapshot shows a neutral banner and server snapshot clears it',
    (tester) async {
      final controller = StreamController<FinanceTransactionSnapshot>();
      addTearDown(controller.close);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            repository: CacheRepository(controller.stream),
            now: DateTime(2026, 9),
            displayName: 'An',
          ),
        ),
      );
      controller.add(
        const FinanceTransactionSnapshot(items: [], isFromCache: true),
      );
      await tester.pumpAndSettle();
      expect(find.text(copy), findsOneWidget);
      controller.add(
        const FinanceTransactionSnapshot(items: [], isFromCache: false),
      );
      await tester.pumpAndSettle();
      expect(find.text(copy), findsNothing);
    },
  );

  testWidgets(
    'cached Reports snapshot shows neutral copy without offline claim',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReportsScreen(
            repository: CacheRepository(
              Stream.value(
                const FinanceTransactionSnapshot(items: [], isFromCache: true),
              ),
            ),
            now: DateTime(2026, 9),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(copy), findsOneWidget);
      expect(find.textContaining('Bạn đang ngoại tuyến'), findsNothing);
    },
  );

  testWidgets('transaction stream error shows retry instead of blank screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: CacheRepository(Stream.error(Exception('unavailable'))),
          now: DateTime(2026, 9),
          displayName: 'An',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Thử lại'), findsWidgets);
  });
}
