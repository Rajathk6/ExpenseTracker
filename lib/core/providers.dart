/// Riverpod providers. Features depend on these, never on each other.
/// Tests override [databaseProvider] with `AppDatabase.memory()`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database.dart';
import 'auth/lock_service.dart';
import 'auth/pin_service.dart';
import 'backup/backup_service.dart';
import '../features/budgets/bucket_math.dart';
import '../features/budgets/budget_repository.dart';
import '../features/customization/account_repository.dart';
import '../features/instruments/instrument_repository.dart';
import '../features/neutral/debt_repository.dart';
import '../features/reconcile/networth_logic.dart';
import '../features/reconcile/reconcile_logic.dart';
import '../features/reconcile/reconcile_repository.dart';
import '../features/reports/reports_repository.dart';
import '../features/splits/split_repository.dart';
import '../features/transactions/transaction_repository.dart';

/// File handles opened once in main(). Tests override [databaseProvider]
/// with `AppDatabase.memory()` instead — never touch these two there.
final realDatabaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('Override in main()'));
final demoDatabaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('Override in main()'));

/// Security gate: the decoy PIN swaps the whole DB handle, so the demo
/// vault is a separate file that never sees real rows.
final databaseProvider = Provider<AppDatabase>((ref) {
  final decoy = ref.watch(lockProvider.select((s) => s.decoyMode));
  if (decoy && !ref.watch(lockProvider.select((s) => s.locked))) {
    return ref.watch(demoDatabaseProvider);
  }
  return ref.watch(realDatabaseProvider);
});

final pinServiceProvider = Provider((ref) => PinService(ref.watch(databaseProvider)));
final backupServiceProvider = Provider((ref) => BackupService(ref.watch(databaseProvider)));

final accountRepositoryProvider = Provider((ref) => AccountRepository(ref.watch(databaseProvider)));
final budgetRepositoryProvider = Provider((ref) => BudgetRepository(ref.watch(databaseProvider)));
final transactionRepositoryProvider = Provider((ref) => TransactionRepository(ref.watch(databaseProvider)));
final debtRepositoryProvider = Provider((ref) => DebtRepository(ref.watch(databaseProvider)));
final splitRepositoryProvider = Provider((ref) => SplitRepository(ref.watch(databaseProvider)));
final instrumentRepositoryProvider = Provider((ref) => InstrumentRepository(ref.watch(databaseProvider)));

final accountsProvider = StreamProvider((ref) => ref.watch(accountRepositoryProvider).watch());

final budgetProvider = FutureProvider.family<({double total, List<Bucket> buckets})?, String>((ref, month) async {
  final b = await ref.watch(budgetRepositoryProvider).get(month);
  if (b == null) return null;
  return (total: b.total, buckets: b.buckets);
});

// --- Transactions UI ---

final recentTransactionsProvider =
    FutureProvider((ref) => ref.watch(transactionRepositoryProvider).recent());

/// `YYYY-M` key → sums for that calendar month.
final monthSummaryProvider = FutureProvider.family<
    ({double inActual, double outActual, double inBudget, double outBudget, int count}), String>((ref, key) async {
  final parts = key.split('-');
  final start = DateTime(int.parse(parts[0]), int.parse(parts[1]));
  final end = DateTime(start.year, start.month + 1).subtract(const Duration(milliseconds: 1));
  return ref.watch(transactionRepositoryProvider).sumsBetween(start, end);
});

final categoryHistoryProvider =
    FutureProvider((ref) => ref.watch(transactionRepositoryProvider).db.distinctCategories());

final allItemsProvider = FutureProvider((ref) => ref.watch(transactionRepositoryProvider).allItems());

final itemRowsProvider =
    FutureProvider.family((ref, String item) => ref.watch(transactionRepositoryProvider).forItem(item));

/// Live search across raw category / levels / item.
final searchProvider =
    FutureProvider.family((ref, String query) => ref.watch(transactionRepositoryProvider).search(query));

// --- Debts UI ---

final openDebtsProvider = FutureProvider((ref) => ref.watch(debtRepositoryProvider).open());

final allDebtsProvider = FutureProvider((ref) => ref.watch(debtRepositoryProvider).all());

