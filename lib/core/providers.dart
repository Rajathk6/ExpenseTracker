/// Riverpod providers. Features depend on these, never on each other.
/// Tests override [databaseProvider] with `AppDatabase.memory()`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database.dart';
import '../features/budgets/bucket_math.dart';
import '../features/budgets/budget_repository.dart';
import '../features/customization/account_repository.dart';
import '../features/neutral/debt_repository.dart';
import '../features/transactions/transaction_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('Override with real or memory DB'));

final accountRepositoryProvider = Provider((ref) => AccountRepository(ref.watch(databaseProvider)));
final budgetRepositoryProvider = Provider((ref) => BudgetRepository(ref.watch(databaseProvider)));
final transactionRepositoryProvider = Provider((ref) => TransactionRepository(ref.watch(databaseProvider)));
final debtRepositoryProvider = Provider((ref) => DebtRepository(ref.watch(databaseProvider)));

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
