# Task 3 App Experience Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn Home and Reports into honest, live-data screens and complete the app-wide Vietnamese Android experience without changing the existing Firebase data model or routing.

**Architecture:** A pure-Dart statistics module consumes the existing `FinanceTransaction`/`FinanceBudget` lists; Home and Reports render its results from user-scoped `FinanceRepository` streams. Flutter-native painters/widgets draw charts, a small `ThemeController` persists a device-wide theme preference, and a metadata-preserving repository stream exposes a neutral cache state.

**Tech Stack:** Flutter 3.47.4, Dart `^3.13.3`, Material 3, Firebase Auth/Firestore, `flutter_test`, `integration_test`, `shared_preferences` (the only new runtime dependency).

**Spec:** `docs/superpowers/specs/2026-09-27-app-experience-design.md`

## Global Constraints

- Preserve AuthGate, `AppRoutes`, UID-scoped Firestore collections/rules, and Task 1/2 CRUD behavior. No public rules, hardcoded UID, schema change, new state-management package, mock data in the production flow, PDF/XLSX/notification implementation, or new offline database.
- All user-facing copy is Vietnamese. Use integer VND, local calendar boundaries with inclusive start/exclusive end, and the existing mint/coral identity; both themes must remain legible.
- Firestore `isFromCache` means “may not be synchronized,” **not** proof the device is offline. Use the exact neutral banner copy in the spec.
- The working tree already contains user-owned Task 1/2 changes. Inspect each overlapping diff before editing; never reset or stage those changes wholesale. Task-level commits are allowed only when the staged diff contains exclusively this task's work; otherwise defer code commits and state that explicitly.
- Use TDD at each task: test red, implement the smallest passing change, verify green. Do not silently replace unavailable Android/Firebase Emulator verification with a claim of passing.

## Review Focus

1. A Monday 00:00 transaction belongs to the new week, while Sunday 23:59 belongs to the old week; Task 1 pins both boundaries.
2. December-to-January comparison and a zero previous-month expense must never divide by zero or report an invented percentage; Task 1 pins both.
3. A report containing only income still shows the correct totals but no expense chart; Tasks 1 and 3 pin that rendering.
4. A cached snapshot can occur while online, so the banner must say “có thể chưa đồng bộ” and disappear on a server snapshot; Task 4 pins both states.
5. Dark mode survives app restart and remains app-wide after changing tabs, including a signed-out page; Task 5 pins preference restoration and navigation/theme propagation.

---

## File map and task dependencies

- `lib/finance/finance_statistics.dart` (new): calendar ranges and immutable Home/report/comparison summaries; no Flutter or Firebase access. Task 1 owns it; Tasks 2–3 consume it.
- `lib/screens/home_screen.dart`: real monthly Home presentation and five recent transactions. Task 2 owns its main change; Task 4 adds cache UI only.
- `lib/screens/reports_screen.dart`, `lib/widgets/report_charts.dart` (new): real period UI, accessible native charts and export placeholder. Task 3 owns main changes; Task 4 adds cache UI only.
- `lib/finance/finance_repository.dart`, `lib/widgets/cache_status_banner.dart` (new): retain transaction snapshot metadata without breaking `watchTransactions()`. Task 4 owns them.
- `lib/app/theme_controller.dart` (new), `lib/main.dart`, `lib/app/app_theme.dart`, `lib/screens/settings_screen.dart`, `pubspec.yaml`, `pubspec.lock`: app-wide persistent theme. Task 5 owns them, plus targeted dark contrast changes in existing widgets/screens.
- `lib/screens/add_transaction_screen.dart`, `lib/screens/transaction_detail_screen.dart`, `lib/screens/budgets_screen.dart`, `lib/screens/categories_screen.dart`, `lib/screens/transactions_screen.dart` and the existing Home caller: success feedback at the visible caller after completed CRUD. Task 6 owns those small callback changes.
- `lib/data/demo_data.dart`: delete in Task 6 only after `rg` proves no imports **and** its current user-owned diff is understood to be safe to remove. Otherwise leave it untouched and report the deferred cleanup. Leave preview screens and routes intact.
- `integration_test/finance_ui_test.dart`: extend existing Firebase Emulator UI test in Task 7; do not add another competing Firebase initialization path.

