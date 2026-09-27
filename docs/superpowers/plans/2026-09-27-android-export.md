# Android PDF and XLSX Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the report export placeholder with real Vietnamese PDF/XLSX files and Android share/save UI.

**Architecture:** Build one immutable, pure-Dart report snapshot from the current UID's transactions, transfers and wallet names; two renderers consume it. The Flutter screen chooses range/format, writes a temporary file and invokes Android's chooser. No cloud export service or broad storage permission.

**Tech Stack:** Flutter/Dart, `pdf` 3.13.1, `excel_community` 2.4.0, `share_plus` 13.3.0, `file_saver` 0.6.0, `path_provider` 2.1.6; bundle a licensed Unicode TTF for Vietnamese PDF. Version/compatibility references: [pdf](https://pub.dev/packages/pdf), [excel_community](https://pub.dev/packages/excel_community), [share_plus](https://pub.dev/packages/share_plus), [file_saver](https://pub.dev/packages/file_saver), [path_provider](https://pub.dev/packages/path_provider).

**Spec:** `docs/superpowers/specs/2026-09-27-android-completion-design.md`

## Global Constraints

- Execute the wallet/profile plan first; use its `FinanceWallet`, `FinanceTransfer`, `FinanceTransaction.walletId` and default `cash` contracts unchanged.
- Android only for file creation/sharing; shared Dart analysis and other platform builds must not be broken.
- No Firebase Storage, image/receipt feature, server export, paid service or fabricated success message.
- Export amounts remain integer VND; dates and displayed text are Vietnamese; transfer entries never affect thu/chi totals.
- Existing Task 1/2 edits are user-owned. Stage isolated new files/hunks only, otherwise leave safely uncommitted.

## Review Focus

- Dates at start/end boundaries and across months/years must enter exactly one export range: Task 1 test.
- Old `walletId`-less transactions must show “Tiền mặt”, not a blank wallet: Task 1 test.
- A transfer must appear in its separate section without changing net thu−chi: Task 1 and renderer tests.
- Vietnamese diacritics, high-value VND cells and a user note starting `=` must survive PDF/XLSX as text/data, not be evaluated as an Excel formula: Task 2 round-trip/manual Android open checks.
- Android chooser dismissal or write failure must not say the export was saved, and temporary files must not be deleted before sharing: Task 3 widget/integration tests.

---

## File map

- `lib/finance/report_export_data.dart`: date filtering and `ReportExportData` with totals, category rows, transaction/transfer rows and wallet-name mapping.
- `lib/finance/report_exporter.dart`: PDF and XLSX bytes from the same snapshot; uses one bundled Unicode font in `assets/fonts/` (with license).
- `lib/screens/reports_screen.dart`: export sheet and progress/error UI; existing charts/stats remain.
- `lib/finance/report_file_share.dart`: Android temporary-file write, cleanup of older export files, share chooser and Save As adapters.
- `pubspec.yaml`, `pubspec.lock`: only the five named dependencies and font asset.
- `test/report_export_data_test.dart`, `test/report_exporter_test.dart`, `test/reports_screen_test.dart`, `integration_test/export_flow_test.dart`: evidence.

### Task 1: Stable export snapshot

**Files:** Create `lib/finance/report_export_data.dart`, `test/report_export_data_test.dart`.

**Interfaces:** `ReportExportData buildReportExportData({required DateRange range, required List<FinanceTransaction> transactions, required List<FinanceTransfer> transfers, required List<FinanceWallet> wallets})`. Its public fields are `range`, `transactions`, `transfers`, `walletNames`, `income`, `expense`, `net`, `categories`. End date is exclusive, like `DateRange.contains`.

- [ ] **Step 1: Write failing tests.** `range_half_open_across_year` includes Dec 31 but excludes Jan 1; `empty_range_zero_totals`; `transfer_is_separate_and_net_unchanged`; `old_transaction_uses_cash_name`; `category_total_uses_expenses_only` with exact VND integer assertions.
- [ ] **Step 2: Verify red.** `flutter test test/report_export_data_test.dart` → missing helper/type failure.
- [ ] **Step 3: Implement the named builder.** Reuse existing `DateRange`, category grouping and format helpers; no second transaction query or duplicated percentage arithmetic.
- [ ] **Step 4: Verify green.** Repeat targeted test and `flutter analyze lib/finance/report_export_data.dart` → PASS/no issues.
- [ ] **Step 5: Review/commit isolated new files only.**

### Task 2: Real PDF and XLSX bytes

**Files:** Create `lib/finance/report_exporter.dart`, `test/report_exporter_test.dart`, `assets/fonts/NotoSans-Regular.ttf`, `assets/fonts/OFL.txt`; modify `pubspec.yaml`, `pubspec.lock`.

**Interfaces:** `Future<Uint8List> renderPdf(ReportExportData data)` and `Uint8List renderXlsx(ReportExportData data)`; table columns ngày/loại/danh mục/ví/số tiền/ghi chú; separate transfers section; filename helper `String reportFileName(DateRange range, String extension)` uses `range.start` and the inclusive day before `range.endExclusive`, e.g. Sep 1–30 → `bao_cao_chi_tieu_2026_09_01_2026_09_30.pdf`.

- [ ] **Step 1: Write failing tests.** `renderPdf` yields `%PDF` bytes, at least one page and embedded Unicode font; `renderXlsx` round-trips Vietnamese labels, 1,250,000 numeric value, a note `=1+1` as literal text and separate transfer sheet through `Excel.decodeBytes`; empty snapshot still has zero totals; 200 rows paginate rather than clip; filename uses boundaries in local dates.
- [ ] **Step 2: Verify red.** `flutter test test/report_exporter_test.dart` → missing renderers.
- [ ] **Step 3: Add only the named packages/assets and implement renderers.** Verify font redistribution license; use `pw.MultiPage` for long PDF tables, worksheet numeric cells for amounts and text for dates; avoid `PdfGoogleFonts` runtime network fetch. Confirm resolved versions via `flutter pub get` before coding against APIs.
- [ ] **Step 4: Verify green.** Repeat targeted test, `flutter analyze` and `flutter build apk --debug`; open a generated sample PDF/XLSX on Android or with local readers to check actual text, not only magic bytes.
- [ ] **Step 5: Review/commit isolated dependencies/assets/renderers if safe.** Existing pubspec changes must be preserved.

### Task 3: Android export flow

**Files:** Create `lib/finance/report_file_share.dart`, `integration_test/export_flow_test.dart`; modify `lib/screens/reports_screen.dart`, `test/reports_screen_test.dart`.

**Interfaces:** `Future<ShareResultStatus> shareReportFile({required Uint8List bytes, required String fileName, required String mimeType})`; `Future<String?> saveReportFile({required Uint8List bytes, required String fileName, required String extension, required MimeType mimeType})` uses Android Save As and returns null on cancellation. Export sheet selects inclusive start/end UI dates, converts to `DateRange(start, DateTime(end.year,end.month,end.day+1))`, chooses PDF/XLSX, then offers separate Lưu and Chia sẻ actions.

- [ ] **Step 1: Write failing tests.** Sheet defaults current month, rejects end-before-start, allows custom date/year boundary, shows busy and error states, never shows “saved” on Save As/share chooser dismiss, creates a real correctly named file and invokes the requested Android chooser; screen with empty transactions exports zeros rather than crashing.
- [ ] **Step 2: Verify red.** `flutter test test/reports_screen_test.dart` and Android `integration_test/export_flow_test.dart` → placeholder/missing chooser failures.
- [ ] **Step 3: Implement export UI/file adapter.** Use app temporary directory and `SharePlus.instance.share(ShareParams(files: [XFile(...)], ...))` for sharing, `FileSaver.instance.saveAs(...)` for explicit Android Save As; prune only prior export files at the next start, never arbitrary temp files; handle platform permission/file errors in Vietnamese.
- [ ] **Step 4: Verify green.** Repeat widget/Android tests, `flutter analyze`, `flutter test`; `flutter run -d emulator-5554` and manually inspect Android chooser/file content.
- [ ] **Step 5: Review/commit isolated files/hunks or record deferment for overlapping Reports path.**
