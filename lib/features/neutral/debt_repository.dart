/// Debt repository: lend/borrow contracts + partial payoffs + auto-settle.
/// Every linked transaction carries budgetImpact 0, so months never inflate.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/database.dart';
import 'debt_logic.dart';

class DebtRepository {
  final AppDatabase db;
  const DebtRepository(this.db);

  Future<Debt> _create({
    required String counterparty,
    required String direction,
    required double principal,
    String? accountId,
    required DateTime at,
    String? note,
    DateTime? dueDate,
    DateTime? nudgeDate,
    String? categoryRaw,
  }) async {
    final who = counterparty.trim();
    if (who.isEmpty) throw ArgumentError('Counterparty cannot be empty');
    if (direction != 'lent' && direction != 'borrowed') {
      throw ArgumentError('direction must be lent/borrowed');
    }
    if (principal <= 0) throw ArgumentError('Principal must be above zero');
    final id = const Uuid().v4();
    await db.insertDebt(
      DebtsCompanion(
        id: Value(id),
        counterparty: Value(who),
        direction: Value(direction),
        principal: Value(principal),
        note: Value(note),
        dueDate: Value(dueDate),
        nudgeDate: Value(nudgeDate),
      ),
    );
    // Principal movement: out for lent, in for borrowed. Never budgeted.
    await db.insertTransaction(
      TransactionsCompanion(
        id: Value(const Uuid().v4()),
        kind: Value(direction == 'lent' ? 'lend' : 'borrow'),
        actual: Value(direction == 'lent' ? -principal : principal),
        budgetImpact: const Value(0),
        occurredAt: Value(at),
        categoryRaw: Value(categoryRaw ?? (direction == 'lent' ? 'lend $who' : 'borrow $who')),
        level0: Value(direction == 'lent' ? 'lend' : 'borrow'),
        level1: Value(who.toLowerCase()),
        note: Value(note),
        accountId: Value(accountId),
        linkId: Value(id),
        linkType: const Value('debt'),
      ),
    );
    return db.getDebt(id);
  }

  Future<Debt> lend({
    required String counterparty,
    required double principal,
    String? accountId,
    DateTime? at,
    String? note,
    DateTime? dueDate,
    DateTime? nudgeDate,
  }) =>
      _create(
        counterparty: counterparty,
        direction: 'lent',
        principal: principal,
        accountId: accountId,
        at: at ?? DateTime.now(),
        note: note,
        dueDate: dueDate,
        nudgeDate: nudgeDate,
      );

  Future<Debt> borrow({
    required String counterparty,
    required double principal,
    String? accountId,
    DateTime? at,
    String? note,
    DateTime? dueDate,
    DateTime? nudgeDate,
  }) =>
      _create(
        counterparty: counterparty,
        direction: 'borrowed',
        principal: principal,
        accountId: accountId,
        at: at ?? DateTime.now(),
        note: note,
        dueDate: dueDate,
        nudgeDate: nudgeDate,
      );

  /// Records one payoff chunk. Auto-flips to `settled` on full payoff.
  Future<Debt> pay({
    required String debtId,
    required double amount,
    String? accountId,
    DateTime? at,
    String? note,
  }) async {
    final debt = await db.getDebt(debtId);
    if (debt.status != 'open') throw StateError('Debt is already settled');
    final actual = payoffActual(
      direction: debt.direction,
      amount: amount,
      principal: debt.principal,
      paid: debt.paid,
    );
    await db.insertTransaction(
      TransactionsCompanion(
        id: Value(const Uuid().v4()),
        kind: const Value('settle'),
        actual: Value(actual),
        budgetImpact: const Value(0),
        occurredAt: Value(at ?? DateTime.now()),
        categoryRaw: Value('settle ${debt.counterparty}'),
        level0: const Value('settle'),
        level1: Value(debt.counterparty.toLowerCase()),
        note: Value(note),
        accountId: Value(accountId),
        linkId: Value(debtId),
        linkType: const Value('debt'),
      ),
    );
    final newPaid = debt.paid + amount;
    final settled = newPaid >= debt.principal - 0.005;
    await db.updateDebt(
      debtId,
      DebtsCompanion(
        paid: Value(newPaid),
        status: Value(settled ? 'settled' : 'open'),
      ),
    );
    return db.getDebt(debtId);
  }

  Future<List<Debt>> open() => db.openDebts();
  Future<List<Debt>> all() => db.allDebts();
  Future<List<Transaction>> history(String debtId) => db.debtHistory(debtId);
}
