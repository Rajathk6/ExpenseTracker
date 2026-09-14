/// Month-open repository: the optional month-start form (budget guess,
/// bank/cash balances, card limit). Everything nullable — prompt, don't
/// require. Editable any time later.
library;

import 'package:drift/drift.dart';

import '../../core/database.dart';
import '../budgets/budget_repository.dart' show BudgetRepository;

class MonthOpenRepository {
  final AppDatabase db;
  const MonthOpenRepository(this.db);

  Future<MonthOpenData?> get(String month) {
    BudgetRepository.checkMonth(month);
    return db.getMonthOpen(month);
  }

  Future<void> save({
    required String month,
    double? budgetIn,
    double? budgetOut,
    double? bankBalance,
    double? cashBalance,
    double? cardLimit,
  }) {
    BudgetRepository.checkMonth(month);
    return db.upsertMonthOpen(
      MonthOpenCompanion(
        month: Value(month),
        budgetIn: Value(budgetIn),
        budgetOut: Value(budgetOut),
        bankBalance: Value(bankBalance),
        cashBalance: Value(cashBalance),
        cardLimit: Value(cardLimit),
      ),
    );
  }
}
