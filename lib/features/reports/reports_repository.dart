/// Reports repository: read-only dashboards assembled from the ledger.
/// Never writes — corrections stay append-only reversals via the transaction
/// repository. Spend figures use planning truth (budgetImpact).
library;

import '../../core/database.dart';
import '../../core/months.dart';
import 'reports_logic.dart';

/// One month in the spend trend.
class TrendPoint {
  final String key;
  final double outBudget;
  final double? budgetTotal;
  const TrendPoint({required this.key, required this.outBudget, required this.budgetTotal});
}

/// Wrapped-style year summary.
class WrappedYear {
  final int year;
  final double inActual;
  final double outBudget;
  final String? topCategory;
  final String? topItem;
  final String? biggestMonth;
  final int txnCount;
  const WrappedYear({
    required this.year,
    required this.inActual,
    required this.outBudget,
    required this.topCategory,
    required this.topItem,
    required this.biggestMonth,
    required this.txnCount,
  });
}

/// Everything the dashboard screen needs in one fetch.
class DashboardData {
  final String month;
  final List<TrendPoint> trend;
  final List<({String label, double out})> categories;
  final double cashOut;
  final double digitalOut;
  final double budgetTotal;
  final double outBudget;
  final WrappedYear wrapped;
  final List<Transaction> monthTxns;
  final Map<String, String> accountKinds;
  const DashboardData({
    required this.month,
    required this.trend,
    required this.categories,
    required this.cashOut,
    required this.digitalOut,
    required this.budgetTotal,
    required this.outBudget,
    required this.wrapped,
    required this.monthTxns,
    required this.accountKinds,
  });
}

class ReportsRepository {
  final AppDatabase db;
  const ReportsRepository(this.db);

  Future<DashboardData> dashboard(String month, {int trendMonths = 6, int topN = 8}) async {
    final bounds = monthBounds(month);
    final monthTxns = await db.transactionsBetween(bounds.start, bounds.end);

    final kinds = <String, String>{};
    for (final a in await db.allAccounts()) {
      kinds[a.id] = a.kind;
    }

    var outBudget = 0.0;
    final catMoves = <TaggedOut>[];
    final cashMoves = <({String kind, double out})>[];
    for (final t in monthTxns) {
      if (t.budgetImpact < 0) {
        final out = -t.budgetImpact;
        outBudget += out;
        catMoves.add((tag: t.level0, out: out));
        cashMoves.add((kind: kinds[t.accountId] ?? 'digital', out: out));
      }
    }
    final categories = topSlices(sumsByTag(catMoves), topN);
    final split = splitCashDigital(cashMoves);
    final budgetTotal = (await db.getBudget(month))?.total ?? 0;

    // Trend: trailing window ending at [month], oldest first.
    final startKey = shiftMonthKey(month, -(trendMonths - 1));
    final windowTxns = await db.transactionsBetween(monthStart(startKey), bounds.end);
    final outByMonth = <String, double>{};
    for (final t in windowTxns) {
      if (t.budgetImpact < 0) {
        final k = monthKey(t.occurredAt);
        outByMonth[k] = (outByMonth[k] ?? 0) + (-t.budgetImpact);
      }
    }
    final trend = <TrendPoint>[];
    for (var back = trendMonths - 1; back >= 0; back--) {
      final k = shiftMonthKey(month, -back);
      trend.add(TrendPoint(key: k, outBudget: outByMonth[k] ?? 0, budgetTotal: (await db.getBudget(k))?.total));
    }

    return DashboardData(
      month: month,
      trend: trend,
      categories: categories,
      cashOut: split.cash,
      digitalOut: split.digital,
      budgetTotal: budgetTotal,
      outBudget: outBudget,
      wrapped: await wrapped(monthStart(month).year),
      monthTxns: monthTxns,
      accountKinds: kinds,
    );
  }

  Future<WrappedYear> wrapped(int year) async {
    final start = DateTime(year);
    final end = DateTime(year + 1).subtract(const Duration(milliseconds: 1));
    final txns = await db.transactionsBetween(start, end);
    var inActual = 0.0, outBudget = 0.0;
    final catMoves = <TaggedOut>[];
    final itemMoves = <TaggedOut>[];
    final monthMoves = <TaggedOut>[];
    for (final t in txns) {
      if (t.actual > 0) inActual += t.actual;
      if (t.budgetImpact < 0) {
        final out = -t.budgetImpact;
        outBudget += out;
        catMoves.add((tag: t.level0, out: out));
        if (t.item != null) itemMoves.add((tag: t.item, out: out));
        monthMoves.add((tag: monthKey(t.occurredAt), out: out));
      }
    }
    return WrappedYear(
      year: year,
      inActual: inActual,
      outBudget: outBudget,
      topCategory: pickTop(sumsByTag(catMoves)),
      topItem: pickTop(sumsByTag(itemMoves)),
      biggestMonth: pickTop(sumsByTag(monthMoves)),
      txnCount: txns.length,
    );
  }
}
