# PROGRESS — session log (update start + end of every session)

| Phase | Branch | Status | Validation | Commit |
|-------|--------|--------|------------|--------|
| 0 foundation | `feature/00-foundation` | done | #0 ✅ 2026-09-04 | 79d2190 + verify commit |
| 1 customization core | `feature/01-custom-core` | done | Flex ✅ 2026-09-04 | see below |
| 2 transactions | `feature/02-transactions` | done | #1 ✅ 2026-09-07 | see below |
| 3 budgets | `feature/03-budgets` | done | #2 ✅ 2026-09-08 | see below |
| 4 neutral | `feature/04-neutral` | done | #3 ✅ 2026-09-08 | Debts table (migration v2) + repo + UI |
| 5 splits | `feature/05-splits` | done (unreleased, bundles into v0.4.0) | #4 ✅ 2026-09-08 | Splits table (migration v3) + repo + UI |
| 6 instruments | `pr/06-instruments` | done, verified | #5 ✅ 2026-09-11 | Instruments table (v4) + repo + UI + phase6_test, 51/51 + analyze clean |
| 7 reconcile+price+networth | `pr/07-reconcile` | done, verified | #6/#6b/#6c ✅ 2026-09-11 | Snapshots table (v5) + report + price + networth + phase7_test, 59/59 + analyze clean |
| 8 reports | `pr/08-reports` | done, verified | #7 ✅ 2026-09-11 | reports_logic + repo + dashboard + drill + phase8_test, 65/65 + analyze clean |
| 9 intake+cash+quick | `pr/09-intake` | done, verified | Intake×2/Cash/Quick ✅ 2026-09-11 | parser+confirm+transfer+filter+quickadd + phase9_test, 72/72 + analyze clean |
| 10 backup+security | `pr/10-backup-security` | done, verified | #8/#9 ✅ 2026-09-11 | settings table (v6) + PIN/decoy/autolock + encrypted ZIP + settings UI + phase10_test, 78/78 + analyze clean |
| 11 hardening | `pr/11-hardening` | done, verified | full gate green | crash guard + release signing template + 0.9.0+9, 78/78 + analyze clean |

## 2026-09-04 — Phase 0 verify / `feature/00-foundation` (Flutter installed, tests green)
- Planned: install Flutter SDK, `flutter pub get`, `flutter test`, flip #0 green.
- Done: cloned Flutter stable → 3.47.2 (Dart 3.13.2); `flutter pub get` 143 deps OK; `flutter test` 8/8 pass; standalone `tool/verify_core.dart` 15/15 asserts pass (parser/ledger/share incl. blank + zero guards); kept flutter's `analysis_options.yaml` analyzer exclude; added `pubspec.lock` + `tool/`.
- Validation: #0 ✅ 2026-09-04.
- Next: merge `feature/00-foundation` → `develop` (local only, never push `main`); start Phase 1 `feature/01-custom-core` (Drift schema v1 + lookups).

## 2026-09-03 — Phase 0 / `feature/00-foundation` (scaffold)
- Planned: git init, docs (PLAN/VALIDATION/PROGRESS), Flutter skeleton, lock shell + category parser + test.
- Done: git init (`main`/`develop`/`feature/00-foundation`); docs written; skeleton + parser written (unverified — no Flutter SDK in env).
- Validation: #0 TODO (needs `flutter test` once SDK installed).
- Next: install Flutter SDK → `flutter pub get` → `build_runner` → `flutter test` → commit → merge to develop.
- Env note: `flutter`/`dart` not found in this machine. Scaffold hand-written, not compiled.

## 2026-09-04 — Push / `develop` + `feature/00-foundation` (remote wired, main untouched)
- Done: `gh auth` confirmed (Rajathk6); pushed `develop` (8af3cf4) + `feature/00-foundation` (ab3f7c7) to github.com/Rajathk6/ExpenseTracker. Remote has only those two refs — `main` never pushed per rule.
- Next: Phase 1 `feature/01-custom-core`.

