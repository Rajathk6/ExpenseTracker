import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/neutral/debt_logic.dart';
import 'package:expense_tracker/features/neutral/debt_repository.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';

void main() {
  group('debt math (pure)', () {
    test('remaining never negative', () {
      expect(remaining(5000, 2000), 3000);
      expect(remaining(5000, 5000), 0);
    });

    test('payoff signs + overpay rejected', () {
      expect(payoffActual(direction: 'lent', amount: 2000, principal: 5000, paid: 0), 2000);
      expect(payoffActual(direction: 'borrowed', amount: 2000, principal: 5000, paid: 0), -2000);
      expect(
        () => payoffActual(direction: 'lent', amount: 4000, principal: 5000, paid: 2000),
        throwsArgumentError,
      );
      expect(() => payoffActual(direction: 'x', amount: 1, principal: 5, paid: 0), throwsArgumentError);
    });

    test('aging + overdue + nudge', () {
      final now = DateTime(2026, 9, 8);
      expect(agingDays(DateTime(2026, 8, 29), now), 10);
      expect(isOverdue(dueDate: DateTime(2026, 9, 1), status: 'open', now: now), isTrue);
      expect(isOverdue(dueDate: DateTime(2026, 9, 20), status: 'open', now: now), isFalse);
      expect(isOverdue(dueDate: DateTime(2026, 9, 1), status: 'settled', now: now), isFalse);
      expect(nudgeDue(nudgeDate: DateTime(2026, 9, 8), status: 'open', now: now), isTrue);
      expect(nudgeDue(nudgeDate: null, status: 'open', now: now), isFalse);
    });
  });

  group('lend lifecycle (May out, June back, net 0, budgets clean)', () {
    late AppDatabase db;
    late DebtRepository debts;
    late TransactionRepository txns;
    late String cashId;

    setUp(() async {
      db = AppDatabase.memory();
      debts = DebtRepository(db);
      txns = TransactionRepository(db);
      cashId = (await AccountRepository(db).create(name: 'Cash')).id;
    });

    tearDown(() => db.close());

    test('full cycle with partials + auto-settle', () async {
      final d0 = await debts.lend(counterparty: 'Ravi', principal: 5000, accountId: cashId, at: DateTime(2026, 5, 10));
      expect(d0.status, 'open');
      expect(d0.paid, 0);

      // May budget untouched by the loan principal.
      final may = await txns.sumsBetween(DateTime(2026, 5, 1), DateTime(2026, 5, 31, 23, 59));
      expect(may.outActual, -5000); // bank truth: money left
      expect(may.outBudget, 0); // planning truth: not an expense

      final d1 = await debts.pay(debtId: d0.id, amount: 2000, accountId: cashId, at: DateTime(2026, 6, 5));
      expect(d1.paid, 2000);
      expect(d1.status, 'open');
      expect(remaining(d1.principal, d1.paid), 3000);

      // June budget untouched by the repayment either.
      final june = await txns.sumsBetween(DateTime(2026, 6, 1), DateTime(2026, 6, 30, 23, 59));
      expect(june.inActual, 2000);
      expect(june.inBudget, 0);

      // Overpay rejected, then exact payoff settles.
      expect(() => debts.pay(debtId: d0.id, amount: 4000, accountId: cashId), throwsArgumentError);
      final d2 = await debts.pay(debtId: d0.id, amount: 3000, accountId: cashId, at: DateTime(2026, 6, 20));
      expect(d2.status, 'settled');
      expect((await debts.open()).map((d) => d.id), isNot(contains(d0.id)));
      expect(() => debts.pay(debtId: d0.id, amount: 1), throwsStateError);

      final trail = await debts.history(d0.id);
      expect(trail.map((t) => t.kind), ['lend', 'settle', 'settle']);
      expect(trail.fold<double>(0, (s, t) => s + t.actual), 0); // net zero
      expect(trail.every((t) => t.budgetImpact == 0), isTrue);
    });

    test('borrow mirrors (in first, out on repay)', () async {
      final d = await debts.borrow(counterparty: 'Bank', principal: 10000, accountId: cashId, at: DateTime(2026, 9, 1));
      final d1 = await debts.pay(debtId: d.id, amount: 10000, accountId: cashId);
      expect(d1.status, 'settled');
      final trail = await debts.history(d.id);
      expect([for (final t in trail) t.actual], [10000, -10000]);
    });

    test('bad inputs rejected', () async {
      expect(() => debts.lend(counterparty: '  ', principal: 100), throwsArgumentError);
      expect(() => debts.lend(counterparty: 'R', principal: 0), throwsArgumentError);
      expect(() => debts.lend(counterparty: 'R', principal: -5), throwsArgumentError);
    });
  });
}
