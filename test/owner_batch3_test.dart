import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/neutral/debt_repository.dart';
import 'package:expense_tracker/features/reconcile/networth_logic.dart';
import 'package:expense_tracker/features/splits/split_logic.dart';
import 'package:expense_tracker/features/splits/split_repository.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';

void main() {
  group('the same person is the same contract (#2)', () {
    late AppDatabase db;
    late DebtRepository debts;

    setUp(() async {
      db = AppDatabase.memory();
      debts = DebtRepository(db);
    });

    tearDown(() => db.close());

    test('lending twice to the same person adds to one card', () async {
      final first = await debts.lendTo(counterparty: 'Karthik', principal: 5000);
      final second = await debts.lendTo(counterparty: 'karthik', principal: 2000);

      expect(second.id, first.id, reason: 'same person, same contract');
      expect(second.principal, 7000);
      final all = await debts.all();
      expect(all.length, 1);
    });

    test('both hand-overs are on the trail', () async {
      final contract = await debts.lendTo(counterparty: 'Karthik', principal: 5000);
      await debts.lendTo(counterparty: ' Karthik ', principal: 2000);
      final trail = await debts.history(contract.id);
      expect(trail.length, 2);
      expect(trail.map((t) => t.actual).toList(), [-5000, -2000]);
    });

    test('borrowing from the same person also folds together', () async {
      await debts.borrowFrom(counterparty: 'Asha', principal: 1000);
      final second = await debts.borrowFrom(counterparty: 'Asha', principal: 500);
      expect(second.principal, 1500);
      expect((await debts.all()).length, 1);
    });

    test('a lent and a borrowed contract with one person stay separate', () async {
      await debts.lendTo(counterparty: 'Ravi', principal: 1000);
      await debts.borrowFrom(counterparty: 'Ravi', principal: 500);
      expect((await debts.all()).length, 2);
    });

    test('names are matched loosely but kept as written', () {
      expect(normaliseName('  Karthik '), 'karthik');
      expect(normaliseName('KARTHIK'), 'karthik');
      expect(normaliseName('Karthik Rao'), 'karthik rao');
      expect(normaliseName('Karthik  Rao'), 'karthik rao');
    });

    test('you cannot lend to yourself', () async {
      expect(
        () => debts.lendTo(counterparty: 'Rajath', principal: 100, ownerName: 'Rajath'),
        throwsArgumentError,
      );
      expect(
        () => debts.borrowFrom(counterparty: 'rajath', principal: 100, ownerName: 'Rajath'),
        throwsArgumentError,
      );
    });
  });

  group('paybacks cannot exceed what is owed (#8)', () {
    late AppDatabase db;
    late DebtRepository debts;
    late SplitRepository splits;

    setUp(() async {
      db = AppDatabase.memory();
      debts = DebtRepository(db);
      splits = SplitRepository(db);
    });

    tearDown(() => db.close());

    test('a debt cannot be over-paid', () async {
      final d = await debts.lend(counterparty: 'Ravi', principal: 1000);
      await debts.pay(debtId: d.id, amount: 600);
      expect(() => debts.pay(debtId: d.id, amount: 600), throwsArgumentError);
    });

    test('a split cannot be over-settled', () async {
      final s = await splits.create(
        title: 'Dinner',
        total: 1000,
        people: 2,
        members: const ['Me', 'Ravi'],
      );
      await splits.settle(splitId: s.id, amount: 400);
      // Only my share minus what came back is outstanding (500 - 400).
      expect(() => splits.settle(splitId: s.id, amount: 200), throwsArgumentError);
    });

    test('a person cannot pay themselves back', () async {
      final s = await splits.create(
        title: 'Dinner',
        total: 1000,
        people: 2,
        members: const ['Me', 'Ravi'],
      );
      expect(() => splits.settle(splitId: s.id, amount: 100, who: 'Me'), throwsArgumentError);
    });

    test('the same name cannot be in a split twice', () {
      expect(validateMembers(const ['Me', 'me']), isNotNull);
      expect(validateMembers(const ['Me', 'Ravi']), isNull);
      expect(validatePayBetween(from: 'Me', to: 'me'), isNotNull);
      expect(validatePayBetween(from: 'Me', to: 'Ravi'), isNull);
    });
  });

  group('accounts hold real money (#4, #6)', () {
    late AppDatabase db;
    late AccountRepository accounts;
    late TransactionRepository txns;

    setUp(() async {
      db = AppDatabase.memory();
      accounts = AccountRepository(db);
      txns = TransactionRepository(db);
    });

    tearDown(() => db.close());

    test('the balance is the opening amount plus everything that moved', () async {
      final cash = await accounts.create(name: 'Cash', kind: 'cash', openingBalance: 1000);
      await txns.add(
        kind: 'out',
        actual: -300,
        budgetImpact: -300,
        dateTime: DateTime(2026, 9, 2),
        categoryRaw: 'food chai cutting',
        accountId: cash.id,
      );
      await txns.add(
        kind: 'in',
        actual: 5000,
        budgetImpact: 5000,
        dateTime: DateTime(2026, 9, 3),
        categoryRaw: 'salary',
        accountId: cash.id,
      );
      final balances = await accounts.balances();
      final one = balances.single;
      expect(one.opening, 1000);
      expect(one.moved, 4700);
      expect(one.balance, 5700);
    });

    test('the opening balance can be corrected', () async {
      final cash = await accounts.create(name: 'Cash', kind: 'cash', openingBalance: 100);
      await accounts.setOpeningBalance(cash.id, 2500);
      final balances = await accounts.balances();
      expect(balances.single.balance, 2500);
    });

    test('a transfer moves money without changing the total', () async {
      final cash = await accounts.create(name: 'Cash', kind: 'cash', openingBalance: 1000);
      final bank = await accounts.create(name: 'Bank', kind: 'bank', openingBalance: 500);
      await txns.transfer(fromId: cash.id, toId: bank.id, amount: 300);
      final balances = await accounts.balances();
      final total = balances.fold<double>(0, (s, b) => s + b.balance);
      expect(total, 1500, reason: 'a transfer is your own money moving');
      expect(balances.firstWhere((b) => b.name == 'Cash').balance, 700);
      expect(balances.firstWhere((b) => b.name == 'Bank').balance, 800);
    });
  });

  group('net worth and the accounts agree (#4)', () {
    late AppDatabase db;
    late AccountRepository accounts;
    late TransactionRepository txns;
    late DebtRepository debts;

    setUp(() async {
      db = AppDatabase.memory();
      accounts = AccountRepository(db);
      txns = TransactionRepository(db);
      debts = DebtRepository(db);
    });

    tearDown(() => db.close());

    test('lending moves the cash out of the account, and the receivable replaces it', () async {
      final cash = await accounts.create(name: 'Cash', kind: 'cash', openingBalance: 10000);
      await debts.lend(counterparty: 'Karthik', principal: 5000, accountId: cash.id);

      // The account really holds 5000 now.
      final balance = (await accounts.balances()).single.balance;
      expect(balance, 5000);

      // And the owner is still whole: 5000 in hand + 5000 owed to them.
      final points = netWorthTimeline(
        moves: [NetMove(DateTime(2026, 9, 5), -5000)],
        obligationsByMonth: const [
          (monthKey: '2026-09', obligations: Obligations(lent: 5000, splitReceivable: 0, borrowed: 0)),
        ],
        investments: 0,
        endMonthKey: '2026-09',
        months: 1,
      );
      expect(points.single.cash, -5000);
      expect(points.single.owedToYou, 5000);
      expect(points.single.net, 0, reason: 'lending is not a loss');
    });
  });
}
