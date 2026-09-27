# Android Wallets and Profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add manual wallets, internal transfers and editable display name without losing existing expense data.

**Architecture:** Extend the UID-scoped Firestore repository and keep monetary calculations pure Dart. A deterministic `cash` wallet represents old transactions without `walletId`; wallet balances are derived, never stored as mutable totals. Home/Settings and two new screens consume the same repository streams.

**Tech Stack:** Flutter 3.47.4/Dart 3.13.3, Firebase Auth, Cloud Firestore, existing Material theme and emulator tests.

**Spec:** `docs/superpowers/specs/2026-09-27-android-completion-design.md`

## Global Constraints

- Android is the product target; do not break shared Dart analysis for Web/Windows.
- No bank or e-wallet API, Firebase Storage, receipt UI, billing, new state-management framework or bulk Firestore migration.
- Preserve `users/{uid}` ownership and all pre-existing Task 1/2 uncommitted files; only stage verified isolated hunks/files. If isolation is unsafe, record an uncommitted task result.
- Vietnamese money/date copy, light/dark theme, 320 px layout, loading/empty/error states and AuthGate protection are required.
- Export plan depends on the types/API in this plan; do not rename them without updating that plan first.

## Review Focus

- Old transaction without `walletId` must read as `cash` and appear once in balances/export: Task 1 model test, Task 4 integration.
- A transfer must change two wallet balances but neither report nor budget totals; an orphan wallet ID must not drop money from the app total: Task 1 tests, Task 4 integration.
- A user cannot read/write another UID's wallets or transfers: Task 2 rules tests.
- Deleting the default or a referenced wallet must fail without data loss: Task 2 repository test and Task 3 UI test.
- Offline/stale cached wallet lists may not prove enough funds or allow deletion; show a recoverable error, not a blank screen: Task 3 widget test.

---

## File map and dependency order

- `lib/finance/finance_models.dart`: add `FinanceWallet`, `FinanceTransfer`; `FinanceTransaction.walletId` defaults to `cash` for old docs/tests.
- `lib/finance/wallet_balances.dart`: pure `walletBalances(...)` and `totalWalletBalance(...)`, consumed by Home/wallet list/export.
- `lib/finance/finance_repository.dart`: wallet/transfer streams and mutations; transaction save persists selected wallet.
- `lib/auth/auth_service.dart`: default-wallet seed, profile stream and update.
- `firestore.rules`, `rules_test/rules.test.mjs`: UID scope and new-document validation.
- `lib/screens/wallets_screen.dart`, `lib/screens/transfer_form_screen.dart`: wallet CRUD and transfer history/create/delete.
- `lib/screens/add_transaction_screen.dart`, `lib/screens/home_screen.dart`, `lib/screens/settings_screen.dart`, `lib/app/app_routes.dart`: select wallet, derived balance, edit name and navigation.
- `test/wallet_balances_test.dart`, `test/wallets_screen_test.dart`, `test/profile_screen_test.dart`, `integration_test/wallet_flow_test.dart`: unit/widget/Android gates.

### Task 1: Model and derived balances

**Files:** Modify `lib/finance/finance_models.dart`; create `lib/finance/wallet_balances.dart`; test `test/wallet_balances_test.dart`.

**Interfaces:** `FinanceWallet(id,name,kind,openingBalance,createdAt?,updatedAt?)`, with `kind` one of `cash`, `bank`, `ewallet`, `other` and signed opening balance; `FinanceTransfer(id,fromWalletId,toWalletId,amount,date,note,createdAt?,updatedAt?)`; `FinanceTransaction.walletId` defaults to `'cash'`; `Map<String,int> walletBalances(List<FinanceWallet> wallets, List<FinanceTransaction> transactions, List<FinanceTransfer> transfers)`; `int totalWalletBalance(...)` with the same arguments. Define `const defaultWalletId = 'cash'` alongside these models.

- [ ] **Step 1: Write failing tests.** `legacy_transaction_defaults_to_cash` parses a doc missing `walletId`; `opening_income_expense_and_transfer` asserts cash opening 100000 + income 50000 − expense 20000 − transfer 30000 = 100000 and receiving wallet opening 0 + transfer = 30000; `transfer_does_not_change_report_or_budget` asserts existing `summarizeReport`/`spentForBudget` ignore transfers; `empty_wallet_list_still_exposes_virtual_cash` asserts existing account fallback; `orphan_wallet_reference_keeps_total` asserts an unknown ID stays in the balance map rather than losing its money.
- [ ] **Step 2: Verify red.** Run `flutter test test/wallet_balances_test.dart`; expect missing models/helpers, not Firebase setup errors.
- [ ] **Step 3: Implement only the named models/helpers.** Keep VND as `int`, date local, no stored mutable balance; preserve old constructor calls by optional wallet field default.
- [ ] **Step 4: Verify green.** Run `flutter test test/wallet_balances_test.dart test/finance_statistics_test.dart test/finance_rules_test.dart`; expect all PASS; `flutter analyze lib/finance` → no issues.
- [ ] **Step 5: Review/commit only isolated new files and hunks.** If `finance_models.dart` cannot be staged separately from user changes, leave it uncommitted and record why.

### Task 2: Firestore API, profile and security rules

**Files:** Modify `lib/finance/finance_repository.dart`, `lib/auth/auth_service.dart`, `firestore.rules`, `rules_test/rules.test.mjs`; test `integration_test/wallet_repository_test.dart`.

