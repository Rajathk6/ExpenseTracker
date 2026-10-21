/// Riverpod providers. Features depend on these, never on each other.
/// Tests override [databaseProvider] with `AppDatabase.memory()`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database.dart';
import 'auth/biometric_service.dart';
import 'auth/lock_service.dart';
import 'auth/pin_service.dart';
import 'backup/backup_service.dart';
import 'category_suggest.dart';
import '../features/budgets/bucket_math.dart';
import '../features/budgets/budget_insight.dart';
import '../features/budgets/budget_status.dart';
import '../features/budgets/budget_repository.dart';
import '../features/customization/account_repository.dart';
import '../features/groups/group_repository.dart';
import '../features/instruments/instrument_repository.dart';
import '../features/neutral/debt_repository.dart';
import '../features/reconcile/month_open_repository.dart';
import '../features/reconcile/month_start_service.dart';
import '../features/reconcile/networth_logic.dart';
import '../features/reconcile/reconcile_logic.dart';
import '../features/reconcile/reconcile_repository.dart';
import '../features/reports/reports_repository.dart';
import '../features/splits/split_repository.dart';
import '../features/transactions/recurring_service.dart';
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

final pinServiceProvider = Provider((ref) {
  // The vault decides the keychain namespace, so the real and demo vaults can
  // each own a `pin.hash` (see KeychainSecretStore).
  final state = ref.watch(lockProvider);
  final decoy = state.decoyMode && !state.locked;
  return PinService(ref.watch(databaseProvider), vault: decoy ? 'demo' : 'real');
});
final biometricServiceProvider = Provider((ref) => BiometricService());
final backupServiceProvider = Provider((ref) => BackupService(ref.watch(databaseProvider)));

final accountRepositoryProvider = Provider((ref) => AccountRepository(ref.watch(databaseProvider)));
final budgetRepositoryProvider = Provider((ref) => BudgetRepository(ref.watch(databaseProvider)));
final monthOpenRepositoryProvider = Provider((ref) => MonthOpenRepository(ref.watch(databaseProvider)));
final transactionRepositoryProvider = Provider((ref) => TransactionRepository(ref.watch(databaseProvider)));
final debtRepositoryProvider = Provider((ref) => DebtRepository(ref.watch(databaseProvider)));
final splitRepositoryProvider = Provider((ref) => SplitRepository(ref.watch(databaseProvider)));
final instrumentRepositoryProvider = Provider((ref) => InstrumentRepository(ref.watch(databaseProvider)));

final accountsProvider = StreamProvider((ref) => ref.watch(accountRepositoryProvider).watch());

/// Every account with its real balance (opening + everything that moved).
final accountBalancesProvider = FutureProvider((ref) => ref.watch(accountRepositoryProvider).balances());

final budgetProvider = FutureProvider.family<({double total, List<Bucket> buckets})?, String>((ref, month) async {
  final b = await ref.watch(budgetRepositoryProvider).get(month);
  if (b == null) return null;
  return (total: b.total, buckets: b.buckets);
});

/// Effective budget: own row, else carried forward from the latest earlier
/// month. Includes the source month so UI can say "carried from 2026-07".
final effectiveBudgetProvider =
    FutureProvider.family<({String sourceMonth, double total, List<Bucket> buckets})?, String>(
        (ref, month) => ref.watch(budgetRepositoryProvider).getEffective(month),);

final monthOpenProvider = FutureProvider.family<MonthOpenData?, String>(
    (ref, month) => ref.watch(monthOpenRepositoryProvider).get(month),);

/// Turns what the owner typed at month start into the budget row, opening
/// balances and repeating income the rest of the app actually reads.
final monthStartServiceProvider = Provider((ref) => MonthStartService(ref.watch(databaseProvider)));

// --- Transactions UI ---

final recentTransactionsProvider =
    FutureProvider((ref) => ref.watch(transactionRepositoryProvider).recent());

