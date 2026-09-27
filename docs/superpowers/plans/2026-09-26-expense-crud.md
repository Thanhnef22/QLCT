# Finance CRUD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace demo transaction/category/budget UI with per-user Firestore CRUD and live financial summaries.

**Architecture:** Typed finance models and one Firestore repository own schema, UID scoping and mutations. Flutter screens retain Material widgets, `StreamBuilder` and local `setState`; filters and calculations stay pure and testable.

**Tech Stack:** Flutter/Dart, Firebase Auth, Cloud Firestore, Firebase Emulator Suite.

**Spec:** `docs/superpowers/specs/2026-09-26-expense-crud-design.md`

## Global Constraints

- Preserve Task 1 Auth and owner-only Firestore rules; never hardcode a UID.
- Store integer VND; use Vietnamese copy and `dd/MM/yyyy`, `Tháng M, yyyy`, `yyyy-MM` month keys.
- No new state-management or formatting dependency; no report/export/upload feature.
- Existing Task 1 working-tree changes are user-owned; work in place and do not commit mixed changes.

## Review Focus

- Empty/zero/negative amount is rejected before Firestore writes.
- A category in use cannot be deleted or changed to the other type.
- One budget per `(month, categoryId)`; duplicate create must not overwrite an existing budget.
- Editing a transaction moves its spend between months/categories correctly.
- Signing in as another UID must not expose the first user's records.

---

### Task 1: Finance values and pure rules

**Files:** Create `lib/finance/finance_models.dart`, `lib/finance/finance_format.dart`, `lib/finance/finance_rules.dart`; test `test/finance_rules_test.dart`.

**Interfaces:** `FinanceCategory`, `FinanceTransaction`, `FinanceBudget`; `formatVnd(int)`, `formatDate(DateTime)`, `formatMonth(DateTime)`; `parseVnd(String)`, `monthKey(DateTime)`, `budgetStatus(int spent,int limit)`, `spentForBudget(...)`, `filterTransactions(...)`.

- [ ] Write tests for 1.250.000 ₫, 26/09/2026, Tháng 9, 2026, invalid amount, budget thresholds and month/category filters.
- [ ] Run `flutter test test/finance_rules_test.dart`; confirm failure from absent behavior.
- [ ] Implement the smallest pure model/format/rule code that passes.
- [ ] Run focused test and full `flutter test`; expect pass.

### Task 2: UID-scoped Firestore CRUD

**Files:** Create `lib/finance/finance_repository.dart`; modify `integration_test/auth_flow_test.dart` or create `integration_test/finance_crud_test.dart`.

**Interfaces:** `FinanceRepository({FirebaseAuth? auth,FirebaseFirestore? firestore})`; streams for categories, transactions and budgets; methods to create/update/delete each entity, with category-use and budget-duplicate guards.

- [ ] Write emulator integration tests for all CRUD paths, duplicate budget, category-in-use and two-UID isolation.
- [ ] Run targeted integration test; confirm missing behavior fails.
- [ ] Implement the repository using `users/{currentUid}/...`, server timestamps, category snapshots and deterministic budget IDs.
- [ ] Run integration test; expect pass. Run `flutter test`; expect pass.

### Task 3: Transaction UI and navigation

**Files:** Modify `lib/screens/add_transaction_screen.dart`, `transactions_screen.dart`, `transaction_detail_screen.dart`, `home_screen.dart`, `lib/widgets/transaction_tile.dart`, `lib/app/app_routes.dart`; test `test/transaction_ui_test.dart`.

**Interfaces:** Detail/edit routes receive transaction ID; form uses repository; list filters locally and displays live data.

- [ ] Write widget/pure-filter tests for validation, empty UI and search/filter behavior; run to see failure.
- [ ] Implement add/edit/delete/detail/list UI with Vietnamese loading/error/empty states and current-user data.
- [ ] Run focused tests and `flutter analyze`; expect pass.

### Task 4: Category UI

**Files:** Create `lib/screens/categories_screen.dart`; modify `lib/screens/settings_screen.dart`, `lib/app/app_routes.dart`; test `test/categories_ui_test.dart`.

**Interfaces:** Settings tile opens categories; tabs show expense/income; dialogs add/edit/delete with safeguards.

- [ ] Write UI tests for tab/empty/form validation and blocked delete; confirm failure.
- [ ] Implement screen, form and route using the repository and existing theme.
- [ ] Run focused tests and `flutter analyze`; expect pass.

### Task 5: Budgets, home summary and final verification

**Files:** Modify `lib/screens/budgets_screen.dart`, `home_screen.dart`, `reports_screen.dart`; test `test/budgets_ui_test.dart` and focused finance rules tests.

**Interfaces:** Budget list/month picker/form use repository; spend and status derive from live transactions; Home sums real transactions/budgets; Reports is explicitly labeled demo.

- [ ] Write tests for live spend totals and all status boundaries; confirm failure.
- [ ] Implement budget CRUD, month filtering, summary and state views.
- [ ] Run `flutter pub get`, `flutter analyze`, `flutter test`, emulator integration/rules tests and `flutter run -d emulator-5554`; expect no failures.
- [ ] Review diff against the spec and report any remaining limits honestly.
