/// Budget repository: one row per month with N user-defined buckets.
/// Validation lives in bucket_math.dart; this class only persists valid budgets.
library;

import 'package:drift/drift.dart';

import '../../core/database.dart';
import 'bucket_math.dart';

final _monthRe = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');

class BudgetRepository {
  final AppDatabase db;
  const BudgetRepository(this.db);

  static void checkMonth(String month) {
    if (!_monthRe.hasMatch(month)) throw ArgumentError('Month must be YYYY-MM (got "$month")');
  }

  Future<void> save({required String month, required double total, required List<Bucket> buckets}) async {
    checkMonth(month);
    if (total < 0) throw ArgumentError('Budget total cannot be negative');
    final err = validateBuckets(buckets);
    if (err != null) throw ArgumentError(err);
    await db.upsertBudget(
      BudgetsCompanion(
        month: Value(month),
        total: Value(total),
        bucketsJson: Value(encodeBuckets([for (final b in buckets) b.toJson()])),
      ),
    );
  }

  Future<({double total, List<Bucket> buckets})?> get(String month) async {
    checkMonth(month);
    final row = await db.getBudget(month);
    if (row == null) return null;
    return (
      total: row.total,
      buckets: [for (final m in decodeBuckets(row.bucketsJson)) Bucket.fromJson(m)],
    );
  }

  /// Effective budget for [month]: the month's own row, else the most recent
  /// earlier row (carry-forward — a saved split holds until changed).
  /// Returns the source month too, so UI can say "carried from 2026-07".
  Future<({String sourceMonth, double total, List<Bucket> buckets})?> getEffective(String month) async {
    checkMonth(month);
    final own = await get(month);
    if (own != null) return (sourceMonth: month, total: own.total, buckets: own.buckets);
    final row = await db.latestBudgetAtOrBefore(month);
    if (row == null) return null;
    // latestBudgetAtOrBefore(month) with no exact row returns a strictly
    // earlier month here.
    return (
      sourceMonth: row.month,
      total: row.total,
      buckets: [for (final m in decodeBuckets(row.bucketsJson)) Bucket.fromJson(m)],
    );
  }

  /// Planned amount per bucket for a saved month.
  Future<Map<String, double>> allocation(String month) async {
    final b = await get(month);
    if (b == null) throw StateError('No budget for $month');
    return allocate(b.total, b.buckets);
  }
}