## 2026-09-04 — CI gate + Phase 1 / `feature/ci-main-gate` + `feature/01-custom-core`
- CI: `.github/workflows/ci.yml` (analyze+test on PRs to main/develop, pushes to develop; Flutter 3.47.2 pinned). `main` bootstrapped from green develop (one-time), protected: PR-only (0 approvals, solo-mergeable), strict `ci / analyze` + `ci / test`, enforce_admins, no force-push. Direct-push probe rejected by hook as expected.
- Phase 1 done: Drift schema v1 (accounts/transactions/budgets) + `database.g.dart`; repositories (Account/Budget/Transaction) + `bucket_math` (presets, sum=100 validation, allocate); Riverpod providers. `flutter test` all pass, `flutter analyze` clean.
- Codegen gotchas: (a) column getter must not shadow Drift builders (`dateTime` → `occurredAt`); (b) dropped DB-level `.references()` FK (drift_dev/analyzer-14 conflict), discipline in repos; (c) `sqlite3` added as direct dep for UNIQUE mapping.
- Validation: Flex ✅ 2026-09-04 (data layer + tests; entry UI in later phases).
- Next: Phase 2 transactions UI. PR #1 (develop→main) open, CI green, awaiting your merge call.

## EOD 2026-09-04 — Phase 2 WIP paused / `feature/02-transactions` (pushed, NOT merged)
- Done: entry UI + list + item search committed (07f8b30); `flutter test` 26/26 green, `flutter analyze` clean. Android shell generated (`dev.rajath.expense_tracker`); Java 17 at `~/jdk-17`; cmdline-tools zip saved at `~/android-cmdtools.zip` (moved out of /tmp so it survives reboot).
- NOT done: SDK install, debug APK build, CI apk-proof job, versioning docs, VALIDATION #1 flip, merge to develop.
- Resume tomorrow: (1) unzip cmdtools → `~/android-sdk`, sdkmanager install platform/build-tools, licenses; (2) `flutter build apk --debug`; (3) CI apk job + release process; (4) flip #1, merge, push, watch CI.

## 2026-09-07 — Phase 2 done + first APK / `feature/02-transactions`
- Env: Java 17 Temurin `~/jdk-17`, Android SDK 36 `~/android-sdk` (cmdline-tools + platform-tools + platforms 34/35/36 + build-tools 36.0.0), `flutter doctor` Android toolchain ✓. Gradle safety: IPv4-preferred, no parallel, long timeouts (`~/.gradle/gradle.properties`, machine-local).
- APK: `flutter build apk --debug` ✅ → `app-debug.apk` (aapt-verified: dev.rajath.expense_tracker, v0.1.0+1, SDK 36, debuggable).
- Fights won: (a) Maven Central flakes → retry loop; (b) rsi 1.9/file-storage 11.x need unpublished compileSdk 37; (c) share_plus 13.3.0 upstream Kotlin breakage; (d) old-plugin JVM-target clash. Fix: trimmed Phase 9/10-only native deps (share/file/auth/OCR/widget/Drive) — zero Dart usages, pure-Dart logic stays; re-added at their phases. compileSdk stays on Flutter pin 36, no hacks.
- CI: `apk-debug` job added (PRs to main, artifact 14d); `main` now requires analyze+test+apk-debug. Release process in PLAN.md (version+tag per main merge, debug-signed for personal use).
- Validation: #1 ✅ 2026-09-07.
- Next: Phase 3 budgets UI (`feature/03-budgets`). PR #1 triple-check done 2026-09-07: analyze ✅ ~45s, test ✅ ~48s, apk-debug ✅ ~4m10s (artifact uploaded). Awaiting your merge call for first versioned `main`.

## 2026-09-08 — v0.1.0 released / `main` + tag + GitHub Release
- PR #1 merged to `main` (659dafb). Gate fix found by execution: protection matches BARE check-run names (`analyze`, not `ci / analyze`) — updated. Direct-push probe rejected again post-merge; PR-review rule (0 approvals) restored.
- Release: tag `v0.1.0` → Release published with `app-arm64-v8a-release.apk` (20MB) + `app-armeabi-v7a-release.apk` (18MB), debug-signed, offline-first. Uplink is very slow (~50KB/s); large uploads need patience or split ABIs (lesson: always `--split-per-abi` for releases).
- Next: pending works list below.

