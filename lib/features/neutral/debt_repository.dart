/// Debt repository: lend/borrow contracts + partial payoffs + auto-settle.
/// Every linked transaction carries budgetImpact 0, so months never inflate.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/database.dart';
import 'debt_logic.dart';

/// People are matched by their name, loosely: case and extra spaces do not
/// make a new person. "karthik", "Karthik" and " Karthik " are one contract.
String normaliseName(String name) => name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

class DebtRepository {
  final AppDatabase db;
  const DebtRepository(this.db);

  /// The open contract with this person, if there is one. Names are matched
  /// loosely (case and spaces do not matter) so "karthik", "Karthik" and
  /// " Karthik " are one person and one contract — not three.
  Future<Debt?> openContractFor(String counterparty) async {
    final want = normaliseName(counterparty);
    if (want.isEmpty) return null;
    for (final d in await db.openDebts()) {
      if (d.direction != 'lent' && d.direction != 'borrowed') continue;
      if (normaliseName(d.counterparty) == want) return d;
    }
    return null;
  }

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

  /// Adds to the existing contract with this person when there is one, so
  /// lending to Karthik twice does not create two cards (#2). The person's
  /// name is matched loosely, and the second amount lands on the first
  /// contract's trail.
  Future<Debt> lendTo({
    required String counterparty,
    required double principal,
    String? accountId,
    DateTime? at,
    String? note,
    DateTime? dueDate,
    DateTime? nudgeDate,
    String? ownerName,
  }) async {
    if (ownerName != null && normaliseName(ownerName) == normaliseName(counterparty)) {
      throw ArgumentError('You cannot lend money to yourself');
    }
    final existing = await openContractFor(counterparty);
    if (existing != null && existing.direction == 'lent') {
      await _addTo(existing, principal, accountId: accountId, at: at, note: note);
      return db.getDebt(existing.id);
    }
    return lend(
      counterparty: counterparty,
      principal: principal,
      accountId: accountId,
      at: at,
      note: note,
      dueDate: dueDate,
      nudgeDate: nudgeDate,
    );
  }

  /// The same for borrowing.
  Future<Debt> borrowFrom({
    required String counterparty,
    required double principal,
    String? accountId,
    DateTime? at,
    String? note,
    DateTime? dueDate,
    DateTime? nudgeDate,
    String? ownerName,
  }) async {
    if (ownerName != null && normaliseName(ownerName) == normaliseName(counterparty)) {
      throw ArgumentError('You cannot borrow money from yourself');
    }
    final existing = await openContractFor(counterparty);
    if (existing != null && existing.direction == 'borrowed') {
      await _addTo(existing, principal, accountId: accountId, at: at, note: note);
      return db.getDebt(existing.id);
    }
    return borrow(
      counterparty: counterparty,
      principal: principal,
      accountId: accountId,
      at: at,
      note: note,
      dueDate: dueDate,
      nudgeDate: nudgeDate,
    );
  }

  /// Adds money to an existing contract: the principal grows and a new row
  /// lands on the trail, so the history shows both hand-overs.
  Future<void> _addTo(Debt debt, double amount, {String? accountId, DateTime? at, String? note}) async {
    if (amount <= 0) throw ArgumentError('Amount must be above zero');
    await db.updateDebt(
      debt.id,
      DebtsCompanion(principal: Value(debt.principal + amount)),
    );
    await db.insertTransaction(
      TransactionsCompanion(
        id: Value(const Uuid().v4()),
        kind: Value(debt.direction == 'lent' ? 'lend' : 'borrow'),
        actual: Value(debt.direction == 'lent' ? -amount : amount),
        budgetImpact: const Value(0),
        occurredAt: Value(at ?? DateTime.now()),
        categoryRaw: Value(
          debt.direction == 'lent' ? 'lend ${debt.counterparty}' : 'borrow ${debt.counterparty}',
        ),
        level0: Value(debt.direction == 'lent' ? 'lend' : 'borrow'),
        level1: Value(debt.counterparty.toLowerCase()),
        note: Value(note),
        accountId: Value(accountId),
        linkId: Value(debt.id),
        linkType: const Value('debt'),
      ),
    );
  }

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
