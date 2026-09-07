# PLAN — ExpenseTracker build order

Stack: **Flutter 3.x + Dart + Drift(SQLite) + Riverpod + go_router + local_auth + fl_chart**.
All data local. Backup = encrypted ZIP (JSON+SQLite) via file copy or manual Drive upload. No auto-sync.

## Approved scope (incl. latest additions)
1. In/Out with date/time/category picker.
2. Monthly budgets: set total, N fully-custom buckets (presets: 30/40/30, 50/30/20, custom). **Budget simulator** to preview a ratio on last-3-months data before committing.
3. Freeform categories: `space` = new level, `-` = item continuation. `food junk gobi-65` → levels `[food, junk]`, item `gobi-65`. Search any token across month/year.
4. Neutral ledger (lend/borrow): excluded from budget, partials validated vs principal, auto-settle + archive. **Aging + local nudge** (days-since, progress bar, reminder date, per-friend note).
5. Splits: pay 1000/10 → `actual=-1000, budget=-100, receivable=900`. Manual settles reconcile to bank. Unpaid-at-month-end flagged `absorbed`.
6. Instruments vault: banks/cards/statements/loans/stocks/paper-trades/plans + notes. Manual P/L% + interest calc.
7. Reconciliation: month-start **bank close + cash count + card spend + budget** → true spent / missing / end status. Cash counted physically, same formula as bank.
8. Reports: per-module graphs + drill to txn list.
9. **Price memory:** per-item price history (avg/min/max, overpay alert vs average).
10. **Net-worth timeline:** `(banks + cash + investments) − debts` per month-end, one graph.
11. Intake: Android share-target + iOS Share Extension, offline regex + on-device OCR, always confirm-screen before save. Manual entry never blocked.
12. Cash wallets: opening count, quick buttons, physical-count reconciliation, Cash-vs-Digital filter.
13. Security: 6-digit PIN (hashed) + biometric (fingerprint/face) + auto-lock + **decoy PIN** (second PIN opens clean demo vault). SQLCipher later phase.
14. **Home-screen quick add:** widget/quick-tile → 2-tap cash spend (amount + category), opens confirm sheet.

## Core invariant (do not break)
```text
actualAmount  = bank/cash impact
budgetImpact  = what counts toward monthly budget
Transfer Bank->Cash: actual moves, budgetImpact = 0
Lend 5000:           actual = -5000, budgetImpact = 0
Split 1000/10 (mine 100): actual = -1000, budgetImpact = -100, receivable = 900
```

## Phases (each = one branch, one VALIDATION row, one PROGRESS entry)
- **0 foundation** (`feature/00-foundation`, this branch): git, docs, pubspec, folder skeleton, lock shell stub, category parser pure function + test. ← WE ARE HERE
- **1 customization core** (`feature/01-custom-core`): lookup tables (buckets/sources/categories), Drift schema v1, settings defaults.
- **2 transactions+categories** (`feature/02-transactions`): in/out CRUD, datetime picker, category suggest + search aggregates.
- **3 budgets+simulator** (`feature/03-budgets`): monthly CRUD, N-bucket engine, simulator on history.
- **4 neutral+aging** (`feature/04-neutral`): debts, partials, auto-settle, aging/nudges.
- **5 splits** (`feature/05-splits`): split create, receivables, settles, absorbed flag, settle-up optimizer (stretch).
- **6 instruments** (`feature/06-instruments`): accounts/cards/stocks/paper/notes, P/L%, interest.
- **7 reconcile+pricememory+networth** (`feature/07-reconcile`): month open/close (bank+cash+card+budget), price history, net-worth graph.
- **8 reports** (`feature/08-reports`): dashboards, drill-downs, wrapped-style summaries.
- **9 intake+quickadd** (`feature/09-intake`): share-target, regex/OCR parsers, widget.
- **10 backup+security** (`feature/10-backup-security`): encrypted export/import, Drive manual, PIN+biometric+decoy, auto-lock, SQLCipher eval.
- **11 hardening** (`feature/11-hardening`): full tests, perf, release build.

Rules: never start N+1 with N red. One failure must not block manual entry.

## Release process (every `main` merge = installable APK)
- Versioning: `pubspec.yaml` `version: X.Y.Z+N` (Z+N bump per release).
  Tag the merge commit `vX.Y.Z`. Minor = phase lands, patch = fix.
- Gate: PR `develop`→`main` needs `ci / analyze` + `ci / test` +
  `ci / apk-debug` (builds debug APK, uploads artifact 14d). Direct pushes
  to `main` are hook-rejected.
- Install: download `app-debug.apk` from the CI run (or build locally with
  `flutter build apk --debug`; needs Java 17 + Android SDK 36, see PROGRESS
  2026-09-07 env notes). Debug-signed = fine for personal distribution.
- Release signing + Play/artifacts land with Phase 10/11.
- Dependency policy: native plugins stay on versions that build against
  Flutter's pinned compileSdk (36) with zero Gradle hacks. Phase 9/10-only
  native deps (share/file/auth/OCR/widget/Drive) were trimmed 2026-09-07
  after upstream breakage (SDK-37 requirements, Kotlin mismatches) and get
  re-added at their phases — pure-Dart logic (share_parser, ZIP) stays.