**Interfaces:** `watchWallets(): Stream<List<FinanceWallet>>` synthesizes default `cash` when absent; `watchTransfers(): Stream<List<FinanceTransfer>>`; `saveWallet({String? id, required String name, required String kind, required int openingBalance}): Future<String>`; `deleteWallet(String id): Future<void>`; `saveTransfer({required String fromWalletId, required String toWalletId, required int amount, required DateTime date, String note = ''}): Future<String>`; `deleteTransfer(String id): Future<void>`; existing `saveTransaction` gains `String walletId = 'cash'`. `AuthService.watchFullName(): Stream<String?>`; `updateFullName(String name): Future<bool>` returns whether Auth display name also synced after Firestore write; `_ensureProfile` syncs Auth name at next sign-in if needed.

- [ ] **Step 1: Write failing emulator/rules tests.** New account has document `wallets/cash`; old account without it reads virtual cash; transaction save stores chosen `walletId`; transfer rejects amount <= 0/same wallet/missing IDs; default or wallet referenced by transaction, incoming transfer or outgoing transfer cannot be deleted; User B denied read/write to User A's wallets/transfers; malformed transfer document denied; updateFullName changes Firestore and Auth, and an Auth-sync failure remains visible as partial result.
- [ ] **Step 2: Verify red.** Run `firebase emulators:exec --only auth,firestore 'flutter test integration_test/wallet_repository_test.dart -d emulator-5554' --project demo-qlct-rules` and `firebase emulators:exec --only firestore,storage 'npm --prefix rules_test test' --project demo-qlct-rules`; expect the new assertions to fail for missing APIs/rules.
- [ ] **Step 3: Implement API and rules.** Seed cash in the existing registration batch, synthesize fallback on reads, use owner-scoped collections, check references before delete; do not change old transaction documents en masse. Firestore name is authoritative; Auth-sync failure returns false and Settings can explain it.
- [ ] **Step 4: Verify green.** Repeat both emulator commands; expect all wallet/rules tests PASS; `flutter analyze lib/auth lib/finance` → no issues.
- [ ] **Step 5: Review/commit only safely isolated hunks/files.** Never wholesale-stage `finance_repository.dart`, `auth_service.dart` or Task 1/2 rules.

### Task 3: Wallet and transfer screens

**Files:** Create `lib/screens/wallets_screen.dart`, `lib/screens/transfer_form_screen.dart`, `test/wallets_screen_test.dart`; modify `lib/app/app_routes.dart`, `lib/screens/settings_screen.dart`, `lib/screens/add_transaction_screen.dart`.

**Interfaces:** `AppRoutes.wallets = '/wallets'`, `AppRoutes.transfer = '/wallets/transfer'`, both behind AuthGate; `WalletsScreen({FinanceRepository? repository})` and `TransferFormScreen({FinanceRepository? repository})` allow widget fakes. Settings wallet tile navigates to wallets; transaction form selects a wallet and passes its ID to `saveTransaction`.

- [ ] **Step 1: Write failing widget tests.** Wallet screen shows virtual cash/derived balance, add/edit/delete form validation and confirm, cannot delete cash/referenced wallet, transfer creation changes visible source/destination balances without income/expense UI, selector in transaction form persists chosen ID, and all forms have retry/no overflow at 320 px in both themes.
- [ ] **Step 2: Verify red.** Run `flutter test test/wallets_screen_test.dart test/add_transaction_screen_test.dart`; expect missing routes/widgets/selector.
- [ ] **Step 3: Build focused UI using existing `FinanceCard`, `StatePanel`, theme colors and Vietnamese labels.** Preserve existing category/date/note CRUD; no decorative or unused controls.
- [ ] **Step 4: Verify green.** Repeat targeted tests plus `flutter analyze lib/screens lib/app`; expect PASS/no issues.
- [ ] **Step 5: Review/commit only isolated new files/hunks or defer overlapping paths in the ledger.**

### Task 4: Profile, Home and Android flow

**Files:** Modify `lib/screens/settings_screen.dart`, `lib/screens/home_screen.dart`, `lib/auth/auth_service.dart`; create `test/profile_screen_test.dart`, `integration_test/wallet_flow_test.dart`.

**Interfaces:** Home combines `summarizeHome(...).balance` with wallet opening balances; transfers are net zero overall. Home and Settings display Firestore `watchFullName()` (Home's `displayName` test injection remains). Settings edit form calls `updateFullName` and explains partial Auth sync.

- [ ] **Step 1: Write failing tests.** Name edit changes both Settings/Home; invalid/empty name blocked; Firestore saved but Auth sync failed shows truthful feedback; Home total includes openings while monthly income/expense remain transaction-only; Android flow logs in old user, reads old cash transactions, creates wallet, transfers, signs out/in and retains per-UID balances.
- [ ] **Step 2: Verify red.** Run `flutter test test/profile_screen_test.dart test/home_screen_test.dart`; run `firebase emulators:exec --only auth,firestore 'flutter test integration_test/wallet_flow_test.dart -d emulator-5554' --project demo-qlct-rules`; expect missing profile/balance flow.
- [ ] **Step 3: Implement only these presentation/data-flow changes.** Keep AuthGate and existing route results; no rename of unrelated screen copy.
- [ ] **Step 4: Verify green.** Repeat targeted/widget/Android tests; `flutter analyze` → no issues; verify `git diff --check`.
- [ ] **Step 5: Review/commit isolated changes if safe; record uncommitted overlaps.** Leave branch and all Task 1/2 user edits intact.
