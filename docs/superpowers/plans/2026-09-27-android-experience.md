# Android Alerts, Offline and Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish truthful budget states/local alerts, Firestore offline feedback and first-launch onboarding without a second database or backend.

**Architecture:** One pure budget-status/alert decision path feeds Home, Budgets and an app-level Android local-notification listener. Firestore snapshot metadata distinguishes cached and pending writes; `shared_preferences` persists alert opt-in/deduplication and onboarding completion. Existing AuthGate and Firebase persistence remain the source of truth.

**Tech Stack:** Flutter 3.47.4/Dart 3.13.3, Firestore, existing `shared_preferences`, `flutter_local_notifications` 22.3.1 ([package and Android setup](https://pub.dev/packages/flutter_local_notifications)); Java 17/AGP 9.1.0 already present, enable the plugin's documented core-library desugaring.

**Spec:** `docs/superpowers/specs/2026-09-27-android-completion-design.md`

## Global Constraints

- Android is the only feature target; no FCM, Cloud Functions, Storage, local SQL database or paid service.
- Local alerts work only while the app is active; never promise delivery for changes made while the app is terminated.
- A cached snapshot is not proof of Internet loss; copy must not claim “ngoại tuyến” from `isFromCache` alone.
- Correct budget bands: <80% safe, 80%–<100% warning, exactly 100% used up, >100% exceeded. Use integer multiplication, not a rounded percent to decide.
- Preserve UID-scoped Firebase/Auth flows and user-owned dirty Task 1/2 work; stage only isolated changes.

## Review Focus

- A budget exactly at 100% must never say “Đã vượt 0 ₫”: Task 1 unit/widget test.
- Different UID/month/budget alert keys must not suppress each other; repeated snapshots must not spam: Task 2 test.
- Android notification permission denied must leave finance UI functional and the switch truthful: Task 2 widget/Android test.
- Cached data with pending writes must show a distinct unsynced message and clear only after server metadata changes: Task 3 widget test.
- Already-signed-in users and users who finished onboarding must not be sent back to onboarding after logout/restart: Task 4 widget/Android test.

---

## File map

- `lib/finance/finance_rules.dart`: `BudgetStatus.usedUp`, exact threshold helper shared by Home/Budgets.
- `lib/finance/budget_alerts.dart`: pure `BudgetAlert? alertForBudget(...)`/dedupe keys, no plugin access.
- `lib/app/budget_alert_service.dart`: permission, notification channel, stream listening for current UID/current month and preference keys.
- `lib/screens/settings_screen.dart`: alert switch; remove demo-state buttons.
- `lib/finance/finance_repository.dart`, `lib/widgets/cache_status_banner.dart`, `lib/screens/home_screen.dart`, `lib/screens/reports_screen.dart`, `lib/screens/budgets_screen.dart`, `lib/screens/wallets_screen.dart`: cache and pending-write display without changing old list-stream APIs.
- `lib/main.dart`, `lib/screens/onboarding_screen.dart`, `lib/app/app_routes.dart`: first-run gate and completion preference.
- `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `pubspec.yaml`, `pubspec.lock`: plugin's minimal Android setup.
- `test/finance_rules_test.dart`, `test/budget_alerts_test.dart`, `test/cache_status_test.dart`, `test/onboarding_test.dart`, `integration_test/experience_flow_test.dart`: checks.

### Task 1: Exact budget thresholds

**Files:** Modify `lib/finance/finance_rules.dart`, `lib/screens/budgets_screen.dart`, `lib/screens/home_screen.dart`, `test/finance_rules_test.dart`, `test/budgets_screen_test.dart`, `test/home_screen_test.dart`.

**Interfaces:** `enum BudgetStatus { safe, warning, usedUp, exceeded }`; `BudgetStatus budgetStatus(int spent, int limit)` stays shared. At exactly limit UI says “Đã dùng hết ngân sách”; only spent > limit says “Đã vượt <VND>”.

- [ ] **Step 1: Write failing tests.** For limit 1000, spent 799/800/999/1000/1001 yields safe/warning/warning/usedUp/exceeded. Home and Budget card at 1000 have no “Đã vượt 0 ₫”.
- [ ] **Step 2: Verify red.** `flutter test test/finance_rules_test.dart test/budgets_screen_test.dart test/home_screen_test.dart` → old enum/status fails.
- [ ] **Step 3: Implement the shared comparison and both labels.** Preserve existing progress clamping and true amount displays.
- [ ] **Step 4: Verify green.** Repeat targeted tests; `flutter analyze lib/finance/finance_rules.dart lib/screens` → no issues.
- [ ] **Step 5: Review/commit isolated hunks or defer overlapping Task 1/2 screen paths.**

### Task 2: Local budget alerts

**Files:** Create `lib/finance/budget_alerts.dart`, `lib/app/budget_alert_service.dart`, `test/budget_alerts_test.dart`; modify `lib/main.dart`, `lib/screens/settings_screen.dart`, `pubspec.yaml`, `pubspec.lock`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`; test `integration_test/experience_flow_test.dart`.

**Interfaces:** `BudgetAlert? alertForBudget(FinanceBudget budget, int spent)` returns null when safe and a warning/usedUp/exceeded message otherwise; `String budgetAlertKey(String uid, FinanceBudget budget)` includes UID/budget ID/month and stores the highest notified `BudgetStatus` as its preference value. `BudgetAlertService` observes current UID's transaction/budget streams only while app is active, exposes `Future<bool> setEnabled(bool)` and `bool isEnabled`, and owns Android permission/channel/dedupe preferences.

- [ ] **Step 1: Write failing tests.** Each exact threshold produces the correct Vietnamese alert; same snapshot/restart sends once, 80→100→101 yields three distinct alerts, User B/month B is independent, permission denial leaves toggle off and finance flows usable, signing out cancels subscriptions.
- [ ] **Step 2: Verify red.** `flutter test test/budget_alerts_test.dart` plus Android `integration_test/experience_flow_test.dart` → missing alert/service/toggle.
- [ ] **Step 3: Implement pure decision first, then plugin adapter.** Add only `flutter_local_notifications`, POST_NOTIFICATIONS and core-library desugaring per its current package documentation; request permission on opt-in, not at launch. Persist highest sent threshold per budget/month/UID; do not generate historical alerts for previous months.
- [ ] **Step 4: Verify green.** Repeat tests, `flutter analyze`, `flutter build apk --debug`, Android permission-granted/denied smoke; expect no build regression on emulator.
- [ ] **Step 5: Review/commit isolated files/hunks or record deferment.**

### Task 3: Truthful cache and pending-write state

**Files:** Modify `lib/finance/finance_repository.dart`, `lib/widgets/cache_status_banner.dart`, `lib/screens/home_screen.dart`, `lib/screens/reports_screen.dart`, `lib/screens/budgets_screen.dart`, `lib/screens/wallets_screen.dart`, `test/cache_status_test.dart`, `integration_test/experience_flow_test.dart`.

**Interfaces:** Extend `FinanceTransactionSnapshot` with `bool hasPendingWrites = false`; add `FinanceBudgetSnapshot` and `FinanceWalletSnapshot` with `items`, `isFromCache`, `hasPendingWrites`, plus `watchBudgetsWithSource()` and `watchWalletsWithSource()` while preserving list-stream methods. `CacheStatusBanner({bool pendingWrites = false})` shows “Thay đổi đang chờ đồng bộ.” when pending, else existing neutral cached-data text.

- [ ] **Step 1: Write failing tests.** Cached server metadata toggles banner without item change; pending write text takes precedence and clears on acknowledgement; budget-only pending write is visible on Budgets/Home and wallet-only pending write on Wallets; no cache/pending shows no banner; Android offline after a prior online session still renders cached transactions, and first-login/no-cache error is recoverable.
- [ ] **Step 2: Verify red.** `flutter test test/cache_status_test.dart` and Android emulator test → missing pending metadata/UI.
- [ ] **Step 3: Map `snapshots(includeMetadataChanges: true)` for transactions/budgets/wallets; preserve legacy list streams.** Avoid server-only reads that unnecessarily block operations with cached categories; do not show a false “offline” label.
- [ ] **Step 4: Verify green.** Repeat targeted/full widget tests and Android disableNetwork/enableNetwork smoke; `flutter analyze` → no issues.
- [ ] **Step 5: Review/commit isolated edits or defer overlapping repository/screens.**

### Task 4: Onboarding and production Settings cleanup

**Files:** Modify `lib/main.dart`, `lib/screens/onboarding_screen.dart`, `lib/app/app_routes.dart`, `lib/screens/settings_screen.dart`, `test/onboarding_test.dart`, `test/theme_mode_test.dart`, `test/app_routes_test.dart`, `integration_test/experience_flow_test.dart`.

**Interfaces:** SharedPreferences key `onboarding.seen`; app startup enters onboarding only when key false and `FirebaseAuth.currentUser == null`; skip/start set key true before navigating `AppRoutes.start`. Existing QlctApp test injection remains possible. Settings removes only demo buttons; actual `StatePanel` remains in real error/empty/loading paths.

- [ ] **Step 1: Write failing tests.** Fresh signed-out install opens onboarding, skip/start enter login and persist seen state; signed-in user bypasses onboarding; logout/restart never repeats it; theme persists and demo buttons no longer appear; 320 px onboarding/Settings have no overflow.
- [ ] **Step 2: Verify red.** `flutter test test/onboarding_test.dart test/theme_mode_test.dart test/app_routes_test.dart` → current initial route/demo assertions fail.
- [ ] **Step 3: Reuse the preferences already loaded for theme.** Avoid a second async startup flash; keep AuthGate as the secure start route and update old integration fixtures for first-run setup.
- [ ] **Step 4: Verify green.** Repeat targeted/full tests, Android `integration_test/experience_flow_test.dart`, `flutter analyze`, `flutter run -d emulator-5554`; expect first-run and restart flows correct.
- [ ] **Step 5: Review/commit isolated edits if safe; check `git diff --check`, list remaining dirty user-owned paths and hand off release-signing configuration as a separate user-secret prerequisite.**
