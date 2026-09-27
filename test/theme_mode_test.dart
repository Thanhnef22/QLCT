import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_qlct/app/app_theme.dart';
import 'package:flutter_qlct/app/theme_controller.dart';
import 'package:flutter_qlct/auth/auth_service.dart';
import 'package:flutter_qlct/screens/settings_screen.dart';
import 'package:flutter_qlct/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget themeHarness(ThemeController controller) => ThemeControllerScope(
  controller: controller,
  child: AnimatedBuilder(
    animation: controller,
    builder: (context, _) => MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: controller.mode,
      home: SettingsScreen(authService: FakeAuthService()),
      routes: {
        '/home': (_) => const Scaffold(body: Center(child: Text('Trang khác'))),
      },
    ),
  ),
);

void main() {
  test('dark theme gives inputs and navigation dark surfaces', () {
    final theme = AppTheme.dark;
    expect(theme.brightness, Brightness.dark);
    expect(theme.inputDecorationTheme.fillColor, isNotNull);
    expect(
      theme.inputDecorationTheme.fillColor!.computeLuminance(),
      lessThan(0.2),
    );
    expect(theme.navigationBarTheme.backgroundColor, isNotNull);
    expect(
      theme.navigationBarTheme.backgroundColor!.computeLuminance(),
      lessThan(0.2),
    );
  });

  test('theme preference survives a fresh controller', () async {
    SharedPreferences.setMockInitialValues({'theme.dark': true});
    final preferences = await SharedPreferences.getInstance();
    final first = ThemeController(preferences);
    expect(first.isDark, isTrue);
    await first.setDark(false);
    final second = ThemeController(preferences);
    expect(second.mode, ThemeMode.light);
    await second.setDark(true);
    expect(ThemeController(preferences).mode, ThemeMode.dark);
  });

  testWidgets('settings switch changes the theme of another route', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController(await SharedPreferences.getInstance());
    await tester.pumpWidget(themeHarness(controller));
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.light,
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Trang khác'))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('settings preview labels are Vietnamese', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController(await SharedPreferences.getInstance());
    await tester.pumpWidget(themeHarness(controller));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Đang tải'), findsOneWidget);
    expect(find.text('Trống'), findsOneWidget);
    expect(find.text('Lỗi'), findsOneWidget);
    expect(find.text('Loading'), findsNothing);
  });

  testWidgets('dark settings remains usable on 320-pixel phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'theme.dark': true});
    final controller = ThemeController(await SharedPreferences.getInstance());
    await tester.pumpWidget(themeHarness(controller));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark settings avatar uses a dark accent surface', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'theme.dark': true});
    final controller = ThemeController(await SharedPreferences.getInstance());
    await tester.pumpWidget(themeHarness(controller));
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundColor!.computeLuminance(), lessThan(0.3));
  });

  testWidgets('login helper text is readable in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const LoginScreen()),
    );
    final helper = tester.widget<Text>(
      find.text('Đăng nhập để tiếp tục quản lý tài chính của bạn.'),
    );
    expect(helper.style?.color, AppTheme.dark.colorScheme.onSurfaceVariant);
  });
}
