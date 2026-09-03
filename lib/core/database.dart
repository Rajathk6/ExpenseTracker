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

@DriftDatabase(tables: [Accounts, Transactions, Budgets])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Production constructor (Phase 10 wires the real file + SQLCipher).
  factory AppDatabase.file(String path) => AppDatabase(NativeDatabase.createInBackground(File(path)));

  /// Tests and previews.
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  // --- Accounts ---

  Future<List<Account>> allAccounts() => (select(accounts)..orderBy([(a) => OrderingTerm.asc(a.name)])).get();

  Stream<List<Account>> watchAccounts() => (select(accounts)..orderBy([(a) => OrderingTerm.asc(a.name)])).watch();

  Future<Account> getAccount(String id) => (select(accounts)..where((a) => a.id.equals(id))).getSingle();

  Future<void> upsertAccount(AccountsCompanion entry) => into(accounts).insertOnConflictUpdate(entry);

  Future<int> deleteAccount(String id) => (delete(accounts)..where((a) => a.id.equals(id))).go();

  // --- Transactions ---

  Future<void> insertTransaction(TransactionsCompanion entry) => into(transactions).insert(entry);

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

  /// Every raw category string ever typed, for autocomplete suggestions.
  Future<List<String>> distinctCategories() async {
    final q = selectOnly(transactions, distinct: true)..addColumns([transactions.categoryRaw]);
    return (await q.get()).map((r) => r.read(transactions.categoryRaw)!).toList()..sort();
  }

  // --- Budgets ---

  Future<Budget?> getBudget(String month) =>
      (select(budgets)..where((b) => b.month.equals(month))).getSingleOrNull();

  Future<void> upsertBudget(BudgetsCompanion entry) => into(budgets).insertOnConflictUpdate(entry);
}

/// JSON helpers for the budgets table (kept here so repositories stay thin).
List<Map<String, dynamic>> decodeBuckets(String raw) =>
    (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

String encodeBuckets(List<Map<String, dynamic>> buckets) => jsonEncode(buckets);
