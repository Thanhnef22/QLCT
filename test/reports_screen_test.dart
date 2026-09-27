import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/finance/finance_models.dart';
import 'package:flutter_qlct/finance/finance_repository.dart';
import 'package:flutter_qlct/screens/reports_screen.dart';
import 'package:flutter_qlct/widgets/report_charts.dart';

FinanceTransaction transaction(
  String id,
  int amount,
  String type,
  DateTime date,
) => FinanceTransaction(
  id: id,
  amount: amount,
  categoryId: 'food',
  categoryName: 'Ăn uống',
  categoryIcon: 'restaurant',
  categoryColor: '#FF796B',
  type: type,
  note: '',
  date: date,
);

class ReportRepository implements FinanceRepository {
  ReportRepository(this.items);
  final List<FinanceTransaction> items;

  @override
  Stream<List<FinanceTransaction>> watchTransactions() => Stream.value(items);

  @override
  Stream<FinanceTransactionSnapshot> watchTransactionsWithSource() =>
      Stream.value(
        FinanceTransactionSnapshot(items: items, isFromCache: false),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime(2026, 9, 27);

  testWidgets('report rolls into new month without a transaction event', (
    tester,
  ) async {
    var current = DateTime(2026, 9, 30, 23, 59, 59);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(
          repository: ReportRepository([
            transaction('oct', 200000, 'expense', DateTime(2026, 10, 1)),
            transaction('sep', 100000, 'expense', DateTime(2026, 9, 30)),
          ]),
          clock: () => current,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('100.000 ₫'), findsWidgets);
    current = DateTime(2026, 10, 1, 0, 0, 1);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('200.000 ₫'), findsWidgets);
  });

  testWidgets('expanded trend lists intermediate daily amounts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(
          repository: ReportRepository([
            transaction('mon', 20000, 'expense', DateTime(2026, 9, 21)),
            transaction('wed', 30000, 'expense', DateTime(2026, 9, 23)),
          ]),
          now: now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tuần'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Chi tiết xu hướng'), 200);
    await Scrollable.ensureVisible(
      tester.element(find.text('Chi tiết xu hướng')),
      alignment: 0.2,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chi tiết xu hướng'));
    await tester.pumpAndSettle();
    expect(find.text('22/9 • 0 ₫'), findsOneWidget);
    expect(find.text('23/9 • 30.000 ₫'), findsOneWidget);
  });

  testWidgets('tiny real increase is not described as unchanged', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(
          repository: ReportRepository([
            transaction('current', 1000001, 'expense', DateTime(2026, 9, 2)),
            transaction('previous', 1000000, 'expense', DateTime(2026, 8, 2)),
          ]),
          now: now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.textContaining('Tăng dưới 0,1%'), 200);
    expect(find.textContaining('Tăng dưới 0,1%'), findsOneWidget);
  });

  testWidgets('period switch changes real totals', (tester) async {
    final repository = ReportRepository([
      transaction('this-week', 100000, 'expense', DateTime(2026, 9, 23)),
      transaction('earlier-month', 200000, 'expense', DateTime(2026, 9, 2)),
      transaction('earlier-year', 400000, 'expense', DateTime(2026, 8, 2)),
      transaction('income', 1000000, 'income', DateTime(2026, 9, 23)),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(repository: repository, now: now),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('300.000 ₫'), findsWidgets);
    await tester.tap(find.text('Tuần'));
    await tester.pumpAndSettle();
    expect(find.text('100.000 ₫'), findsWidgets);
    await tester.tap(find.text('Năm'));
    await tester.pumpAndSettle();
    expect(find.text('700.000 ₫'), findsWidgets);
  });

  testWidgets('comparison remains current versus previous month on year tab', (
    tester,
  ) async {
    final repository = ReportRepository([
      transaction('current', 200000, 'expense', DateTime(2026, 9, 2)),
      transaction('previous', 100000, 'expense', DateTime(2026, 8, 2)),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(repository: repository, now: now),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Năm'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.textContaining('Tăng 100,0%'), 200);
    expect(find.textContaining('Tăng 100,0%'), findsOneWidget);
  });

  testWidgets('income-only report has totals but no expense painter', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(
          repository: ReportRepository([
            transaction('income', 1000000, 'income', DateTime(2026, 9, 2)),
          ]),
          now: now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1.000.000 ₫'), findsWidgets);
    expect(find.byType(ReportDonutChart), findsNothing);
    expect(find.byType(ReportTrendChart), findsNothing);
    await tester.scrollUntilVisible(
      find.textContaining('Chưa có chi tiêu'),
      200,
    );
    expect(find.textContaining('Chưa có chi tiêu'), findsWidgets);
  });

  testWidgets('empty report shows no illustrative metrics or chart', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(repository: ReportRepository([]), now: now),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa đủ dữ liệu để tạo báo cáo'), findsOneWidget);
    expect(find.byType(ReportDonutChart), findsNothing);
    expect(find.byType(ReportTrendChart), findsNothing);
    expect(find.text('5.920.000 ₫'), findsNothing);
  });

  testWidgets('export action explains that export is not implemented', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(repository: ReportRepository([]), now: now),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xuất báo cáo'));
    await tester.pump();
    expect(
      find.text('Tính năng xuất báo cáo sẽ được hoàn thiện sau.'),
      findsOneWidget,
    );
  });

  testWidgets('report has no overflow at 320 logical pixels', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(
          repository: ReportRepository([
            transaction('expense', 123456789, 'expense', DateTime(2026, 9, 2)),
          ]),
          now: now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
