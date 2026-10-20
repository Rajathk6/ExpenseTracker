/// Month-start opener: one place that turns what the owner typed at the start
/// of a month into the things the rest of the app actually reads.
///
/// Before this existed the dialog saved a row nobody looked at — the budget
/// screen, the reconcile report and net worth all kept saying "no data".
/// Saving now writes, in one shot:
/// - the month's **budget row** with the owner's bucket split applied
///   (auto-split, carried forward until they change it — earlier months are
///   untouched because every month is its own row);
/// - the **opening snapshots** (bank + cash) so reconcile can compute true
///   spend from day one;
/// - a **recurring salary/income rule** when an income figure is given, so the
///   same money does not have to be retyped every month.
library;

import 'package:drift/drift.dart';

import '../../core/database.dart';
import '../budgets/bucket_math.dart';
import '../budgets/budget_repository.dart';
import '../reconcile/month_open_repository.dart';

/// Result of [applyMonthStart], for the UI to report what it did.
class MonthStartResult {
  final bool budgetWritten;
  final List<Bucket> bucketsUsed;
  final int snapshotsWritten;
  final int recurringRulesCreated;

  const MonthStartResult({
    required this.budgetWritten,
    required this.bucketsUsed,
    required this.snapshotsWritten,
    required this.recurringRulesCreated,
  });

  /// One line for the snackbar — "did nothing" must never be silent.
  String get summary {
    final parts = <String>[];
    if (budgetWritten) parts.add('budget ${bucketsUsed.map((b) => b.name).join('/')} split');
    if (snapshotsWritten > 0) parts.add('$snapshotsWritten opening balance(s)');
    if (recurringRulesCreated > 0) parts.add('$recurringRulesCreated repeating entry(ies)');
    return parts.isEmpty ? 'Nothing to apply — all fields were left blank' : parts.join(' · ');
  }
}

class MonthStartService {
  final AppDatabase db;
  const MonthStartService(this.db);

  BudgetRepository get _budgets => BudgetRepository(db);
  MonthOpenRepository get _open => MonthOpenRepository(db);

  /// Applies everything in [values]; null fields are skipped, never zeroed.
  /// The budget is applied to the accounts the owner already has — the month
  /// card never asks them to set up accounts again (#7).
  Future<MonthStartResult> apply({
    required String month,
    double? budgetIn,
    double? budgetOut,
    double? bankBalance,
    double? cashBalance,
    double? cardLimit,
    double? salaryAmount,
    String? salaryCategory,
    String? salaryAccountId,
    int salaryMonths = 0,
    int salaryDayOfMonth = 1,
  }) async {
    BudgetRepository.checkMonth(month);
    await _open.save(
      month: month,
      budgetIn: budgetIn,
      budgetOut: budgetOut,
      bankBalance: bankBalance,
      cashBalance: cashBalance,
      cardLimit: cardLimit,
    );

    // 1) Budget row, auto-split across the bucket percentages.
    var budgetWritten = false;
    var bucketsUsed = const <Bucket>[];
    if (budgetOut != null && budgetOut > 0) {
      final effective = await _budgets.getEffective(month);
      final buckets = (effective?.buckets.isNotEmpty ?? false) ? effective!.buckets : defaultBuckets;
      await _budgets.save(month: month, total: budgetOut, buckets: buckets);
      budgetWritten = true;
      bucketsUsed = buckets;
    }

    // 2) Opening balances, so the reconcile report has a starting point.
    var snapshots = 0;
    final accounts = await db.allAccounts();
    Future<void> snapshotFor(String kindContains, double? value) async {
      if (value == null) return;
      // Only a *matching* account is written. Guessing "probably the first one"
      // put a bank balance on a wallet, which then made reconcile lie.
      Account? account;
      for (final a in accounts) {
        if (a.kind.toLowerCase().contains(kindContains)) {
          account = a;
          break;
        }
      }
      if (account == null) return;
      await db.upsertSnapshot(
        SnapshotsCompanion(
          month: Value(month),
          accountId: Value(account.id),
          openBalance: Value(value),
        ),
      );
      snapshots++;
    }

    await snapshotFor('cash', cashBalance);
    await snapshotFor('bank', bankBalance);

    // 3) A repeating income entry, if the owner wants the salary typed once.
    var rules = 0;
    if (salaryAmount != null && salaryAmount > 0 && salaryMonths > 0) {
      // One rule per (month, label): adding a second salary does not overwrite
      // the first, and re-saving the same one keeps its progress.
      final tag = (salaryCategory ?? 'salary').trim().toLowerCase().replaceAll(' ', '-');
      final existing = (await db.allRecurringRules())
          .where((r) => r.startMonth == month && r.categoryRaw.toLowerCase() == tag)
          .toList();
      await db.upsertRecurringRule(
        RecurringRulesCompanion(
          id: Value(existing.isEmpty ? 'rule-$month-$tag' : existing.first.id),
          kind: const Value('in'),
          amount: Value(salaryAmount),
          categoryRaw: Value((salaryCategory == null || salaryCategory.trim().isEmpty) ? 'salary' : salaryCategory.trim().toLowerCase()),
          bucket: const Value(null),
          accountId: Value(salaryAccountId),
          dayOfMonth: Value(salaryDayOfMonth.clamp(1, 28)),
          months: Value(salaryMonths),
          startMonth: Value(month),
        ),
      );
      rules++;
    }

    return MonthStartResult(
      budgetWritten: budgetWritten,
      bucketsUsed: bucketsUsed,
      snapshotsWritten: snapshots,
      recurringRulesCreated: rules,
    );
  }
}