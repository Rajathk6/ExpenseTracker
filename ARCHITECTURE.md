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

## Data model (Drift v1, Phase 1 will implement)
- `transactions(id, kind, actual, budgetImpact, dateTime, categoryRaw, level0..2, item, note, accountId, linkId, linkType)`
- `lookups(kind[bucket/source/account], value, meta)` — everything customizable lives here.
- `budgets(month, total, bucketsJson)` — bucketsJson = `[{name,pct}]`, sum must = 100.
- `debts(id, counterparty, principal, paid, direction, dueDate, nudgeDate, note, status)`
- `splits(id, totalPaid, myShare, membersJson, status)` + `settlements(splitId, who, amount, date)`
- `accounts(id, type[bank/cash/card/wallet], name, openBal)` + `snapshots(month, accountId, open, close)`
- `prices(item, amount, date, place)` — price memory log (append-only).