### Task 1: Pure-Dart financial summaries

**Files:** Create `lib/finance/finance_statistics.dart`; test `test/finance_statistics_test.dart`.

**Interfaces:** Produce `enum ReportPeriod { week, month, year }`; `DateRange reportRange(ReportPeriod period, DateTime now)` with `start` and `endExclusive`; `HomeSummary summarizeHome(List<FinanceTransaction> transactions, List<FinanceBudget> budgets, DateTime now)` with `balance`, `monthIncome`, `monthExpense`, `budgetLimit`, `budgetSpent`, `recent` (maximum five); `ReportSummary summarizeReport(List<FinanceTransaction> transactions, ReportPeriod period, DateTime now)` with `income`, `expense`, `savings`, `categories`, `trend`; and `MonthComparison compareCurrentMonth(List<FinanceTransaction> transactions, DateTime now)` with `currentExpense`, `previousExpense`, nullable `changePercent`. Category entries carry `categoryId`, snapshot name/color, amount; trend points carry local period start and expense amount. Task 2 consumes `summarizeHome`; Task 3 consumes `summarizeReport`/`compareCurrentMonth`.

- [ ] **Step 1: Write failing unit tests.** Name/assert: `week_range_is_monday_to_monday` (Sun 23:59 included, next Mon 00:00 excluded); `month_and_year_ranges_cross_december` (31 Dec and 1 Jan); `home_balance_month_totals_and_five_recent` (all-time balance vs current-month income/expense, newest five); `budget_uses_only_current_month_matching_expenses` (other month/type/category excluded, empty budget = 0); `report_groups_by_category_id_and_zero_fills_trend` (same ID merged, missing day/month = 0); `income_only_and_empty_report` (savings may be negative, no expense groups); `month_comparison_zero_and_year_turn` (nullable percent when previous = 0, both-zero distinct; normal delta rounded to one decimal).
- [ ] **Step 2: Verify red.** Run `flutter test test/finance_statistics_test.dart`; expect failure from the missing statistics API, not a test setup error.
- [ ] **Step 3: Implement the named types/functions.** Use local `DateTime(year, month, day)` and half-open comparisons; Monday is `DateTime.monday`. For year trend use twelve month buckets, and week/month trend use daily buckets. Reuse `monthKey` and `spentForBudget`; never divide by zero. Preserve repository ordering for `recent` rather than re-sorting a second way. For repeated category IDs, use the first (newest) transaction's snapshot name/color. A no-previous-data `changePercent` is `null`; presentation picks the Vietnamese message.
- [ ] **Step 4: Verify green.** Run `flutter test test/finance_statistics_test.dart`; expect every named test PASS. Run `flutter analyze lib/finance/finance_statistics.dart`; expect no issues.
- [ ] **Step 5: Review scope/commit.** `git diff -- lib/finance/finance_statistics.dart test/finance_statistics_test.dart`; stage/commit only these files if safe (`feat: add financial summaries`), otherwise record why commit is deferred.

### Task 2: Live Home presentation

**Files:** Modify `lib/screens/home_screen.dart`; test `test/home_screen_test.dart`.

**Interfaces:** Consume Task 1 `summarizeHome(...)`. Keep `HomeScreen({FinanceRepository? repository})`; add optional `DateTime? now` and `String? displayName` only if needed to make time/greeting deterministic in widget tests. Do not change routes or AuthGate.

