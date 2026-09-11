/// Reconcile repository: month open/close snapshots + per-account report.
/// Snapshots are planning inputs (typed at month-start, counted at
/// month-end); the ledger stays append-only and is only ever read here.
library;

import 'package:drift/drift.dart';

import '../../core/database.dart';
import 'reconcile_logic.dart';

/// One account's row in the month report. [counted]/[gap]/[status] are null
/// until the physical close is counted.
class AccountRecon {
  final String accountId;
  final String name;
  final String kind;
  final double open;
  final bool hasOpen;
  final double inActual;
  final double outActual;
  final double expected;
  final double? counted;
  final double? gap;
  final String? status;
  const AccountRecon({
    required this.accountId,
    required this.name,
    required this.kind,
    required this.open,
    required this.hasOpen,
    required this.inActual,
    required this.outActual,
    required this.expected,
    required this.counted,
    required this.gap,
    required this.status,
  });
}

/// Whole-month report: per-account rows plus totals and planning truth.
class MonthReport {
  final String month;
  final List<AccountRecon> rows;
  final double totalOpen;
  final double totalExpected;
  final double totalCounted;
  final double totalGap;
  final int countedCount;
  final double outBudget;
  final int txnCount;
  const MonthReport({
    required this.month,
    required this.rows,
    required this.totalOpen,
    required this.totalExpected,
    required this.totalCounted,
    required this.totalGap,
    required this.countedCount,
    required this.outBudget,
    required this.txnCount,
  });
}

class ReconcileRepository {
  final AppDatabase db;
  const ReconcileRepository(this.db);

  Future<void> setOpen({required String month, required String accountId, required double value}) async {
    final ex = await db.getSnapshot(month, accountId);
    await db.upsertSnapshot(
      SnapshotsCompanion(
        month: Value(month),
        accountId: Value(accountId),
        openBalance: Value(value),
        countedClose: Value(ex?.countedClose ?? 0),
        hasClose: Value(ex?.hasClose ?? 0),
      ),
    );
  }

  Future<void> setClose({required String month, required String accountId, required double value}) async {
    if (value < 0) throw ArgumentError('Counted close cannot be negative');
    final ex = await db.getSnapshot(month, accountId);
    await db.upsertSnapshot(
      SnapshotsCompanion(
        month: Value(month),
        accountId: Value(accountId),
        openBalance: Value(ex?.openBalance ?? 0),
        countedClose: Value(value),
        hasClose: const Value(1),
      ),
    );
  }

  Future<MonthReport> report(String month) async {
    final bounds = monthBounds(month);
    final accounts = await db.allAccounts();
    final snaps = await db.snapshotsForMonth(month);
    final snapByAcct = {for (final s in snaps) s.accountId: s};
    final txns = await db.transactionsBetween(bounds.start, bounds.end);

    final inBy = <String?, double>{};
    final outBy = <String?, double>{};
    var outBudget = 0.0;
    for (final t in txns) {
      if (t.actual >= 0) {
        inBy[t.accountId] = (inBy[t.accountId] ?? 0) + t.actual;
      } else {
        outBy[t.accountId] = (outBy[t.accountId] ?? 0) + (-t.actual);
      }
      if (t.budgetImpact < 0) outBudget += -t.budgetImpact;
    }

    final rows = <AccountRecon>[];
    for (final a in accounts) {
      final snap = snapByAcct[a.id];
      final inflow = inBy[a.id] ?? 0;
      final outflow = outBy[a.id] ?? 0;
      final open = snap?.openBalance ?? 0;
      final expected = expectedClose(open: open, inflows: inflow, outflows: outflow);
      final counted = (snap?.hasClose ?? 0) == 1 ? snap!.countedClose : null;
      final gap = counted == null ? null : reconcileGap(expected: expected, counted: counted);
      rows.add(
        AccountRecon(
          accountId: a.id,
          name: a.name,
          kind: a.kind,
          open: open,
          hasOpen: snap != null,
          inActual: inflow,
          outActual: outflow,
          expected: expected,
          counted: counted,
          gap: gap,
          status: gap == null ? null : reconcileStatus(gap),
        ),
      );
    }
    // Ledger rows with no account link still move money — show them honestly
    // instead of silently dropping them.
    if ((inBy[null] ?? 0) != 0 || (outBy[null] ?? 0) != 0) {
      final inflow = inBy[null] ?? 0;
      final outflow = outBy[null] ?? 0;
      rows.add(
        AccountRecon(
          accountId: '',
          name: 'No account',
          kind: '—',
          open: 0,
          hasOpen: false,
          inActual: inflow,
          outActual: outflow,
          expected: expectedClose(open: 0, inflows: inflow, outflows: outflow),
          counted: null,
          gap: null,
          status: null,
        ),
      );
    }

    var totalOpen = 0.0, totalExpected = 0.0, totalCounted = 0.0, totalGap = 0.0;
    var countedCount = 0;
    for (final r in rows) {
      totalOpen += r.open;
      totalExpected += r.expected;
      if (r.counted != null && r.gap != null) {
        totalCounted += r.counted!;
        totalGap += r.gap!;
        countedCount++;
      }
    }
    return MonthReport(
      month: month,
      rows: rows,
      totalOpen: totalOpen,
      totalExpected: totalExpected,
      totalCounted: totalCounted,
      totalGap: totalGap,
      countedCount: countedCount,
      outBudget: outBudget,
      txnCount: txns.length,
    );
  }
}
