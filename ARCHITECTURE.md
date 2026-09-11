# ARCHITECTURE — what each component is and why

```text
lib/
  main.dart                  // boots ProviderScope, AppRouter, AppLock gate. No business logic.
  core/
    database.dart            // Drift DB singleton, schema versions, migrations. Only place with SQL.
    ledger.dart              // Dual-amount math: actual vs budgetImpact. Pure functions, tested.
    category_parser.dart     // Freeform parser: space=level, '-'=item. Pure function, tested.
    auth/ lock_service.dart  // PIN verify (hashed) + biometric + decoy PIN + auto-lock timer.
    backup/ codec.dart       // Encrypted ZIP export/import (JSON+sqlite). No network.
    intake/ share_parser.dart// Offline regex extractors for shared text/OCR output. Pure, tested.
  features/
    transactions/  // In/out CRUD UI + provider. Writes via core/database only.
    customization/ // Buckets/sources/dests lookup tables + settings. All dropdowns read from here.
    budgets/       // Monthly totals + N-bucket math + simulator (runs on history, writes nothing).
    neutral/       // Debts + partials + aging/nudge dates. budgetImpact always 0.
    splits/        // Split group + receivables + settles + absorbed flag.
    instruments/   // Accounts/cards/stocks/paper/notes + P/L% + interest pure fns.
    reconcile/     // Month open/close: bank open/close + cash count + card spend vs budget.
    reports/       // Read-only charts + drill queries. Never writes.
    settings/      // PIN/biometric/decoy, Drive manual, about.
```

## Why decoupled this way
- `features/*` never import each other — only `core/*`. Reports can crash, entry still saves.
- All money math lives in `core/ledger.dart` (one place to audit accuracy).
- All parsing lives in `core/category_parser.dart` + `core/intake/share_parser.dart` (one place to test `gobi-65`, `Rs.450`).
- DB schema change = `core/database.dart` migration only, features untouched.
- Security is a gate (`AppLock`), not sprinkled per screen — decoy PIN just swaps the DB file handle.

## Data model (Drift v4, Phase 6 code-complete ✅ code / ⏳ codegen+tests on dev machine)
- `transactions(id, kind, actual, budgetImpact, occurredAt, categoryRaw, level0..2, item, note, accountId, linkId, linkType)` — append-only; corrections are reversals.
- `budgets(month, total, bucketsJson)` — bucketsJson = `[{name,pct}]`, sum must = 100 (validated in bucket_math.dart, enforced by BudgetRepository).
- `accounts(id, name UNIQUE, kind freeform, openingBalance, note)` — no DB-level FK from transactions (drift_dev/analyzer-14 codegen conflict); repositories own the discipline.
- `debts(...)` (v2) + `splits(...)` (v3) — contracts with money trails in transactions.
- `instruments(id, name, kind freeform, invested, current, note, status, createdAt)` (v4) — vault, tracking-only, never writes transactions. P/L% + interest in instruments/instrument_logic.dart.
- Later: `snapshots(month, accountId, open, close)`, `prices(item, amount, date, place)`.
- Gotcha (2026-09-04): never name a column getter identical to a Drift builder (`dateTime`); drift_dev 2.34 + analyzer 14 crashes parsing it. Used `occurredAt`.
