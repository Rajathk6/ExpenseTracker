# PROGRESS — session log (update start + end of every session)

| Phase | Branch | Status | Validation | Commit |
|-------|--------|--------|------------|--------|
| 0 foundation | `feature/00-foundation` | done | #0 ✅ 2026-09-04 | 79d2190 + verify commit |
| 1 customization core | `feature/01-custom-core` | done | Flex ✅ 2026-09-04 | see below |

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
## How to update
Append a dated section per session. Flip Status todo→doing→done only with VALIDATION row green.