- [ ] **Step 1: Write failing widget tests.** `home_uses_all_time_balance_but_current_month_income_expense` injects a fake repository with last-month and current-month transactions and checks exact VND labels; `home_shows_five_recent_and_current_budget` checks five tiles, matching-month spending and clipped progress with the actual over-limit text; `home_empty_and_error_states` checks create actions and retry; `home_small_width_does_not_overflow` pumps at 320 logical pixels and asserts `tester.takeException() == null`.
- [ ] **Step 2: Verify red.** Run `flutter test test/home_screen_test.dart`; expect assertion failures for old cumulative labels/three tiles, not Firebase initialization errors.
- [ ] **Step 3: Update Home.** Render greeting `Xin chào!` when no name, otherwise `Xin chào, <name>` plus a short subline. Show all-time balance, explicitly labeled monthly income/expense, `budgetLimit`/`budgetSpent`, bounded progress but true remaining/overrun, and five latest transactions. Keep list scrolling, Vietnamese loading/error/empty actions and existing tab/FAB navigation.
- [ ] **Step 4: Verify green.** Run `flutter test test/home_screen_test.dart test/budgets_screen_test.dart`; expect PASS, including no 320-pixel overflow.
- [ ] **Step 5: Review scope/commit.** Inspect `git diff -- lib/screens/home_screen.dart test/home_screen_test.dart`; commit only Task 2 lines if they can be isolated, otherwise defer.

### Task 3: Live Reports, charts, and honest export action

**Files:** Modify `lib/screens/reports_screen.dart`; create `lib/widgets/report_charts.dart`; test `test/reports_screen_test.dart`.

**Interfaces:** Consume Task 1 `summarizeReport(...)` and `compareCurrentMonth(...)`. Keep `ReportsScreen` route constructor compatible; permit optional `FinanceRepository? repository` and `DateTime? now` for widget tests. `ReportDonutChart` consumes category amounts/colors; `ReportTrendChart` consumes trend points. The screen owns `ReportPeriod` selection; no second statistics implementation in chart widgets.

- [ ] **Step 1: Write failing widget tests.** `period_switch_changes_real_totals` uses transactions in current week, earlier current month and previous year; `comparison_is_month_based_even_on_year_tab` checks an unchanged current-vs-previous-month card; `income_only_has_totals_without_painters` asserts correct income/savings, no donut/line painter and explanatory text; `empty_report_has_no_fake_metrics_or_chart`; `export_action_shows_exact_placeholder` asserts the spec's SnackBar copy; `report_is_readable_at_320_width` checks no overflow and visible legend values/semantic descriptions.
- [ ] **Step 2: Verify red.** Run `flutter test test/reports_screen_test.dart`; expect failures from mock values/nonfunctional filter.
- [ ] **Step 3: Implement the Report screen.** Use one transaction stream, `SegmentedButton<ReportPeriod>` for Tuần/Tháng/Năm, period totals, category legend with amount and percent, trend labels by day/month, fixed month comparison, and relative income/expense bars. `CustomPainter` draws only non-empty expense data; wrap charts with `Semantics` text and keep numeric text outside the canvas. Use theme colors/contrast, responsive width, loading/error/retry/empty states. “Xuất báo cáo” shows exactly `Tính năng xuất báo cáo sẽ được hoàn thiện sau.`; create no file or fake share flow.
- [ ] **Step 4: Verify green.** Run `flutter test test/reports_screen_test.dart test/finance_statistics_test.dart`; expect PASS. Run `flutter analyze lib/screens/reports_screen.dart lib/widgets/report_charts.dart`; expect no issues.
- [ ] **Step 5: Review scope/commit.** Inspect only Task 3 paths and commit if the stage is isolated, otherwise defer.

### Task 4: Truthful Firestore cache indication

**Files:** Modify `lib/finance/finance_repository.dart`, `lib/screens/home_screen.dart`, `lib/screens/reports_screen.dart`; create `lib/widgets/cache_status_banner.dart`; test `test/cache_status_test.dart`.

**Interfaces:** Produce `FinanceTransactionSnapshot` with `List<FinanceTransaction> items` and `bool isFromCache`, and `FinanceRepository.watchTransactionsWithSource(): Stream<FinanceTransactionSnapshot>` using `snapshots(includeMetadataChanges: true)`. Preserve the old `watchTransactions(): Stream<List<FinanceTransaction>>` contract for Task 1/2 callers. Task 2/3 screens switch to the richer stream without changing their summary calculations.