final debtHistoryProvider =
    FutureProvider.family((ref, String debtId) => ref.watch(debtRepositoryProvider).history(debtId));

// --- Splits UI ---

final openSplitsProvider = FutureProvider((ref) => ref.watch(splitRepositoryProvider).open());

final allSplitsProvider = FutureProvider((ref) => ref.watch(splitRepositoryProvider).all());

final splitHistoryProvider =
    FutureProvider.family((ref, String splitId) => ref.watch(splitRepositoryProvider).history(splitId));

// --- Instruments vault (Phase 6, tracking-only) ---

final openInstrumentsProvider = FutureProvider((ref) => ref.watch(instrumentRepositoryProvider).open());

final allInstrumentsProvider = FutureProvider((ref) => ref.watch(instrumentRepositoryProvider).all());

// --- Reconcile / price memory / net worth (Phase 7, read-only vs ledger) ---

final reconcileRepositoryProvider = Provider((ref) => ReconcileRepository(ref.watch(databaseProvider)));

final monthReportProvider =
    FutureProvider.family<MonthReport, String>((ref, month) => ref.watch(reconcileRepositoryProvider).report(month));

/// Trailing-12-month net-worth timeline ending at the current month, plus
/// the current breakdown. Investments + debts use current manual values.
final netWorthProvider = FutureProvider(
  (ref) async {
    final accounts = await ref.watch(accountRepositoryProvider).list();
    final instruments = await ref.watch(instrumentRepositoryProvider).open();
    final debts = await ref.watch(debtRepositoryProvider).open();
    final txns = await ref.watch(transactionRepositoryProvider).all();
    var openings = 0.0;
    for (final a in accounts) {
      openings += a.openingBalance;
    }
    var investCurrent = 0.0;
    for (final i in instruments) {
      investCurrent += i.current;
    }
    final debtNetValue = debtNet([
      for (final d in debts) (direction: d.direction, principal: d.principal, paid: d.paid),
    ]);
    final now = DateTime.now();
    final endKey = monthKey(DateTime(now.year, now.month));
    final points = netWorthTimeline(
      openings: openings,
      moves: [for (final t in txns) (at: t.occurredAt, actual: t.actual)],
      investCurrent: investCurrent,
      debtNetValue: debtNetValue,
      endKey: endKey,
    );
    final bankNow = points.isEmpty
        ? openings
        : bankAt(
            openings: openings,
            moves: [for (final t in txns) (at: t.occurredAt, actual: t.actual)],
            monthEnd: DateTime(now.year, now.month + 1).subtract(const Duration(milliseconds: 1)),
          );
    return (
      points: points,
      bankNow: bankNow,
      investNow: investCurrent,
      debtNetValue: debtNetValue,
    );
  },
);

String _shiftedKey(int year, int month, int back) {
  var y = year, m = month - back;
  while (m <= 0) {
    m += 12;
    y--;
  }
  return '$y-${m.toString().padLeft(2, '0')}';
}

/// Budget-planning truth per month for the 3 months ending at [key]
/// (oldest first). Used by the budget simulator.
final pastOutProvider = FutureProvider.family<List<({String key, double out})>, String>((ref, key) async {
  final parts = key.split('-');
  final year = int.parse(parts[0]), month = int.parse(parts[1]);
  final repo = ref.watch(transactionRepositoryProvider);
  final rows = <({String key, double out})>[];
  for (var back = 2; back >= 0; back--) {
    final k = _shiftedKey(year, month, back);
    final kp = k.split('-');
    final start = DateTime(int.parse(kp[0]), int.parse(kp[1]));
    final end = DateTime(start.year, start.month + 1).subtract(const Duration(milliseconds: 1));
    final s = await repo.sumsBetween(start, end);
    rows.add((key: k, out: s.outBudget.abs()));
  }
  return rows;
});

// --- Reports dashboard (Phase 8, read-only) ---

final reportsRepositoryProvider = Provider((ref) => ReportsRepository(ref.watch(databaseProvider)));

final dashboardProvider =
    FutureProvider.family<DashboardData, String>((ref, month) => ref.watch(reportsRepositoryProvider).dashboard(month));
