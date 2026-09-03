/// Riverpod providers. Features depend on these, never on each other.
/// Tests override [databaseProvider] with `AppDatabase.memory()`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database.dart';
import '../features/budgets/bucket_math.dart';
import '../features/budgets/budget_repository.dart';
import '../features/customization/account_repository.dart';
import '../features/transactions/transaction_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('Override with real or memory DB'));

final accountRepositoryProvider = Provider((ref) => AccountRepository(ref.watch(databaseProvider)));
final budgetRepositoryProvider = Provider((ref) => BudgetRepository(ref.watch(databaseProvider)));
final transactionRepositoryProvider = Provider((ref) => TransactionRepository(ref.watch(databaseProvider)));

final accountsProvider = StreamProvider((ref) => ref.watch(accountRepositoryProvider).watch());

final budgetProvider = FutureProvider.family<({double total, List<Bucket> buckets})?, String>((ref, month) async {
  final b = await ref.watch(budgetRepositoryProvider).get(month);
  if (b == null) return null;
  return (total: b.total, buckets: b.buckets);
});