## 2026-09-08 — v0.2.0 released / PR #2 merged + tag + GitHub Release
- Version bump 0.2.0+2 on develop; CI re-ran: apk-debug upload flaked once (artifact 403) → `--failed` re-run green. PR #2 merged (1000c57), tag `v0.2.0`, Release published with arm64 (20.6MB) + armeabi (17.9MB) split release APKs, debug-signed.
- x86_64 still pending upload (slow uplink); attach any time.

## 2026-09-08 — Phase 4 neutral/aging done / `feature/04-neutral`
- Debts table (schema v2 migration) + DebtRepository (lend/borrow, partial payoffs, overpay rejected, auto-settle) + pure aging/overdue/nudge math.
- Debts UI: open contracts with progress + aging badges, payoff dialog, money trail, settled archive. Handshake entry in Transactions bar.
- Neutral invariant proven by test: May lend 5000 → outActual -5000 but outBudget 0; June partial → inActual +2000, inBudget 0; full payoff → settled, trail nets 0.
- `flutter test` 38/38 green, `flutter analyze` clean.
- Validation: #3 ✅ 2026-09-08.
- Next: merge to develop, PR #3, v0.3.0 on your call, then Phase 5 splits.

## 2026-09-08 — CI relaxed + EOD pause / `develop`
- Decision: CI triple gate was costing more wait than value at this stage. Required status checks REMOVED from `main` protection (workflow files stay, free to re-enable). `main` still PR-only (0 approvals) + no force-push + no direct push.
- PR #3 (Phase 4 → main) left OPEN, unmerged — merge + v0.3.0 release tomorrow if phone test passes.
- Next: pending works list below (Phase 4 needs release before phone testing).

## 2026-09-08 — v0.3.0 released / PR #3 merged + tag + GitHub Release
- Version bump 0.3.0+3 on develop; PR #3 merged (f5cb765, no CI wait per relaxed gate); tag `v0.3.0`; Release published with arm64 (20.6MB) + armeabi (18.0MB), debug-signed.
- x86_64 still pending upload (slow uplink); attach any time.

## 2026-09-08 — Phase 5 splits done / `feature/05-splits`
- Splits table (schema v3 migration) + SplitRepository (front/settle/absorb) + pure settle-up optimizer.
- Splits UI: open recovery progress, settle/absorb dialogs, money trail, closed archive, equal-split helpers. Group entry in Transactions bar.
- Honesty model proven by test: front 1000/100 → bank -1000 but budget -100; +600 recovered → net -400 bank; 300 defaulted → absorb (actual 0, budget -300) → budget -400, contract closed.
- Gotchas: over-settle cap must exclude my share (fixed before merge); drift `Split` clashes with Flutter's — `hide Split` on material import.
- `flutter test` 43/43 green, `flutter analyze` clean.
- Validation: #4 ✅ 2026-09-08.
- Next: merge to develop, PR, v0.4.0 on your call, then Phase 6 instruments.

## PENDING WORKS (remaining, in order)
1. **x86_64 APK** — built locally (`app-x86_64-release.apk`, 22MB, emulator-only) but upload kept timing out on the slow uplink. Attach to v0.1.0 later via `gh release upload v0.1.0 build/app/outputs/flutter-apk/app-x86_64-release.apk`. Not needed for real phones.
2. **Phone findings (fixed 2026-09-08):** (a) only Cash source → new Accounts manager (add/rename/delete, freeform kinds), reachable from Transactions AppBar; entry banner kept for first run. (b) search felt broken → it only matched hyphenated items; now matches raw category + any level + item, with empty-query item browser + stats drill-down kept.
3. **Phase 4 neutral/aging** — IN PROGRESS (`feature/04-neutral`).
4. **Phases 4–11** per PLAN.md (neutral/aging → splits → instruments → reconcile/prices/net-worth → reports → intake → backup/security → hardening).
5. **Phase 9/10 native deps** — share/file/auth/OCR/widget/Drive re-added at their phases (trimmed 2026-09-07, zero Dart usages affected).
6. **Release signing** (Phase 10/11) — replace debug signing with a personal keystore + `release` CI job.