/// `YYYY-M` key → sums for that calendar month, neutral money (lend /
/// borrow / debt payoffs) excluded so borrowed cash never inflates it.
final monthSummaryProvider = FutureProvider.family<
    ({double inActual, double outActual, double inBudget, double outBudget, int count}), String>((ref, key) async {
  final parts = key.split('-');
  final start = DateTime(int.parse(parts[0]), int.parse(parts[1]));
  final end = DateTime(start.year, start.month + 1).subtract(const Duration(milliseconds: 1));
  return ref.watch(transactionRepositoryProvider).sumsBetween(start, end, excludeNeutral: true);
});

/// Spend per bucket label for a month key (negative budgetImpact sums).
final bucketSpendProvider = FutureProvider.family<Map<String, double>, String>((ref, key) async {
  final parts = key.split('-');
  final start = DateTime(int.parse(parts[0]), int.parse(parts[1]));
  final end = DateTime(start.year, start.month + 1).subtract(const Duration(milliseconds: 1));
  return ref.watch(transactionRepositoryProvider).bucketSpend(start, end);
});

final allItemsProvider = FutureProvider((ref) => ref.watch(transactionRepositoryProvider).allItems());

final itemRowsProvider =
    FutureProvider.family((ref, String item) => ref.watch(transactionRepositoryProvider).forItem(item));

/// Search inside a window: `{query, from, to}`. Defaults to the current month
/// so the first thing the owner sees is this month, not all of history.
typedef SearchScope = ({String query, DateTime? from, DateTime? to});

final scopedSearchProvider = FutureProvider.family<List<Transaction>, SearchScope>((ref, scope) {
  return ref
      .watch(transactionRepositoryProvider)
      .searchIn(scope.query, from: scope.from, to: scope.to);
});

/// Ranked category completions for the entry / intake / quick-add fields, so
/// half a category is enough (`gob` → `food junk gobi-65`). Pure ranking lives
/// in core/category_suggest.dart; this only feeds it the ledger's history.
/// autoDispose so a just-saved category shows up in the next entry form.
final categorySuggestProvider =
    FutureProvider.autoDispose.family<List<CategorySuggestion>, String>((ref, query) async {
  final db = ref.watch(transactionRepositoryProvider).db;
  final past = await db.distinctCategories();
  final uses = await db.categoryUsage();
  return suggestCategories(past, query: query, uses: uses);
});

/// Month budget as the owner framed it: income is the scale, the bucket split
/// is carried forward, and spending is measured against the planned amounts.
/// One pure function (budget_status.dart) so the card, the budget screen and
/// the alerts can never tell different stories.
final budgetStatusProvider = FutureProvider.family<BudgetStatusReport, String>((ref, month) async {
  final parts = month.split('-');
  final start = DateTime(int.parse(parts[0]), int.parse(parts[1]));
  final end = DateTime(start.year, start.month + 1).subtract(const Duration(milliseconds: 1));
  final sums = await ref.watch(transactionRepositoryProvider).sumsBetween(start, end, excludeNeutral: true);
  final spendByBucket = await ref.watch(transactionRepositoryProvider).bucketSpend(start, end);
  final budget = await ref.watch(budgetRepositoryProvider).getEffective(month);
  return buildBudgetStatus(
    income: sums.inBudget.abs(),
    budgetTotal: budget?.total ?? 0,
    spent: sums.outBudget.abs(),
    sourceMonth: budget?.sourceMonth ?? month,
    buckets: budget?.buckets ?? const [],
    bucketSpend: spendByBucket,
  );
});

