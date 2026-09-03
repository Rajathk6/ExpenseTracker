# ExpenseTracker (Flutter, offline-first)

Offline personal finance app. No backend. No network required for core flows.

## Principles
- **Offline-first:** Drift/SQLite local DB. Share/Drive/OCR are optional intake paths, never block manual entry.
- **Flexibility:** budgets (N buckets), categories (`space=level, -=item`), sources/dests, all user-definable. No hardcoded enums in DB.
- **Dual-amount ledger:** every money event stores `actualAmount` (bank impact) + `budgetImpact` (budget impact). Lending/split/transfer differ only in these two numbers.
- **Decoupled modules:** `lib/features/*` depend only on `lib/core/*`. One feature failing never blocks another.

## Status
See `PROGRESS.md` (session log), `VALIDATION.md` (acceptance checks), `PLAN.md` (full build order).

## Branches
`main` (stable) / `develop` (integration) / `feature/*` / `release/*` / `hotfix/*`.
Conventional commits: `feat(auth): ...`, `fix(split): ...`, `docs: ...`, `test: ...`.

## Run (requires Flutter SDK 3.3+)
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
flutter test
```

Flutter not installed here yet — scaffold is hand-written and ready for `flutter pub get` once SDK is installed.
See `PLAN.md` Phase 0 for SDK install steps.