## 2026-09-08 — Phase 3 budgets + phone fixes / `feature/03-budgets`
- Accounts manager (add SBI/bank/card with freeform kind, rename, delete) + AppBar entry points (Accounts, Search, Budgets).
- Search now matches raw/levels/item; empty query browses items with stats drill-down.
- Budget screen: month nav, total + dynamic N-bucket editor, presets, validation, planned allocation chips, spend-vs-budget progress, 3-month simulator with preset switcher.
- `flutter test` 32/32 green, `flutter analyze` clean.
- Validation: #2 ✅ 2026-09-08.
- Next: merge to develop, watch CI, cut v0.2.0 release on your call.

## 2026-09-11 — Phase 6 instruments code-complete / `feature/06-instruments` (code-only, no local toolchain)
- Decisions per owner: skip standalone v0.4.0 splits release (bundle 5+6 into next APK); code-only here, APK built later on dev machine; write tests but don't execute locally.
- Done: `Instruments` table (schema v4 migration) + `instrument_logic` (P/L, SI/compound, totals, validation) + `InstrumentRepository` (create/revalue/edit/archive/restore/delete) + `InstrumentsScreen` (totals header, SI preview, open/archived, revalue) + providers + AppBar entry + `test/phase6_test.dart` + version bump 0.4.0+4.
- NOT done (no Flutter/Java/Android SDK on this machine): `flutter pub run build_runner build --delete-conflicting-outputs` to regen `database.g.dart`, `flutter analyze`, `flutter test`, APK build. Run these on the dev machine before merging.
- Validation: #5 🟡 code-complete (vault + P/L% + interest + tests written, verification pending).
- Next: dev-machine verify (codegen → analyze → test) → merge to develop → APK → then Phase 7 reconcile+pricememory+networth.

## 2026-09-11 — Phase 7 reconcile+price+networth code-complete / `feature/07-reconcile` (code-only, no local toolchain)
- Branch ops: merged `feature/06-instruments` → local `develop` (no push; `main`/origin untouched), branched `feature/07-reconcile`.
- Done: `Snapshots` table (schema v5, PK month+account, `openBalance` naming dodges the Drift-builder clash) + `reconcile_logic` (month keys, expected/gap/status) + `ReconcileRepository` (setOpen/setClose/report incl. unassigned-ledger row) + `ReconcileScreen` (month nav, per-account cards, cash-count hint, true-spent + gap header) + `price_logic`/`PriceScreen` (avg/min/max + overpay over existing item history, no new table) + `networth_logic`/`NetWorthScreen` (12-mo timeline + fl_chart, honest current-value limitation noted) + `TransactionRepository.all()` + providers + Transactions "More" menu + `test/phase7_test.dart` + version 0.5.0+5 (next release bundles 5+6+7).
- NOT done (no Flutter here): `build_runner` regen for v4+v5 tables, `flutter analyze`, `flutter test`, APK build. Same dev-machine gate as Phase 6.
- Validation: #6/#6b/#6c 🟡 code-complete, verification pending.
- Next: dev-machine verify both phases → merge to develop → APK → then Phase 8 reports.

