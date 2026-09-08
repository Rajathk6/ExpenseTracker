# PROGRESS — session log (update start + end of every session)

| Phase | Branch | Status | Validation | Commit |
|-------|--------|--------|------------|--------|
| 0 foundation | `feature/00-foundation` | done | #0 ✅ 2026-09-04 | 79d2190 + verify commit |
| 1 customization core | `feature/01-custom-core` | done | Flex ✅ 2026-09-04 | see below |
| 2 transactions | `feature/02-transactions` | done | #1 ✅ 2026-09-07 | see below |

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

## PENDING WORKS (remaining, in order)
1. **x86_64 APK** — built locally (`app-x86_64-release.apk`, 22MB, emulator-only) but upload kept timing out on the slow uplink. Attach to v0.1.0 later via `gh release upload v0.1.0 build/app/outputs/flutter-apk/app-x86_64-release.apk`. Not needed for real phones.
2. **Download + smoke-test the APK on your phone** — install arm64 build, create Cash wallet, add one in/out entry. Report any crash/misbehavior → becomes Phase 2 fix before Phase 3.
3. **Phase 3 budgets UI** (`feature/03-budgets`) — monthly CRUD, N-bucket editor + simulator, budget-vs-actual screen. VALIDATION #2.
4. **Phases 4–11** per PLAN.md (neutral/aging → splits → instruments → reconcile/prices/net-worth → reports → intake → backup/security → hardening).
5. **Phase 9/10 native deps** — share/file/auth/OCR/widget/Drive re-added at their phases (trimmed 2026-09-07, zero Dart usages affected).
6. **Release signing** (Phase 10/11) — replace debug signing with a personal keystore + `release` CI job.## How to update
Append a dated section per session. Flip Status todo→doing→done only with VALIDATION row green.