- [ ] **Step 1: Write failing tests.** `cached_snapshot_shows_neutral_banner` pumps Home/Report with a fake cached snapshot and checks exact `Đang hiển thị dữ liệu đã lưu; có thể chưa đồng bộ.`; `server_snapshot_clears_banner` emits the next `isFromCache: false` snapshot without changing items and asserts the banner disappears; `repository_keeps_legacy_transaction_stream` checks the previous list-stream API remains usable; `cache_without_items_and_error_has_retry` checks nonblank error/empty UI.
- [ ] **Step 2: Verify red.** Run `flutter test test/cache_status_test.dart`; expect missing API/banner failures.
- [ ] **Step 3: Implement metadata mapping and the shared banner.** Enable metadata-only changes so a cache-to-server transition rebuilds UI. Do not infer “offline” from cache; keep one transaction query/sorting path. Reuse the common small banner in Home/Report, then preserve their existing loading/error/empty behavior.
- [ ] **Step 4: Verify green.** Run `flutter test test/cache_status_test.dart test/home_screen_test.dart test/reports_screen_test.dart`; expect PASS.
- [ ] **Step 5: Review scope/commit.** Inspect changed repository/screens against Task 1/2 diff; stage only Task 4 lines if safely separable, otherwise defer.

### Task 5: Persistent app-wide dark mode and Vietnamese Settings

**Files:** Create `lib/app/theme_controller.dart`; modify `lib/main.dart`, `lib/app/app_theme.dart`, `lib/screens/settings_screen.dart`, `pubspec.yaml`, `pubspec.lock`; adjust hard-coded text/surface colors in `lib/screens/home_screen.dart`, `lib/screens/reports_screen.dart`, `lib/screens/budgets_screen.dart`, `lib/screens/categories_screen.dart`, `lib/screens/transaction_detail_screen.dart`, `lib/screens/login_screen.dart`, `lib/screens/register_screen.dart`, `lib/widgets/transaction_tile.dart` only where the dark smoke test finds contrast failures. Test `test/theme_mode_test.dart`.

**Interfaces:** `ThemeController(SharedPreferences preferences) extends ChangeNotifier` exposes `ThemeMode get mode`, `bool get isDark`, `Future<void> setDark(bool value)`; preference key `theme.dark`. `ThemeControllerScope` (in the same file) exposes `ThemeControllerScope.of(context)` to Settings. `QlctApp({ThemeController? themeController})` uses the controller at the `MaterialApp.themeMode` level; `main()` loads preferences before `runApp` to avoid a light-theme flash. `SettingsScreen({AuthService? authService})` permits a fake account service in widget tests. Existing `const QlctApp()` integration usage must either remain compatible or be updated in Task 7.

- [ ] **Step 1: Write failing tests.** `preference_restores_dark_mode_after_new_controller` uses `SharedPreferences.setMockInitialValues` and a fresh controller; `settings_switch_changes_material_app_not_just_settings` checks Theme brightness before/after tap and after navigating tabs; `theme_remains_after_signed_out_route` checks a non-protected page; `settings_preview_labels_are_vietnamese` checks “Đang tải”, “Trống”, “Lỗi”; `dark_screens_have_readable_surfaces` pumps representative Home/Report/Settings at 320 width and checks no overflow plus light-on-dark text/theme colors.
- [ ] **Step 2: Verify red.** Run `flutter test test/theme_mode_test.dart`; expect no controller/persistence and old English labels.
- [ ] **Step 3: Implement persistent theme.** Add only `shared_preferences`, make the switch read/write the shared controller, remove the local Settings `Theme` wrapper. Complete dark ColorScheme, card/input/navigation/indicator and text colors; change hard-coded colors only when they are illegible. Keep preview states and AppRoutes unchanged.
- [ ] **Step 4: Verify green.** Run `flutter pub get`, `flutter test test/theme_mode_test.dart test/app_routes_test.dart`, `flutter analyze`; expect success with no new analyzer issues.
- [ ] **Step 5: Review scope/commit.** Inspect `pubspec`/lock and every touched color line; commit only isolated Task 5 changes if safe, otherwise defer.

### Task 6: CRUD feedback and mock cleanup