## 2026-09-11 — Phase 8 reports code-complete / `feature/08-reports` (code-only, no local toolchain)
- Branch ops: merged `feature/07-reconcile` → local `develop` (no push; `main`/origin untouched), branched `feature/08-reports`.
- Done: `core/months.dart` (shared keys; re-exported by reconcile_logic so old imports keep working) + `reports_logic` (sums/topSlices/pickTop/cash-digital, pure) + `ReportsRepository` (one-shot `dashboard()` + `wrapped()`, core DB only — no feature-feature imports) + `ReportsScreen` (6-mo trend line, tappable category bars + rows, cash-vs-digital, budget-vs-actual, wrapped card, drill screen with exact rows) + providers + Transactions "More" menu entry + `test/phase8_test.dart` + version 0.6.0+6 (next release bundles 5+6+7+8).
- Schema: NO new tables — Phase 8 needs no `build_runner` of its own (v4+v5 regen from 6+7 still pending).
- Validation: #7 🟡 code-complete, verification pending.
- Next: dev-machine verify → merge to develop → APK → then Phase 9 intake+quickadd.

## 2026-09-11 — Phase 9 intake+cash+quick code-complete / `feature/09-intake` (code-only, no native deps added)
- Branch ops: merged `feature/08-reports` → local `develop` (no push; `main`/origin untouched), branched `feature/09-intake`. Also fixed `price_screen` dropdown to `initialValue` (matches Flutter 3.47 API used in entry_sheet).
- Done: share_parser merchant-`to X` guess + in/out kind hint + `parseOcrText` alias + `IntakeScreen` confirm (paste/share text → editable amount/category/account → offline save, `initialText` hook for share-target) + `TransactionRepository.transfer` (dual rows, shared linkId, budget 0) + `TransferSheet` (from/to + quick amounts) + `QuickAddSheet` + `openQuickAdd()` (cash-first account) + All/Cash/Digital filter chips on Transactions + `test/phase9_test.dart` + 0.7.0+7.
- Deliberately NOT added (needs dev-machine native verification): share_plus/receive-sharing-intent, google_mlkit_text_recognition (or equivalent), home_widget. Dev-machine wiring: (1) add plugin, `flutter pub get`, (2) pass shared text/OCR output into `IntakeScreen(initialText:)`, (3) widget button → MethodChannel → `openQuickAdd()`. Parser + confirm already handle the rest.
- Validation: Intake/Intake-img/Cash/Quick 🟡 code-complete, verification pending.
- Next: Phase 10 backup+security, then 11 hardening — still no release per owner.

## 2026-09-11 — Phase 10 backup+security code-complete / `feature/10-backup-security` (code-only, no native deps added)
- Branch ops: merged `feature/09-intake` → local `develop` (no push; `main`/origin untouched), branched `feature/10-backup-security`.
- Done: `Settings` table (schema v6) + `pin_service` (6-digit + decoy, salted SHA-256, lock minutes) + lock gate v2 (verdicts, demo-vault flag, idle timer) + real/demo DB split (`databaseProvider` swaps handles; main opens both files; resume refreshes countdown) + PIN-pad `LockScreen` (first-run setup, wrong-PIN error) + `codec` (JSON→ZIP→AES-GCM/PBKDF2, clean wrong-password error) + `BackupService` (dump/restore all 8 tables, .etbak export, path-based import) + `SettingsScreen` (PIN/decoy/auto-lock/export/restore/about) + More-menu entry + `test/phase10_test.dart` + 0.8.0+8.
- Deliberately NOT added (dev-machine native steps): local_auth (biometric button explains), flutter_secure_storage (hashes live in Settings meanwhile), file_picker (import takes a pasted path), google Drive API (manual Files-app upload per PLAN), SQLCipher (eval: file DB + encrypted exports cover the offline model until the signed release).
- Validation: #8/#9 🟡 code-complete, verification pending (needs v6 codegen + `flutter test`).
- Next: Phase 11 hardening — still no release per owner.