/// Average spend per bucket over the months *before* [month] — the "what you
/// normally do" number the budget insights compare against (#7).
final budgetUsualProvider = FutureProvider.family<Map<String, double>, String>((ref, month) async {
  final parts = month.split('-');
  final start = DateTime(int.parse(parts[0]), int.parse(parts[1]));
  final end = DateTime(start.year, start.month + 1).subtract(const Duration(milliseconds: 1));
  final repo = ref.watch(transactionRepositoryProvider);
  // Six months back, so a seasonal change is visible but not a fluke.
  final from = DateTime(start.year, start.month - 6);
  final rows = await repo.db.transactionsBetween(from, end);
  final totals = <String, double>{};
  final counts = <String, int>{};
  for (final t in rows) {
    final key = (t.bucket ?? '').trim();
    if (key.isEmpty) continue;
    if (t.kind == 'lend' || t.kind == 'borrow' || t.linkType == 'debt') continue;
    final impact = t.absorbed == 1 ? t.actual : t.budgetImpact;
    if (impact >= 0) continue;
    totals[key] = (totals[key] ?? 0) + impact.abs();
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return {
    for (final key in totals.keys)
      // Average per month over the months that had this bucket.
      key: totals[key]! / (counts[key]! > 6 ? 6 : counts[key]!),
  };
});

/// The month's story: pace, estimate and the lines worth saying (#7).
final budgetInsightProvider = FutureProvider.family<BudgetInsight, String>((ref, month) async {
  final parts = month.split('-');
  final start = DateTime(int.parse(parts[0]), int.parse(parts[1]));
  final end = DateTime(start.year, start.month + 1).subtract(const Duration(milliseconds: 1));
  final repo = ref.watch(transactionRepositoryProvider);
  final sums = await repo.sumsBetween(start, end, excludeNeutral: true);
  final spendByBucket = await repo.bucketSpend(start, end);
  final usual = await ref.watch(budgetUsualProvider(month).future);
  final budget = await ref.watch(budgetRepositoryProvider).getEffective(month);
  final planned = budget == null || budget.total <= 0
      ? const <String, double>{}
      : allocate(budget.total, budget.buckets);
  return buildBudgetInsight(
    monthKey: month,
    at: DateTime.now(),
    income: sums.inBudget.abs(),
    budgetTotal: budget?.total ?? 0,
    spent: sums.outBudget.abs(),
    buckets: budget?.buckets ?? const [],
    spentByBucket: {for (final e in spendByBucket.entries) e.key: e.value.abs()},
    usualByBucket: usual,
    plannedByBucket: planned,
  );
});

/// Neutral rows the owner has not absorbed yet — the "does not count for the
/// month until you say so" list, with the button to change that (#10).
final unabsorbedNeutralProvider = FutureProvider<List<Transaction>>((ref) async {
  final rows = await ref.watch(transactionRepositoryProvider).all();
  return [
    for (final r in rows)
      if (TransactionRepository.isUnabsorbedNeutral(r)) r,
  ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
});

/// …and the ones already absorbed, so the decision can be undone from the same
/// place. Absorbing is never a one-way door.
final absorbedNeutralProvider = FutureProvider<List<Transaction>>((ref) async {
  final rows = await ref.watch(transactionRepositoryProvider).all();
  return [
    for (final r in rows)
      if (TransactionRepository.isNeutral(r) && r.absorbed == 1) r,
  ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
});

final recurringServiceProvider = Provider((ref) => RecurringService(ref.watch(databaseProvider)));

final groupRepositoryProvider = Provider((ref) => GroupRepository(ref.watch(databaseProvider)));

/// Every group, newest first (#9).
final groupsProvider = FutureProvider((ref) => ref.watch(groupRepositoryProvider).all());

/// Live balances for one group — the Splitwise-style "who owes whom".
final groupBalancesProvider = FutureProvider.family<GroupBalances?, String>(
    (ref, groupId) => ref.watch(groupRepositoryProvider).balances(groupId),);

final debtByIdProvider = FutureProvider.family<Debt?, String>(
    (ref, id) => ref.watch(debtRepositoryProvider).db.getDebt(id),);

final splitByIdProvider = FutureProvider.family<Split?, String>(
    (ref, id) => ref.watch(splitRepositoryProvider).db.getSplit(id),);

/// Repeating entries the owner set up (salary and friends).
final recurringRulesProvider = FutureProvider((ref) => ref.watch(recurringServiceProvider).all());

/// Entries that still need a category, a bucket or an account — the "ready to
/// fill" list on the front page (#17).
final readyToFillProvider = FutureProvider<List<Transaction>>((ref) async {
  final rows = await ref.watch(transactionRepositoryProvider).all();
  return [
    for (final r in rows)
      if (!TransactionRepository.isNeutral(r) && r.kind != 'transfer' && r.kind != 'split')
        if (r.categoryRaw.trim().isEmpty || (r.bucket ?? '').trim().isEmpty || r.accountId == null) r,
  ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
});

/// Months with any activity, newest first — search and report filters.
final monthsWithActivityProvider = FutureProvider((ref) => ref.watch(databaseProvider).monthsWithActivity());

/// Every counterparty the owner has ever dealt with, so the entry form can
/// offer "Ravi — lend / borrow / settle" instead of a free-text note (#8).
final peopleProvider = FutureProvider<List<String>>((ref) async {
  final debts = await ref.watch(debtRepositoryProvider).all();
  final names = <String>{for (final d in debts) d.counterparty.trim()};
  for (final group in await ref.watch(databaseProvider).allGroups()) {
    for (final m in await ref.watch(databaseProvider).membersOf(group.id)) {
      names.add(m.name.trim());
    }
  }
  return [for (final n in names.where((n) => n.isNotEmpty)) n]..sort();
});

// --- Debts UI ---

final openDebtsProvider = FutureProvider((ref) => ref.watch(debtRepositoryProvider).open());

final allDebtsProvider = FutureProvider((ref) => ref.watch(debtRepositoryProvider).all());

/// The money trail of one contract. autoDispose so a trail is re-read when the
/// screen is opened again — a cached list is how "I added money and the
/// history did not show it" happened.
final debtHistoryProvider =
    FutureProvider.autoDispose.family((ref, String debtId) => ref.watch(debtRepositoryProvider).history(debtId));

// --- Splits UI ---

final openSplitsProvider = FutureProvider((ref) => ref.watch(splitRepositoryProvider).open());

final allSplitsProvider = FutureProvider((ref) => ref.watch(splitRepositoryProvider).all());

/// The money trail of one split. autoDispose, for the same reason as the
/// debt trail above.
final splitHistoryProvider =
    FutureProvider.autoDispose.family((ref, String splitId) => ref.watch(splitRepositoryProvider).history(splitId));

/// Live outstanding (total − received − absorbed, whole rupees) for a split
/// contract. Drives the main-list tile: paid → shrinks → my share.
final splitOutstandingProvider = FutureProvider.family<int, String>((ref, splitId) async {
  final s = await ref.watch(splitRepositoryProvider).db.getSplit(splitId);
  return (s.totalPaid - s.received - s.absorbed).round().clamp(s.myShare.round(), s.totalPaid.round());
});

// --- Instruments vault (Phase 6, tracking-only) ---

final openInstrumentsProvider = FutureProvider((ref) => ref.watch(instrumentRepositoryProvider).open());

final allInstrumentsProvider = FutureProvider((ref) => ref.watch(instrumentRepositoryProvider).all());

// --- Reconcile / price memory / net worth (Phase 7, read-only vs ledger) ---

final reconcileRepositoryProvider = Provider((ref) => ReconcileRepository(ref.watch(databaseProvider)));

final monthReportProvider =
    FutureProvider.family<MonthReport, String>((ref, month) => ref.watch(reconcileRepositoryProvider).report(month));

/// Net worth: what the owner holds minus what the owner owes.
///
/// The formula (networth_logic.dart): cash in the accounts + investments +
/// money others owe me − money I owe others. Lends and borrows are *not*
/// plain movements here — the cash that left for a lend is balanced by the
/// receivable, and borrowed cash is balanced by the liability, so nothing is
/// counted twice and nothing is left out.
final netWorthProvider = FutureProvider(
  (ref) async {
    final accounts = await ref.watch(accountRepositoryProvider).list();
    final instruments = await ref.watch(instrumentRepositoryProvider).open();
    final txns = await ref.watch(transactionRepositoryProvider).all();
    final debts = await ref.watch(debtRepositoryProvider).all();
    final splits = await ref.watch(splitRepositoryProvider).all();
    var investCurrent = 0.0;
    var investBasis = 0.0;
    for (final i in instruments) {
      investCurrent += i.current;
      investBasis += i.invested;
    }

    // Every real movement of money, including lends and borrows: the cash
    // genuinely leaves the account when you lend it, and the receivable (or
    // the liability) is counted beside it — so the cash line here is the same
    // number the accounts screen shows. Transfers are excluded because they
    // are your own money moving between your own accounts.
    final moves = [
      for (final t in txns)
        if (t.kind != 'transfer') NetMove(t.occurredAt, t.actual),
    ];

    // Cash starts from the accounts' opening balances — the same number the
    // accounts screen shows, so the two can never disagree.
    var openingCash = 0.0;
    for (final a in accounts) {
      openingCash += a.openingBalance;
    }

    // Obligations at each month end: what is owed to the owner, what the owner
    // owes, and the split shares still to come back.
    final obligationSnapshots = <({String monthKey, Obligations obligations})>[];
    final now = DateTime.now();
    for (var back = 11; back >= 0; back--) {
      final month = DateTime(now.year, now.month - back);
      final key = monthKey(month);
      final end = DateTime(month.year, month.month + 1).subtract(const Duration(milliseconds: 1));
      var lent = 0.0;
      var borrowed = 0.0;
      for (final d in debts) {
        if (d.createdAt.isAfter(end)) continue;
        final paid = _paidBy(d.id, txns, end);
        final open = (d.principal - paid).clamp(0, double.infinity);
        if (d.direction == 'lent') {
          lent += open;
        } else {
          borrowed += open;
        }
      }
      var receivable = 0.0;
      for (final s in splits) {
        final front = txns.where((t) => t.linkType == 'split' && t.linkId == s.id).firstOrNull;
        if (front == null || front.occurredAt.isAfter(end)) continue;
        final back2 = _receivedBy(s.id, txns, end);
        final open = (s.totalPaid - s.myShare - back2.received - back2.absorbed).clamp(0, double.infinity);
        receivable += open;
      }
      obligationSnapshots.add((monthKey: key, obligations: Obligations(lent: lent, splitReceivable: receivable, borrowed: borrowed)));
    }

    final endKey = monthKey(now);
    final points = netWorthTimeline(
      moves: moves,
      obligationsByMonth: obligationSnapshots,
      investments: investCurrent,
      endMonthKey: endKey,
    );
    // The cash the timeline starts from is the accounts' opening balances.
    final withOpening = [
      for (final p in points)
        NetWorthPoint(
          monthKey: p.monthKey,
          cash: p.cash + openingCash,
          investments: p.investments,
          owedToYou: p.owedToYou,
          youOwe: p.youOwe,
        ),
    ];
    final last = withOpening.isEmpty
        ? NetWorthPoint(monthKey: endKey, cash: 0, investments: 0, owedToYou: 0, youOwe: 0)
        : withOpening.last;
    return (
      points: withOpening,
      cash: last.cash,
      investNow: investCurrent,
      investGains: investCurrent - investBasis,
      owedToYou: last.owedToYou,
      youOwe: last.youOwe,
      net: last.net,
    );
  },
);

/// How much of a debt contract had been paid back by [end].
double _paidBy(String debtId, List<Transaction> txns, DateTime end) {
  var paid = 0.0;
  for (final t in txns) {
    if (t.linkType != 'debt' || t.linkId != debtId) continue;
    if (t.kind != 'settle' || t.occurredAt.isAfter(end)) continue;
    paid += t.actual.abs();
  }
  return paid;
}

/// How much of a split had come back (and how much was written off) by [end].
({double received, double absorbed}) _receivedBy(String splitId, List<Transaction> txns, DateTime end) {
  var received = 0.0;
  var absorbed = 0.0;
  for (final t in txns) {
    if (t.linkType != 'split' || t.linkId != splitId) continue;
    if (t.occurredAt.isAfter(end)) continue;
    if (t.kind == 'settle') received += t.actual.abs();
    if (t.kind == 'absorb') absorbed += t.budgetImpact.abs();
  }
  return (received: received, absorbed: absorbed);
}

String _shiftedKey(int year, int month, int back) {
  var y = year, m = month - back;
  while (m <= 0) {
    m += 12;
    y--;
  }
  return '$y-${m.toString().padLeft(2, '0')}';
}

/// Budget-planning truth per month for the 3 months ending at [key]
/// (oldest first). Backs the simulator math in features/budgets/simulator.dart,
/// whose preview screen the owner retired in the UX batch.
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
