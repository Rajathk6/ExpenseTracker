/// Repeating entries: "this salary arrives on the 1st, every month".
///
/// A rule is not a transaction. Applying it writes a real entry, so the ledger
/// keeps telling the truth and the owner can edit or delete the result like any
/// other entry. Rules fill months forward from their start month and remember
/// where they got to, so the same month is never filled twice.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/database.dart';
import '../../core/ledger.dart';
import '../../core/months.dart';

/// One month a rule should fill, from [startMonth] up to [months] months on.
class PendingApplication {
  final RecurringRule rule;
  final String monthKey;
  PendingApplication(this.rule, this.monthKey);
}

class RecurringService {
  final AppDatabase db;
  const RecurringService(this.db);

  Future<List<RecurringRule>> all() => db.allRecurringRules();

  Future<void> delete(String id) => db.deleteRecurringRule(id);

  /// Months this rule still owes, oldest first. `YYYY-MM` sorts correctly as
  /// text, so string comparison is the honest month comparison here.
  List<PendingApplication> pending(RecurringRule rule, {String? nowMonth}) {
    final today = nowMonth ?? monthKey(DateTime.now());
    final start = _parse(rule.startMonth);
    final after = rule.lastAppliedMonth;
    final out = <PendingApplication>[];
    for (var i = 0; i < rule.months; i++) {
      final key = monthKey(DateTime(start.year, start.month + i));
      if (after != null && key.compareTo(after) <= 0) continue;
      if (key.compareTo(today) > 0) break; // never backfill a month that has not happened
      out.add(PendingApplication(rule, key));
    }
    return out;
  }

  /// Writes one real entry for [monthKey] from [rule] and remembers progress.
  /// Returns the transaction, or null when that month is already filled.
  Future<Transaction?> apply(RecurringRule rule, String month) async {
    final start = _parse(month);
    final day = rule.dayOfMonth.clamp(1, 28);
    final when = DateTime(start.year, start.month, day, 10, 0);
    final existing = (await db.allTransactions())
        .where((t) => '${t.occurredAt.year}-${t.occurredAt.month.toString().padLeft(2, '0')}' == month)
        .where((t) => t.categoryRaw.toLowerCase() == rule.categoryRaw.toLowerCase())
        .where((t) => t.note != null && t.note!.contains(rule.id))
        .toList();
    if (existing.isNotEmpty) return null;
    final entry = rule.kind == 'in' ? income(rule.amount) : spend(rule.amount);
    final id = const Uuid().v4();
    await db.insertTransaction(
      TransactionsCompanion(
        id: Value(id),
        kind: Value(rule.kind == 'in' ? 'in' : 'out'),
        actual: Value(entry.actual),
        budgetImpact: Value(entry.budgetImpact),
        occurredAt: Value(when),
        categoryRaw: Value(rule.categoryRaw),
        level0: Value(rule.categoryRaw.split(' ').first),
        bucket: Value(rule.bucket),
        note: Value('repeating ${rule.id.substring(0, min(rule.id.length, 8))} · $month'),
        accountId: Value(rule.accountId),
      ),
    );
    await db.markRecurringApplied(id: rule.id, month: month);
    return db.transactionById(id);
  }

  /// Applies every month this rule still owes, oldest first. [nowMonth] exists
  /// so tests (and a future "fill up to this month" button) are deterministic.
  Future<int> applyAll(RecurringRule rule, {String? nowMonth}) async {
    var written = 0;
    for (final pending in pending(rule, nowMonth: nowMonth)) {
      final row = await apply(rule, pending.monthKey);
      if (row != null) written++;
    }
    return written;
  }

  static int min(int a, int b) => a < b ? a : b;

  static DateTime _parse(String month) {
    final parts = month.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }
}