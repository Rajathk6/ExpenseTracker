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
}