**Files:** Modify `lib/screens/add_transaction_screen.dart`, `lib/screens/transaction_detail_screen.dart`, `lib/screens/budgets_screen.dart`, `lib/screens/categories_screen.dart`, `lib/screens/transactions_screen.dart`, `lib/screens/home_screen.dart` as needed; delete `lib/data/demo_data.dart` only if unused and safe to remove. Test `test/finance_feedback_test.dart`; extend existing CRUD widget tests where a narrow case already lives.

**Interfaces:** Keep existing repository methods/dialog confirmations and route results. Make save dialogs return `true` only after successful writes; their `showDialog<bool>` callers show the SnackBar. Keep `AddTransactionScreen` returning `true` after save and make Home/Transactions/Detail await that route result; make Detail return a success result after deletion so its caller can acknowledge it. Success SnackBars belong to the visible parent screen after successful `Navigator.pop`/dialog completion, not to a disposed dialog; use Vietnamese saved/deleted messages. Failed operations keep their existing error SnackBar and must not show success.

- [ ] **Step 1: Write failing tests.** `transaction_save_and_delete_show_success_only_after_completion`; `budget_and_category_save_delete_show_success`; `cancelled_or_failed_delete_shows_no_success`; `optional_note_and_null_receipt_render_safely`. Stub repository futures so assertions can distinguish pending vs completed actions.
- [ ] **Step 2: Verify red.** Run `flutter test test/finance_feedback_test.dart`; expect missing success feedback, not missing Firebase setup.
- [ ] **Step 3: Add the feedback at the existing callback sites.** Keep confirmation before delete, guards against duplicate taps, realtime list updates and error handling. Check `rg -n 'demo_data' lib test integration_test` and inspect `git diff -- lib/data/demo_data.dart`; remove the unused production file only if its existing edits are safe to discard. Do not delete preview components or seed categories.
- [ ] **Step 4: Verify green.** Run `flutter test test/finance_feedback_test.dart test/transaction_ui_test.dart test/budgets_screen_test.dart test/categories_screen_test.dart`; expect PASS.
- [ ] **Step 5: Review scope/commit.** Inspect feedback/mocked-file diff; stage only this task if isolated, otherwise defer.

### Task 7: Android end-to-end verification and final review

**Files:** Modify `integration_test/finance_ui_test.dart`; optionally `integration_test/finance_crud_test.dart` if required to assert the full user-data boundary. No production feature added in this task.

**Interfaces:** Exercise the real `QlctApp`, AuthGate/routes, Firebase Auth and Firestore Emulator; reuse existing emulator configuration and fresh per-test users. Test identity stays UID-scoped.

- [ ] **Step 1: Extend the Android integration test.** `login_create_income_and_expense_updates_home_and_reports` checks real totals/filter changes; `budget_warning_then_sign_out_and_sign_in_preserves_only_own_data` covers warning, logout/relogin and a second UID; `dark_and_narrow_screen_smoke` checks navigation, theme and no overflow. Use dates relative to `DateTime.now()` so the test is not tied to September 2026. Do not infer success merely from repository reads—assert visible UI.
- [ ] **Step 2: Run it with Firebase Emulator.** Start the existing Auth/Firestore emulator setup from `firebase.json`, then run `flutter test integration_test/finance_ui_test.dart -d <android-device-id>`; expect PASS if Tasks 1–6 already cover the flow, otherwise retain the failing assertion as evidence. If emulator/device is unavailable, record the exact blocker rather than skip silently.
- [ ] **Step 3: Fix only integration issues revealed by that run.** Adjust test synchronization, screen semantics or scoped UI defects; do not redesign Auth/CRUD or loosen rules.
- [ ] **Step 4: Run final verification.** `flutter pub get`; `dart format lib test integration_test`; `flutter analyze`; `flutter test`; Firestore rules tests per `rules_test` setup; `flutter test integration_test/finance_ui_test.dart -d <android-device-id>` with emulators; `flutter run -d <android-device-id>` for the narrow/dark smoke. Record outputs and any environment-only blockers precisely.
- [ ] **Step 5: Review and hand off.** Run `git diff --check`, inspect staged/unstaged paths, get a fresh code review per Superpowers, and report tests, deferred features (real export/notifications), and any uncommitted Task 3 work. Never include unrelated Task 1/2 user changes in a commit.
