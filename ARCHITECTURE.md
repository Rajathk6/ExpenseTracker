# ARCHITECTURE — what each component is and why

```text
lib/
  main.dart                  // boots ProviderScope, AppRouter, AppLock gate. No business logic.
  core/
    database.dart            // Drift DB singleton, schema versions, migrations. Only place with SQL.
    ledger.dart              // Dual-amount math: actual vs budgetImpact. Pure functions, tested.
    category_parser.dart     // Freeform parser: space=level, '-'=item. Pure function, tested.
    auth/ lock_service.dart  // PIN verify (hashed) + biometric + decoy PIN + auto-lock timer.
                             // pin_service.dart owns hashes/storage; the gate swaps real/demo DB handles.
    backup/ codec.dart       // Encrypted ZIP export/import (JSON+sqlite). No network.
                             // backup_service.dart dumps/restores all tables; Drive stays manual.
    intake/ share_parser.dart// Offline regex extractors for shared text/OCR output. Pure, tested.
    auth/ secret_store.dart // PIN/decoy/recovery hashes in the OS keychain, not the DB file.
    auth/ biometric_service.dart // local_auth wrapper; never throws, always leaves the PIN usable.
    cash/          // (features/cash) Self-transfers (dual budget-neutral rows) + 2-tap quick-add
                   // sheet + the home-screen tile that opens it.
  features/
    transactions/  // In/out CRUD UI + provider. Writes via core/database only.
    customization/ // Buckets/sources/dests lookup tables + settings. All dropdowns read from here.
    budgets/       // Monthly totals + N-bucket math + simulator (runs on history, writes nothing).
    neutral/       // Debts + partials + aging/nudge dates. budgetImpact always 0.
    splits/        // Split group + receivables + settles + absorbed flag.
    instruments/   // Accounts/cards/stocks/paper/notes + P/L% + interest pure fns.
    reconcile/     // Month open/close: bank open/close + cash count + card spend vs budget.
                   // + price memory (stats over item history) + net-worth timeline.
    reports/       // Read-only dashboards + drill queries. Never writes.
                   // Spend figures use budget truth; drill screens take row
                   // lists directly (no extra providers). Month keys shared
                   // via core/months.dart (re-exported by reconcile_logic).
    intake/       // Confirm screen (mandatory human checkpoint), the Android share target
                   // (our own manifest filter + two channels, no plugin) and on-device OCR.
    settings/      // PIN/biometric/decoy, encrypted backup, about. Drive upload is manual.
```

## Why decoupled this way
- `features/*` never import each other — only `core/*`. Reports can crash, entry still saves.
- All money math lives in `core/ledger.dart` (one place to audit accuracy).
- All parsing lives in `core/category_parser.dart` + `core/intake/share_parser.dart` (one place to test `gobi-65`, `Rs.450`).
- DB schema change = `core/database.dart` migration only, features untouched.
- Security is a gate (`AppLock`), not sprinkled per screen — decoy PIN just swaps the DB file handle.

## Data model (Drift v7, codegen + tests green — 109/109 as of 2026-09-16)
- `transactions(id, kind, actual, budgetImpact, occurredAt, categoryRaw, level0..2, item, note, accountId, linkId, linkType)` — append-only; corrections are reversals.
- `budgets(month, total, bucketsJson)` — bucketsJson = `[{name,pct}]`, sum must = 100 (validated in bucket_math.dart, enforced by BudgetRepository).
- `accounts(id, name UNIQUE, kind freeform, openingBalance, note)` — no DB-level FK from transactions (drift_dev/analyzer-14 codegen conflict); repositories own the discipline.
- `debts(...)` (v2) + `splits(...)` (v3) — contracts with money trails in transactions.
- `instruments(id, name, kind freeform, invested, current, note, status, createdAt)` (v4) — vault, tracking-only, never writes transactions. P/L% + interest in instruments/instrument_logic.dart.
- `snapshots(month, accountId, openBalance, countedClose, hasClose, createdAt)` (v5, PK = month+account) — reconcile inputs. Report reads ledger via transactionsBetween; price memory reads item history (no table); net-worth timeline derives bank/cash from openings + all actuals.
- `settings(key, value)` (v6) — non-secret settings only: auto-lock minutes, the biometric toggle and the recovery question. PIN/decoy/recovery hashes live in the OS keychain (`core/auth/secret_store.dart`), namespaced per vault and migrated out of this table on first read. `month_open(month, budgetIn, budgetOut, bankBalance, cashBalance, cardLimit)` (v7) — the optional month-start form.
- Later: `prices(item, amount, date, place)` only if derived history proves too slow.
- `core/backup/backup_service.dart` walks the single `backupTables` list — a new table must be added there or it silently misses every .etbak.
- Gotcha (2026-09-04): never name a column getter identical to a Drift builder (`dateTime`); drift_dev 2.34 + analyzer 14 crashes parsing it. Used `occurredAt`.

## SQLCipher evaluation (2026-09-27, decision: not now)

PLAN scope item 13 says "SQLCipher later phase"; this is that phase's evaluation.

**What it would buy:** the ledger file on disk stops being readable plaintext, so
adb backup, a rooted device, or a filesystem-level read stops yielding the whole
history. Right now the file is a plain SQLite database.

**What it costs, concretely:**
1. **Migration is the risk, not the library.** Every existing install has a
   plaintext `expense_tracker.sqlite`. Switching the opener to SQLCipher means
   detecting that file and re-encrypting it (`ATTACH` + `sqlcipher_export`, or
   dump → new encrypted file → verify → delete old). A bug there loses the
   owner's real data, and there is no server to restore from — only the .etbak.
2. **Key custody.** The DB key has to live in `flutter_secure_storage` (the
   Android Keystore). Keystore entries are lost when the app is uninstalled or
   its signing key changes. Today a reinstall just re-reads a plaintext file;
   with SQLCipher an uninstall/reinstall (or a debug-signed rebuild) makes the
   ledger permanently unreadable unless it is restored from a backup.
3. **Build surface.** `sqlcipher_flutter_libs` replaces `sqlite3_flutter_libs`
   (they both provide the `sqlite3` native library), which is another
   dependency to keep building against the pinned compileSdk.
4. **It duplicates a control that already exists.** The app already has a PIN
   gate, keychain-held secrets, biometric unlock, auto-lock and a
   password-encrypted export that is tested end to end. SQLCipher protects a
   different threat (off-device file access) with a much bigger blast radius.

**Decision: keep the file database as is.** The remaining exposure is
off-device file access, which for a personal, offline, non-rooted phone is
already covered by the app lock plus the encrypted backup.

**When to revisit:** the same day release signing lands (so the signing key
stops changing and reinstalls stop invalidating the Keystore entry), and with a
migration that is rehearsed on a copy of a real vault before it ever touches
the real one. Drift supports it with `NativeDatabase.opened(setup:)` plus
`PRAGMA key`; the seam would be `core/db_open.dart` and nothing else.
