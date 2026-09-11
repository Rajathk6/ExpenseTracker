/// Transaction repository: append-only writes with automatic category parsing.
/// Any category string is accepted (flexibility rule) — parsing never rejects.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/category_parser.dart';
import '../../core/database.dart';

class TransactionRepository {
  final AppDatabase db;
  const TransactionRepository(this.db);

  Future<Transaction> add({
    required String kind,
    required double actual,
    required double budgetImpact,
    required DateTime dateTime,
    required String categoryRaw,
    String? note,
    String? accountId,
    String? linkId,
    String? linkType,
  }) async {
    if (kind.trim().isEmpty) throw ArgumentError('kind cannot be empty');
    if (categoryRaw.trim().isEmpty) throw ArgumentError('category cannot be empty');
    final parsed = parseCategory(categoryRaw);
    final id = const Uuid().v4();
    await db.insertTransaction(
      TransactionsCompanion(
        id: Value(id),
        kind: Value(kind.trim().toLowerCase()),
        actual: Value(actual),
        budgetImpact: Value(budgetImpact),
        occurredAt: Value(dateTime),
        categoryRaw: Value(categoryRaw.trim()),
        level0: Value(parsed.levels.isNotEmpty ? parsed.levels[0] : null),
        level1: Value(parsed.levels.length > 1 ? parsed.levels[1] : null),
        level2: Value(parsed.levels.length > 2 ? parsed.levels.sublist(2).join(' ') : null),
        item: Value(parsed.item),
        note: Value(note),
        accountId: Value(accountId),
        linkId: Value(linkId),
        linkType: Value(linkType),
      ),
    );
    return (db.select(db.transactions)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<List<Transaction>> forItem(String item, {DateTime? from, DateTime? to}) async {
    final rows = await db.transactionsForItem(item);
    if (from == null && to == null) return rows;
    return rows
        .where((r) => (from == null || !r.occurredAt.isBefore(from)) && (to == null || !r.occurredAt.isAfter(to)))
        .toList();
  }

  Future<List<String>> allItems() => db.distinctItems();

  /// Matches raw category, any level, or item (substring, case-insensitive).
  /// Empty query returns empty (use allItems() to browse).
  Future<List<Transaction>> search(String query) => db.searchTransactions(query);

  /// Category autocomplete: past raw categories containing [prefix] (case-insensitive).
  Future<List<String>> suggestions(String prefix) async {
    final all = await db.distinctCategories();
    final q = prefix.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((c) => c.toLowerCase().contains(q)).toList();
  }

  /// Month (or any range) totals. Positive `inflow`, negative `outflow` sums
  /// for both statement (actual) and planning (budgetImpact) truths.
  Future<({double inActual, double outActual, double inBudget, double outBudget, int count})> sumsBetween(
    DateTime from,
    DateTime to,
  ) async {
    final rows = await db.transactionsBetween(from, to);
    var inActual = 0.0, outActual = 0.0, inBudget = 0.0, outBudget = 0.0;
    for (final r in rows) {
      if (r.actual >= 0) {
        inActual += r.actual;
      } else {
        outActual += r.actual;
      }
      if (r.budgetImpact >= 0) {
        inBudget += r.budgetImpact;
      } else {
        outBudget += r.budgetImpact;
      }
    }
    return (inActual: inActual, outActual: outActual, inBudget: inBudget, outBudget: outBudget, count: rows.length);
  }

  Future<List<Transaction>> recent({int limit = 200}) async {
    final q = db.select(db.transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
      ..limit(limit);
    return q.get();
  }

  /// Self-transfer between own accounts (e.g. ATM Bank→Cash). Writes TWO
  /// rows sharing one linkId: out of [fromId], into [toId]. Both carry
  /// budgetImpact 0, so months never inflate. Phase 9.
  Future<(Transaction, Transaction)> transfer({
    required String fromId,
    required String toId,
    required double amount,
    DateTime? at,
    String? note,
  }) async {
    if (fromId == toId) throw ArgumentError('Pick two different accounts');
    if (amount <= 0) throw ArgumentError('Amount must be above zero');
    final from = await db.getAccount(fromId);
    final to = await db.getAccount(toId);
    final when = at ?? DateTime.now();
    final linkId = const Uuid().v4();
    final label = 'transfer ${from.name} to ${to.name}'.toLowerCase();
    final out = await add(
      kind: 'transfer',
      actual: -amount,
      budgetImpact: 0,
      dateTime: when,
      categoryRaw: label,
      note: note,
      accountId: fromId,
      linkId: linkId,
      linkType: 'transfer',
    );
    final inn = await add(
      kind: 'transfer',
      actual: amount,
      budgetImpact: 0,
      dateTime: when,
      categoryRaw: label,
      note: note,
      accountId: toId,
      linkId: linkId,
      linkType: 'transfer',
    );
    return (out, inn);
  }

  /// Every row, oldest first. Used by the net-worth timeline (Phase 7).
  /// Perf note (Phase 11): fine for personal scale (thousands of rows);
  /// if it ever feels slow, window this to the trailing N months.
  Future<List<Transaction>> all() async {
    final q = db.select(db.transactions)..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]);
    return q.get();
  }
}
