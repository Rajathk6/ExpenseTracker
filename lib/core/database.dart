/// Drift (SQLite) schema v1 + query surface. Only place in the app with SQL.
///
/// Tables:
/// - [Accounts]: user-defined money sources/dests. `kind` is freeform text
///   (bank/cash/card/wallet/upi/...), only *suggested* in UI, never constrained.
/// - [Transactions]: append-only money events with dual amounts (see ledger.dart)
///   plus pre-parsed category levels/item for fast offline search.
/// - [Budgets]: one row per month (`YYYY-MM`), N custom buckets as JSON.
///
/// Phase 1. Later phases add debts/splits/snapshots/prices tables + migrations.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'database.g.dart';

/// User-defined accounts. Name is unique so dropdowns stay unambiguous.
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().unique()();
  TextColumn get kind => text().withDefault(const Constant('cash'))();
  RealColumn get openingBalance => real().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

/// Append-only ledger. Never UPDATE/DELETE from features — corrections are
/// reversal entries (enforced by repositories, not the DB).
class Transactions extends Table {
  TextColumn get id => text()();
  /// Freeform: in / out / neutral / lend / borrow / split / settle / transfer / invest.
  TextColumn get kind => text()();
  /// Statement truth: what entered/left the account.
  RealColumn get actual => real()();
  /// Planning truth: what counts toward the monthly budget.
  RealColumn get budgetImpact => real()();
  /// When the money moved (user-picked date/time, not insertion time).
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get categoryRaw => text()();
  TextColumn get level0 => text().nullable()();
  TextColumn get level1 => text().nullable()();
  TextColumn get level2 => text().nullable()();
  /// Exact item token incl. hyphen part, e.g. `gobi-65`. Null when none.
  TextColumn get item => text().nullable()();
  /// Budget bucket this entry belongs to (need/want/invest or custom).
  /// Freeform text, null = unassigned. UX-feedback batch.
  TextColumn get bucket => text().nullable()();
  /// 1 when the owner chose to absorb this neutral row (a lend/borrow or its
  /// payoff) into the month's budget. Neutral rows stay out of month math
  /// until this flips — owner rule 2026-09-27.
  IntColumn get absorbed => integer().withDefault(const Constant(0))();
  /// Counterparty on lend/borrow/settle rows, so a plain front-screen entry
  /// can be routed to the right person's contract. Owner rule 2026-09-27.
  TextColumn get person => text().nullable()();
  TextColumn get note => text().nullable()();
  /// Owning account id. Plain text, no DB-level FK (keeps drift codegen
  /// robust across analyzer versions; repositories own the discipline).
  TextColumn get accountId => text().nullable()();
  TextColumn get linkId => text().nullable()();
  TextColumn get linkType => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

/// Monthly budget. `bucketsJson` = `[{"name": "...", "pct": 30}]`, must sum to 100
/// (enforced by [BudgetRepository], validated in bucket_math.dart).
class Budgets extends Table {
  /// `YYYY-MM`.
  TextColumn get month => text()();
  RealColumn get total => real()();
  TextColumn get bucketsJson => text()();
  @override
  Set<Column> get primaryKey => {month};
}

/// Lend/borrow contracts. Money movement lives in [Transactions] with
/// linkType='debt' + linkId; this table is the contract + payoff state.
/// Phase 4. Budget impact of all linked txns is always 0 (neutral ledger).
class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get counterparty => text()();
  /// 'lent' (I gave money) or 'borrowed' (I took money).
  TextColumn get direction => text()();
  RealColumn get principal => real()();
  RealColumn get paid => real().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get nudgeDate => dateTime().nullable()();
  /// 'open' or 'settled'. Auto-settled by DebtRepository; never edited by UI.
  TextColumn get status => text().withDefault(const Constant('open'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

/// Group-expense splits. I pay [totalPaid] now; my fair share is [myShare];
/// the rest ([totalPaid]-[myShare]) is receivable from others.
/// Settlements + absorb-writeoffs live in [Transactions] (linkType='split').
/// Phase 5.
class Splits extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  RealColumn get totalPaid => real()();
  RealColumn get myShare => real()();
  RealColumn get received => real().withDefault(const Constant(0))();
  RealColumn get absorbed => real().withDefault(const Constant(0))();
  /// JSON list of member names for display, e.g. ["Ravi","Asha"].
  TextColumn get membersJson => text().withDefault(const Constant('[]'))();
  TextColumn get note => text().nullable()();
  /// 'open' or 'closed'. Auto-closed when received+absorbed covers receivable.
  TextColumn get status => text().withDefault(const Constant('open'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

/// Instruments vault: banks/cards/statements/loans/stocks/paper-trades/plans
/// + notes. Phase 6. Tracking-only — no auto ledger writes (keeps the
/// dual-amount invariant untouched). `kind` is freeform text
/// (stock/mutual/fd/loan/card/paper/plan/note/...), only suggested in UI.
/// P/L% + interest are pure functions in instruments/instrument_logic.dart.
class Instruments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get kind => text().withDefault(const Constant('stock'))();
  /// Money put in (principal / buy cost).
  RealColumn get invested => real().withDefault(const Constant(0))();
  /// Latest marked value (manual update — vault is offline-first).
  RealColumn get current => real().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  /// 'open' or 'archived'. Archived rows leave totals and history intact.
  TextColumn get status => text().withDefault(const Constant('open'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

/// Month snapshots for reconciliation. One row per (month, account):
/// the opening balance typed at month-start plus the physically-counted
/// close at month-end. Phase 7. `openBalance` (not `open`) avoids any
/// clash with Drift builder names. `hasClose` distinguishes "counted 0"
/// from "not counted yet".
class Snapshots extends Table {
  /// `YYYY-MM`.
  TextColumn get month => text()();
  TextColumn get accountId => text()();
  RealColumn get openBalance => real().withDefault(const Constant(0))();
  RealColumn get countedClose => real().withDefault(const Constant(0))();
  IntColumn get hasClose => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {month, accountId};
}

/// Optional month-open form: everything the month-start prompt asks for.
/// All nullables — every field optional, editable later. UX-feedback batch.
class MonthOpen extends Table {
  /// `YYYY-MM`.
  TextColumn get month => text()();
  RealColumn get budgetIn => real().nullable()();
  RealColumn get budgetOut => real().nullable()();
  RealColumn get bankBalance => real().nullable()();
  RealColumn get cashBalance => real().nullable()();
  RealColumn get cardLimit => real().nullable()();
  @override
  Set<Column> get primaryKey => {month};
}

/// A recurring entry the owner repeats every month (salary, rent, SIP…). Kept
/// as a rule, not as rows: applying it creates real transactions, so history
/// stays honest and the rule can be edited or retired. Owner rule 2026-09-27.
class RecurringRules extends Table {
  TextColumn get id => text()();
  /// 'in' or 'out'.
  TextColumn get kind => text()();
  RealColumn get amount => real()();
  TextColumn get categoryRaw => text()();
  TextColumn get bucket => text().nullable()();
  TextColumn get accountId => text().nullable()();
  /// Day of month the entry lands on (1–28 keeps it month-safe).
  IntColumn get dayOfMonth => integer().withDefault(const Constant(1))();
  /// How many months to apply, counting from [startMonth].
  IntColumn get months => integer().withDefault(const Constant(1))();
  /// `YYYY-MM` the rule counts forward from.
  TextColumn get startMonth => text()();
  /// `YYYY-MM` of the last month this rule filled in (null = not applied yet).
  TextColumn get lastAppliedMonth => text().nullable()();
  /// Freeform note on the rule itself.
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

/// Splitwise-style group: a named set of people for one period, joined by a
/// share code. Offline-first — a code identifies the group on both devices,
/// but syncing rows between phones needs a server (see ARCHITECTURE.md).
class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  /// Short code the other party types to join, e.g. `ET-4KQ2`.
  TextColumn get code => text()();
  /// `YYYY-MM` the group covers (owner asked for a month per group).
  TextColumn get monthKey => text()();
  TextColumn get note => text().nullable()();
  /// 'open' or 'closed'.
  TextColumn get status => text().withDefault(const Constant('open'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

/// Who is in a group. Names are required — an unlabelled participant makes a
/// balance impossible to read (owner rule 2026-09-27).
class GroupMembers extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

/// Money spent for a group, and who fronted it.
class GroupExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  /// Participant name who paid.
  TextColumn get paidBy => text()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get note => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// A pay-up: somebody returned money to somebody. Recorded once per side, so
/// both phones show the same pay-up when they share the group code.
class GroupPayments extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  /// Who paid back.
  TextColumn get paidBy => text()();
  /// Who received it (empty string = into the pot, e.g. me).
  TextColumn get paidTo => text()();
  RealColumn get amount => real()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get note => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// App settings as plain key/value rows (PIN hashes, auto-lock timeout…).
/// Phase 10. Values are opaque strings owned by feature code; the only
/// secrets stored are salted hashes, never raw PINs. (A move to
/// flutter_secure_storage / SQLCipher is a dev-machine step, see PROGRESS.)
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  Accounts,
  Transactions,
  Budgets,
  Debts,
  Splits,
  Instruments,
  Snapshots,
  Settings,
  MonthOpen,
  RecurringRules,
  Groups,
  GroupMembers,
  GroupExpenses,
  GroupPayments,
],)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Production constructor (Phase 10 wires the real file + SQLCipher).
  factory AppDatabase.file(String path) => AppDatabase(NativeDatabase.createInBackground(File(path)));

  /// Tests and previews.
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(debts);
          if (from < 3) await m.createTable(splits);
          if (from < 4) await m.createTable(instruments);
          if (from < 5) await m.createTable(snapshots);
          if (from < 6) await m.createTable(settings);
          if (from < 7) {
            await m.addColumn(transactions, transactions.bucket);
            await m.createTable(monthOpen);
          }
          if (from < 8) {
            await m.addColumn(transactions, transactions.absorbed);
            await m.addColumn(transactions, transactions.person);
            await m.createTable(recurringRules);
            await m.createTable(groups);
            await m.createTable(groupMembers);
            await m.createTable(groupExpenses);
            await m.createTable(groupPayments);
          }
        },
      );

  // --- Accounts ---

  Future<List<Account>> allAccounts() => (select(accounts)..orderBy([(a) => OrderingTerm.asc(a.name)])).get();

  Stream<List<Account>> watchAccounts() => (select(accounts)..orderBy([(a) => OrderingTerm.asc(a.name)])).watch();

  Future<Account> getAccount(String id) => (select(accounts)..where((a) => a.id.equals(id))).getSingle();

  Future<void> upsertAccount(AccountsCompanion entry) => into(accounts).insertOnConflictUpdate(entry);

  Future<int> deleteAccount(String id) => (delete(accounts)..where((a) => a.id.equals(id))).go();

  // --- Transactions ---

  Future<void> insertTransaction(TransactionsCompanion entry) => into(transactions).insert(entry);

  Future<Transaction> transactionById(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingle();

  Future<void> updateTransaction(String id, TransactionsCompanion entry) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(entry);

  Future<int> deleteTransaction(String id) => (delete(transactions)..where((t) => t.id.equals(id))).go();

  Future<List<Transaction>> transactionsBetween(DateTime from, DateTime to) =>
      (select(transactions)
            ..where((t) => t.occurredAt.isBetweenValues(from, to))
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
          .get();

  /// Exact-item search across all time, e.g. every `gobi-65` ever.
  Future<List<Transaction>> transactionsForItem(String item) =>
      (select(transactions)
            ..where((t) => t.item.equals(item.toLowerCase()))
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
          .get();

  Future<List<String>> distinctItems() async {
    final q = selectOnly(transactions, distinct: true)
      ..addColumns([transactions.item])
      ..where(transactions.item.isNotNull());
    return (await q.get()).map((r) => r.read(transactions.item)!).toList()..sort();
  }

  /// Full-text-ish search across raw category, levels and item.
  /// Matches substrings, case-insensitive for ASCII. `%`/`_` stripped.
  /// [from]/[to] narrow the window so the owner can search one month, one
  /// year or everything (#4); null means no bound on that side.
  Future<List<Transaction>> searchTransactions(String query, {DateTime? from, DateTime? to}) {
    final clean = query.trim().toLowerCase().replaceAll(RegExp(r'[%_]'), '');
    bool inRange(Transaction t) =>
        (from == null || !t.occurredAt.isBefore(from)) && (to == null || !t.occurredAt.isAfter(to));
    if (clean.isEmpty) {
      // No query + a window = "show me this month", which is what the owner
      // expects to land on.
      if (from == null && to == null) return Future.value(const <Transaction>[]);
      return (select(transactions)
            ..where((t) => t.occurredAt.isBetweenValues(from ?? DateTime(1970), to ?? DateTime(2100)))
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
            ..limit(200))
          .get();
    }
    final pattern = '%$clean%';
    return (select(transactions)
          ..where(
            (t) =>
                t.categoryRaw.lower().like(pattern) |
                t.level0.lower().like(pattern) |
                t.level1.lower().like(pattern) |
                t.level2.lower().like(pattern) |
                t.item.lower().like(pattern),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
          ..limit(400))
        .get()
        .then((rows) => [for (final r in rows) if (inRange(r)) r].take(200).toList());
  }

  /// Every raw category string ever typed, for autocomplete suggestions.
  Future<List<String>> distinctCategories() async {
    final q = selectOnly(transactions, distinct: true)..addColumns([transactions.categoryRaw]);
    return (await q.get()).map((r) => r.read(transactions.categoryRaw)!).toList()..sort();
  }

  /// Raw category → how many entries used it. Ties in the suggestion rank
  /// are broken by usage, so the things you buy most come first.
  Future<Map<String, int>> categoryUsage() async {
    final n = transactions.categoryRaw.count();
    final q = selectOnly(transactions)
      ..addColumns([transactions.categoryRaw, n])
      ..groupBy([transactions.categoryRaw]);
    final out = <String, int>{};
    for (final r in await q.get()) {
      out[r.read(transactions.categoryRaw)!] = r.read(n) ?? 0;
    }
    return out;
  }

  // --- Budgets ---

  Future<Budget?> getBudget(String month) =>
      (select(budgets)..where((b) => b.month.equals(month))).getSingleOrNull();

  Future<void> upsertBudget(BudgetsCompanion entry) => into(budgets).insertOnConflictUpdate(entry);

  /// Latest budget at or before [month] (carry-forward source), null if none.
  Future<Budget?> latestBudgetAtOrBefore(String month) => (select(budgets)
        ..where((b) => b.month.isSmallerOrEqualValue(month))
        ..orderBy([(b) => OrderingTerm.desc(b.month)])
        ..limit(1))
      .getSingleOrNull();

  // --- Month open ---

  Future<MonthOpenData?> getMonthOpen(String month) =>
      (select(monthOpen)..where((m) => m.month.equals(month))).getSingleOrNull();

  Future<void> upsertMonthOpen(MonthOpenCompanion entry) =>
      into(monthOpen).insertOnConflictUpdate(entry);

  // --- Debts ---

  Future<Debt> getDebt(String id) => (select(debts)..where((d) => d.id.equals(id))).getSingle();

  Future<List<Debt>> openDebts() =>
      (select(debts)
            ..where((d) => d.status.equals('open'))
            ..orderBy([(d) => OrderingTerm.asc(d.createdAt)]))
          .get();

  Future<List<Debt>> allDebts() =>
      (select(debts)..orderBy([(d) => OrderingTerm.desc(d.createdAt)])).get();

  Future<void> insertDebt(DebtsCompanion entry) => into(debts).insert(entry);

  Future<void> updateDebt(String id, DebtsCompanion entry) =>
      (update(debts)..where((d) => d.id.equals(id))).write(entry);

  /// Money trail for one contract, oldest first.
  Future<List<Transaction>> debtHistory(String debtId) =>
      (select(transactions)
            ..where((t) => t.linkId.equals(debtId) & t.linkType.equals('debt'))
            ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
          .get();

  // --- Splits ---

  Future<Split> getSplit(String id) => (select(splits)..where((s) => s.id.equals(id))).getSingle();

  Future<List<Split>> openSplits() =>
      (select(splits)
            ..where((s) => s.status.equals('open'))
            ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
          .get();

  Future<List<Split>> allSplits() =>
      (select(splits)..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).get();

  Future<void> insertSplit(SplitsCompanion entry) => into(splits).insert(entry);

  Future<void> updateSplit(String id, SplitsCompanion entry) =>
      (update(splits)..where((s) => s.id.equals(id))).write(entry);

  /// Money trail for one split, oldest first.
  Future<List<Transaction>> splitHistory(String splitId) =>
      (select(transactions)
            ..where((t) => t.linkId.equals(splitId) & t.linkType.equals('split'))
            ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
          .get();

  // --- Instruments (Phase 6, vault) ---

  Future<Instrument> getInstrument(String id) =>
      (select(instruments)..where((i) => i.id.equals(id))).getSingle();

  Future<List<Instrument>> openInstruments() =>
      (select(instruments)
            ..where((i) => i.status.equals('open'))
            ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
          .get();

  Future<List<Instrument>> allInstruments() =>
      (select(instruments)..orderBy([(i) => OrderingTerm.desc(i.createdAt)])).get();

  Future<void> insertInstrument(InstrumentsCompanion entry) => into(instruments).insert(entry);

  Future<void> updateInstrument(String id, InstrumentsCompanion entry) =>
      (update(instruments)..where((i) => i.id.equals(id))).write(entry);

  Future<int> deleteInstrument(String id) => (delete(instruments)..where((i) => i.id.equals(id))).go();

  // --- Snapshots (Phase 7, reconcile) ---

  Future<Snapshot?> getSnapshot(String month, String accountId) =>
      (select(snapshots)..where((s) => s.month.equals(month) & s.accountId.equals(accountId))).getSingleOrNull();

  Future<List<Snapshot>> snapshotsForMonth(String month) =>
      (select(snapshots)..where((s) => s.month.equals(month))).get();

  Future<void> upsertSnapshot(SnapshotsCompanion entry) => into(snapshots).insertOnConflictUpdate(entry);

  // --- Recurring rules (v8) ---

  Future<List<RecurringRule>> allRecurringRules() => select(recurringRules).get();

  Future<void> upsertRecurringRule(RecurringRulesCompanion entry) =>
      into(recurringRules).insertOnConflictUpdate(entry);

  /// Progress marker only. Insert-or-replace would have to repeat every NOT NULL
  /// column, and would blank the ones it left out.
  Future<void> markRecurringApplied({required String id, required String month}) =>
      (update(recurringRules)..where((r) => r.id.equals(id)))
          .write(RecurringRulesCompanion(lastAppliedMonth: Value(month)));

  Future<int> deleteRecurringRule(String id) => (delete(recurringRules)..where((r) => r.id.equals(id))).go();

  // --- Groups (v8) ---

  Future<List<Group>> allGroups() => (select(groups)..orderBy([(g) => OrderingTerm.desc(g.createdAt)])).get();

  Future<Group?> getGroup(String id) => (select(groups)..where((g) => g.id.equals(id))).getSingleOrNull();

  Future<Group?> groupByCode(String code) =>
      (select(groups)..where((g) => g.code.equals(code.trim().toUpperCase()))).getSingleOrNull();

  Future<List<GroupMember>> membersOf(String groupId) =>
      (select(groupMembers)..where((m) => m.groupId.equals(groupId))..orderBy([(m) => OrderingTerm.asc(m.createdAt)])).get();

  Future<void> upsertGroup(GroupsCompanion entry) => into(groups).insertOnConflictUpdate(entry);

  Future<void> insertMember(GroupMembersCompanion entry) => into(groupMembers).insert(entry);

  Future<int> deleteMember(String id) => (delete(groupMembers)..where((m) => m.id.equals(id))).go();

  Future<List<GroupExpense>> expensesOf(String groupId) =>
      (select(groupExpenses)..where((e) => e.groupId.equals(groupId))..orderBy([(e) => OrderingTerm.desc(e.occurredAt)])).get();

  Future<void> insertGroupExpense(GroupExpensesCompanion entry) => into(groupExpenses).insert(entry);

  Future<List<GroupPayment>> paymentsOf(String groupId) =>
      (select(groupPayments)..where((p) => p.groupId.equals(groupId))..orderBy([(p) => OrderingTerm.desc(p.occurredAt)])).get();

  Future<void> insertGroupPayment(GroupPaymentsCompanion entry) => into(groupPayments).insert(entry);

  Future<List<GroupMember>> allMembers() => select(groupMembers).get();

  Future<List<GroupExpense>> allGroupExpenses() => select(groupExpenses).get();

  Future<List<GroupPayment>> allGroupPayments() => select(groupPayments).get();

  // --- Settings (Phase 10, PIN hashes etc.) ---

  Future<String?> getSetting(String key) async =>
      (await (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(SettingsCompanion(key: Value(key), value: Value(value)));

  Future<int> deleteSetting(String key) => (delete(settings)..where((s) => s.key.equals(key))).go();

  // --- Full-table reads for encrypted backup (Phase 10) ---

  Future<List<Budget>> allBudgets() => select(budgets).get();

  Future<List<Snapshot>> allSnapshots() => select(snapshots).get();

  Future<List<MonthOpenData>> allMonthOpens() => select(monthOpen).get();

  Future<List<RecurringRule>> allRecurring() => select(recurringRules).get();

  Future<List<Group>> allGroupsFlat() => select(groups).get();

  /// Month keys that have any transaction, newest first — powers the search
  /// and report month filters.
  Future<List<String>> monthsWithActivity() async {
    final q = selectOnly(transactions, distinct: true)..addColumns([transactions.occurredAt]);
    final keys = <String>{};
    for (final r in await q.get()) {
      final at = r.read(transactions.occurredAt)!;
      keys.add('${at.year}-${at.month.toString().padLeft(2, '0')}');
    }
    final sorted = keys.toList()..sort();
    return sorted.reversed.toList();
  }

  Future<List<Transaction>> allTransactions() =>
      (select(transactions)..orderBy([(t) => OrderingTerm.asc(t.occurredAt)])).get();
}

/// JSON helpers for the budgets table (kept here so repositories stay thin).
List<Map<String, dynamic>> decodeBuckets(String raw) =>
    (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

String encodeBuckets(List<Map<String, dynamic>> buckets) => jsonEncode(buckets);
