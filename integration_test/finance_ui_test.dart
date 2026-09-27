import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_qlct/auth/auth_service.dart';
import 'package:flutter_qlct/app/app_routes.dart';
import 'package:flutter_qlct/main.dart';
import 'package:flutter_qlct/screens/home_screen.dart';
import 'package:flutter_qlct/screens/settings_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signed-in user adds a transaction through the app', (
    tester,
  ) async {
    final app = await Firebase.initializeApp();
    final auth = FirebaseAuth.instanceFor(app: app);
    final firestore = FirebaseFirestore.instanceFor(app: app);
    await auth.useAuthEmulator('10.0.2.2', 9099);
    firestore.useFirestoreEmulator('10.0.2.2', 8080);
    final email = 'ui-${DateTime.now().microsecondsSinceEpoch}@example.com';
    await AuthService(
      auth: auth,
      firestore: firestore,
    ).register(fullName: 'Kiểm thử', email: email, password: 'safePassword123');

    await tester.pumpWidget(const QlctApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.textContaining('Xin chào'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Thêm giao dịch'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '85000');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ăn uống').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn ngày'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu giao dịch'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('85.000 ₫'), findsWidgets);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed(AppRoutes.reports);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('85.000 ₫'), findsWidgets);
    expect(find.text('5.920.000 ₫'), findsNothing);
    await tester.tap(find.text('Tuần'));
    await tester.pumpAndSettle();
    expect(find.text('85.000 ₫'), findsWidgets);

    navigator.pushNamed(AppRoutes.home);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Chi tiêu tháng này'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thu nhập'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '1000000');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lương').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn ngày'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu giao dịch'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('1.000.000 ₫'), findsWidgets);
    navigator.pushNamed(AppRoutes.reports);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('915.000 ₫'), findsWidgets);

    navigator.pushNamed(AppRoutes.budgets);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Chưa có ngân sách'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ăn uống').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '100000');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Sắp vượt'), findsOneWidget);

    navigator.pushNamed(AppRoutes.categories);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Ăn uống'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Cà phê');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Cà phê'), findsOneWidget);

    final transactionId =
        (await firestore
                .collection('users/${auth.currentUser!.uid}/transactions')
                .where('categoryId', isEqualTo: 'expense-food')
                .get())
            .docs
            .single
            .id;
    navigator.pushNamed(AppRoutes.transactionDetail, arguments: transactionId);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('-85.000 ₫'), findsOneWidget);
    await tester.tap(find.text('Chỉnh sửa giao dịch'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextFormField).first, '90000');
    await tester.tap(find.text('Lưu giao dịch'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('-90.000 ₫'), findsOneWidget);
    await tester.tap(find.text('Xóa giao dịch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(
      (await firestore
              .doc('users/${auth.currentUser!.uid}/transactions/$transactionId')
              .get())
          .exists,
      isFalse,
    );

    navigator.pushNamed(AppRoutes.settings);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    if (!tester.widget<Switch>(find.byType(Switch)).value) {
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
    }
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Đăng nhập'))).brightness,
      Brightness.dark,
    );
    await tester.enterText(find.byType(TextFormField).first, email);
    await tester.enterText(find.byType(TextFormField).last, 'safePassword123');
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.textContaining('Xin chào'), findsOneWidget);
    expect(find.text('1.000.000 ₫'), findsWidgets);
    expect(
      Theme.of(tester.element(find.byType(HomeScreen))).brightness,
      Brightness.dark,
    );

    navigator.pushNamed(AppRoutes.settings);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    final secondEmail =
        'ui-other-${DateTime.now().microsecondsSinceEpoch}@example.com';
    await AuthService(auth: auth, firestore: firestore).register(
      fullName: 'Tài khoản khác',
      email: secondEmail,
      password: 'safePassword123',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('1.000.000 ₫'), findsNothing);
    expect(find.text('Chi tiêu tháng này'), findsOneWidget);

    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    navigator.pushNamed(AppRoutes.reports);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Chưa đủ dữ liệu để tạo báo cáo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