## 2026-09-11 — Phase 11 hardening code-complete / `feature/11-hardening` (code-only, NO release per owner)
- Branch ops: merged `feature/10-backup-security` → local `develop` (no push; `main`/origin untouched), branched `feature/11-hardening`.
- Done: `main.dart` crash guard (`ErrorWidget` fallback card + `runZonedGuarded` → FlutterError) + release signing template in `android/app/build.gradle.kts` (uses `key.properties` when present, debug keys otherwise — dev builds never break) + perf note on the unbounded net-worth read + 0.9.0+9.
- One-time signing setup (dev machine, never committed): `keytool -genkey -v -keystore ~/expense-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias expense`, then create `android/key.properties` with `storeFile/keyAlias/keyPassword/storePassword` (git-ignored). Then `flutter build apk --release --split-per-abi`.
- Full verify gate (dev machine, all phases 5–11): `flutter pub get` → `flutter pub run build_runner build --delete-conflicting-outputs` (regens v4+v5+v6 tables) → `flutter analyze` → `flutter test` → `flutter build apk --debug` → phone pass over VALIDATION rows #4–#9 + Intake/Cash/Quick → merge develop→main → tag + GitHub Release with split APKs.
- Known review hotspots for that pass: fl_chart touch callback signatures (reports), AES/PBKDF2 + archive APIs (backup codec), `toCompanion(true)` round-trips (backup restore), decoy DB-handle swap, `initialValue` dropdown API.
- Next: run the gate above, cut the release on your call. Phases 5–11 all code-complete; nothing was pushed — `git push origin develop feature/06-instruments feature/07-reconcile feature/08-reports feature/09-intake feature/10-backup-security feature/11-hardening` when ready (or open PRs per phase as before).

## 2026-09-11 — Full verification pass, one PR per phase / `pr/06`→`pr/11` (Flutter 3.47.2 installed here)
- Env: Flutter 3.47.2 + Dart 3.13.2 installed at `D:\flutter` (this Windows machine). No Java/Android SDK — APK builds still pending.
- Caught by execution: (1) `IntColumn get hasClose => int()` crashes drift_dev codegen (`int()` is not a builder — must be `integer()`; same family as the old `dateTime` gotcha, now fixed in Phase 7). (2) `DropdownButtonFormField(value:)` is deprecated in Flutter 3.47 — `initialValue` (as in entry_sheet) is correct. (3) Hand-written backup restore comprehension was a syntax error. All fixed; `flutter analyze` is clean on every branch.
- Rebuilt history as a clean stack off `origin/develop`: `pr/06-instruments` → `pr/07-reconcile` → `pr/08-reports` → `pr/09-intake` → `pr/10-backup-security` → `pr/11-hardening`, each with its own schema codegen (v4/v5/v6) committed. Old local `feature/*` + `develop` merges superseded (kept under `backup/pre-pr-rebuild` until the PRs land).
- Verified per branch (`flutter analyze` + `flutter test`): 06: 51/51, 07: 59/59, 08: 65/65, 09: 72/72, 10: 78/78, 11: 78/78 — all green, VALIDATION fully ✅.
- Next: 6 PRs (`pr/*` → `develop`, merge in order with merge commits, NOT squash — stacking depends on ancestry), then APK + phone pass + release on your call.

## 2026-09-11 — Catch-up: external PR stack verified, merged, v0.9.0 released / `develop` + `main`
- Reviewed `session-ses_f70e.md` + 7 open PRs (#4–#10). Found a clean stack from fork `Rajathk74`: pr5(Phase 6) → pr6(7) → pr7(8) → pr8(9) → pr9(10) → pr10(11), each on the previous; head branches deleted post-push, fetched via `pull/N/head`.
- Verified the stack tip locally (this machine): `flutter test` 78/78 green, `flutter analyze` clean, version 0.9.0+9, schema v6. Dropped my redundant local Phase 6 draft (stashed, then deleted after green).
- Merged #5→#10 into `develop` in order (merge commits), retitled #4 to Phases 5–11, merged to `main` (78d783e), tag `v0.9.0`, Release published with arm64 (21.5MB) + armeabi (19.1MB) split release APKs (aapt-verified 0.9.0, debug-signed).
- Gate fix found by execution: protection matches BARE check-run names (`analyze`, not `ci / analyze`).
- Next: phone-test v0.9.0; remaining ideas (x86_64 upload, release signing, re-enable CI) on your call.

## How to update
Append a dated section per session. Flip Status todo→doing→done only with VALIDATION row green.
