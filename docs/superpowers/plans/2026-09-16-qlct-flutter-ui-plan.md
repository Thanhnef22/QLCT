# QLCT Flutter UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the finance-management mobile UI from the approved Figma direction, with reusable Flutter widgets and navigation between the requested screens.

**Architecture:** A small Flutter app using `MaterialApp` with a central `AppRoutes` route table and `PageRouteBuilder` transitions. Screens own presentation only; dummy data stays in local constants. Shared visual primitives live in `app_theme.dart` and `widgets/`.

**Tech Stack:** Flutter 3.47.4, Dart 3.13.3, Material 3, Flutter SDK only.

**Spec:** Approved UI scope from the conversation on 2026-09-16 and Figma file `B3MJYwDu1qDIITSE277YDF`.

## Global Constraints

- UI and navigation only; no API, database, authentication, or business logic.
- Use Vietnamese UI copy and realistic dummy finance data.
- Prefer Flutter SDK widgets and icons; do not add packages for this prototype.
- Keep files focused: theme, routes, shared widgets, and screen-level widgets are separate.
- Provide loading, empty, and error states as reusable presentation widgets.

---

### Task 1: Create the minimal Flutter project contract

**Files:**
- Create: `pubspec.yaml`
- Create: `test/app_routes_test.dart`

**Interfaces:**
- The test imports `lib/app/app_routes.dart` and expects named route constants for onboarding, login, register, home, transactions, add transaction, transaction detail, reports, budgets, and settings.

- [ ] **Step 1: Write the failing route test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/app/app_routes.dart';
import 'package:flutter_qlct/screens/onboarding_screen.dart';

void main() {
  testWidgets('opens onboarding at the initial route', (tester) async {
    await tester.pumpWidget(MaterialApp(
      initialRoute: AppRoutes.onboarding,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    ));

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  test('declares the core navigation paths', () {
    expect(AppRoutes.all, containsAll(<String>[
      AppRoutes.onboarding,
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.home,
      AppRoutes.transactions,
      AppRoutes.addTransaction,
      AppRoutes.transactionDetail,
      AppRoutes.reports,
      AppRoutes.budgets,
      AppRoutes.settings,
    ]));
  });
}
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `flutter test test/app_routes_test.dart`

Expected: FAIL because the route and screen files do not exist yet.

- [ ] **Step 3: Add only the project manifest needed to run Flutter**

Use an SDK-only `pubspec.yaml` with package name `flutter_qlct`, Flutter SDK constraint `>=3.0.0 <4.0.0`, and `flutter: uses-material-design: true`.

### Task 2: Add theme, shared widgets, and routes

**Files:**
- Create: `lib/app/app_theme.dart`
- Create: `lib/app/app_routes.dart`
- Create: `lib/widgets/section_title.dart`
- Create: `lib/widgets/finance_card.dart`
- Create: `lib/widgets/transaction_tile.dart`
- Create: `lib/widgets/app_bottom_nav.dart`
- Create: `lib/widgets/state_panel.dart`

**Interfaces:**
- `AppRoutes.onGenerateRoute(RouteSettings)` returns the correct screen route and preserves an optional transaction title argument.
- `AppTheme.light` and `AppTheme.dark` return complete `ThemeData` values.
- Shared widgets accept only the data needed to render their presentation.

- [ ] **Step 1: Implement the minimum route table and theme**
- [ ] **Step 2: Implement shared widgets with Material semantics**
- [ ] **Step 3: Run `flutter test test/app_routes_test.dart` and confirm GREEN**

### Task 3: Build onboarding and auth screens

**Files:**
- Create: `lib/screens/onboarding_screen.dart`
- Create: `lib/screens/login_screen.dart`
- Create: `lib/screens/register_screen.dart`

**Interfaces:**
- Onboarding routes to login and can skip to login.
- Login routes to home or register.
- Register routes to home or login.

- [ ] **Step 1: Build the three-slide onboarding presentation**
- [ ] **Step 2: Build login and register forms as visual-only fields**
- [ ] **Step 3: Add button navigation and verify the route test remains green**

### Task 4: Build the finance surfaces

**Files:**
- Create: `lib/screens/home_screen.dart`
- Create: `lib/screens/transactions_screen.dart`
- Create: `lib/screens/add_transaction_screen.dart`
- Create: `lib/screens/transaction_detail_screen.dart`
- Create: `lib/screens/reports_screen.dart`
- Create: `lib/screens/budgets_screen.dart`
- Create: `lib/screens/settings_screen.dart`
- Modify: `lib/widgets/app_bottom_nav.dart`

**Interfaces:**
- Home bottom navigation opens transactions, reports, budgets, and settings.
- Home quick actions open add transaction and transaction detail.
- Transaction list opens detail; add transaction returns to the previous screen.
- Settings exposes a theme toggle presentation using local widget state only.

- [ ] **Step 1: Build the home dashboard and bottom navigation**
- [ ] **Step 2: Build transactions, add, and detail screens**
- [ ] **Step 3: Build reports, budgets, and settings screens**
- [ ] **Step 4: Add loading, empty, and error state examples without data logic**

### Task 5: Wire app entry and verify

**Files:**
- Create: `lib/main.dart`
- Modify: `test/app_routes_test.dart`

- [ ] **Step 1: Configure `MaterialApp` with theme and initial onboarding route**
- [ ] **Step 2: Add route smoke tests for login and home**
- [ ] **Step 3: Run `flutter analyze`**
- [ ] **Step 4: Run `flutter test`**
- [ ] **Step 5: Run `flutter build apk --debug` when Android tooling is available**

