import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/budgets/bucket_math.dart';
import 'package:expense_tracker/features/budgets/budget_repository.dart';
import 'package:expense_tracker/features/budgets/budget_status.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/instruments/instruments_screen.dart';
import 'package:expense_tracker/features/groups/group_repository.dart';
import 'package:expense_tracker/features/shared/shared_logic.dart';
import 'package:expense_tracker/features/splits/split_logic.dart';
import 'package:expense_tracker/features/neutral/debt_repository.dart';
import 'package:expense_tracker/features/reconcile/month_start_service.dart';
import 'package:expense_tracker/features/transactions/recurring_service.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';

void main() {
  group('month start actually applies (#1, #6)', () {
    late AppDatabase db;
    late Account cash;

    setUp(() async {
      db = AppDatabase.memory();
      cash = await AccountRepository(db).create(name: 'Cash', kind: 'cash');
    });

    tearDown(() => db.close());

    test('budget total is split across the carried-forward buckets', () async {
      await BudgetRepository(db).save(
        month: '2026-08',
        total: 10000,
        buckets: const [Bucket(name: 'need', pct: 50), Bucket(name: 'want', pct: 30), Bucket(name: 'invest', pct: 20)],
      );
      final result = await MonthStartService(db).apply(month: '2026-09', budgetOut: 60000);

      expect(result.budgetWritten, true);
      final budget = await BudgetRepository(db).get('2026-09');
      expect(budget!.total, 60000);
      final allocation = await BudgetRepository(db).allocation('2026-09');
      expect(allocation['need'], 30000);
      expect(allocation['want'], 18000);
      expect(allocation['invest'], 12000);
      // The earlier month is untouched by the new one.
      expect((await BudgetRepository(db).get('2026-08'))!.total, 10000);
      expect(result.summary, contains('need/want/invest'));
    });

    test('no buckets anywhere yet → a sane 50/30/20 default, not a crash', () async {
      final result = await MonthStartService(db).apply(month: '2026-09', budgetOut: 1000);
      expect(result.budgetWritten, true);
      expect((await BudgetRepository(db).allocation('2026-09'))['invest'], 200);
    });

    test('opening balances become snapshots reconcile can read', () async {
      await AccountRepository(db).create(name: 'SBI', kind: 'bank');
      final result = await MonthStartService(db).apply(month: '2026-09', cashBalance: 2500, bankBalance: 40000);
      expect(result.snapshotsWritten, 2);
      final snapshots = await db.snapshotsForMonth('2026-09');
      expect(snapshots.length, 2);
      final cashRow = snapshots.firstWhere((s) => s.accountId == cash.id);
      expect(cashRow.openBalance, 2500);
    });

    test('a repeating salary is stored as a rule, not as phantom entries', () async {
      final result = await MonthStartService(db).apply(
        month: '2026-09',
        salaryAmount: 60000,
        salaryMonths: 4,
      );
      expect(result.recurringRulesCreated, 1);
      expect(await db.allRecurring(), hasLength(1));
      expect(await db.allTransactions(), isEmpty);
    });

    test('blank form reports that it did nothing instead of pretending', () async {
      final result = await MonthStartService(db).apply(month: '2026-09');
      expect(result.budgetWritten, false);
      expect(result.summary, contains('Nothing to apply'));
    });
  });

  group('repeating entries fill months forward (#4)', () {
    late AppDatabase db;
    late RecurringService service;

    setUp(() async {
      db = AppDatabase.memory();
      service = RecurringService(db);
      await AccountRepository(db).create(name: 'Cash', kind: 'cash');
    });

    tearDown(() => db.close());

    Future<RecurringRule> rule({int months = 4, String start = '2026-07'}) async {
      await db.upsertRecurringRule(
        RecurringRulesCompanion(
          id: const Value('salary-1'),
          kind: const Value('in'),
          amount: const Value(60000),
          categoryRaw: const Value('salary'),
          dayOfMonth: const Value(1),
          months: Value(months),
          startMonth: Value(start),
        ),
      );
      return (await db.allRecurringRules()).single;
    }

    test('a 4-month salary produces four real entries and stops', () async {
      final r = await rule(months: 4, start: '2026-09');
      // "Now" is 2026-09 in the app's world, so months after it are not backfilled.
      final written = await service.applyAll(r, nowMonth: '2026-09');
      expect(written, 1, reason: 'only September has happened at that point');
      final rows = await db.allTransactions();
      expect(rows.single.actual, 60000);
      expect(rows.single.categoryRaw, 'salary');
      // Re-running never double-fills the same month.
      expect(await service.applyAll(r, nowMonth: '2026-09'), 0);
      // And a month that has now arrived can be filled on the next pass.
      expect(await service.applyAll(r, nowMonth: '2026-10'), 1);
      expect(await db.allTransactions(), hasLength(2));
    });

    test('pending months never include one that has not happened', () {
      final r = RecurringRule(
        id: 'x',
        kind: 'in',
        amount: 1,
        categoryRaw: 'salary',
        bucket: null,
        accountId: null,
        dayOfMonth: 1,
        months: 4,
        startMonth: '2026-09',
        lastAppliedMonth: null,
        note: null,
        createdAt: DateTime(2026, 9, 1),
      );
      final pending = service.pending(r, nowMonth: '2026-10');
      expect([for (final p in pending) p.monthKey], ['2026-09', '2026-10']);
    });
  });

  group('absorb neutral rows into a month (#10)', () {
    late AppDatabase db;
    late TransactionRepository txns;

    setUp(() async {
      db = AppDatabase.memory();
      txns = TransactionRepository(db);
    });

    tearDown(() => db.close());

    test('a lend is invisible until absorbed, then it counts as real spend', () async {
      final account = (await AccountRepository(db).create(name: 'Cash', kind: 'cash')).id;
      final debt = await DebtRepository(db).lend(
        counterparty: 'Ravi',
        principal: 5000,
        accountId: account,
        at: DateTime(2026, 9, 5),
      );
      final start = DateTime(2026, 9);
      final end = DateTime(2026, 9, 30, 23, 59);

      var sums = await txns.sumsBetween(start, end, excludeNeutral: true);
      expect(sums.outBudget, 0, reason: 'held out of the month by default');

      final row = (await db.debtHistory(debt.id)).first;
      await txns.setAbsorbed(id: row.id, absorbed: true);
      sums = await txns.sumsBetween(start, end, excludeNeutral: true);
      expect(sums.outBudget, -5000, reason: 'absorbed = treated as a real spend');
      expect(sums.outActual, -5000);

      // …and it can be taken back out again.
      await txns.setAbsorbed(id: row.id, absorbed: false);
      sums = await txns.sumsBetween(start, end, excludeNeutral: true);
      expect(sums.outBudget, 0);
    });

    test('only neutral rows can be absorbed', () async {
      final row = await txns.add(
        kind: 'out',
        actual: -450,
        budgetImpact: -450,
        dateTime: DateTime(2026, 9, 2),
        categoryRaw: 'food chai cutting',
      );
      expect(() => txns.setAbsorbed(id: row.id, absorbed: true), throwsStateError);
    });

    test('absorbing borrowed money counts it as income for the month', () async {
      final account = (await AccountRepository(db).create(name: 'Cash', kind: 'cash')).id;
      final debt = await DebtRepository(db).borrow(
        counterparty: 'Asha',
        principal: 2000,
        accountId: account,
        at: DateTime(2026, 9, 6),
      );
      final row = (await db.debtHistory(debt.id)).first;
      final start = DateTime(2026, 9);
      final end = DateTime(2026, 9, 30, 23, 59);
      expect((await txns.sumsBetween(start, end, excludeNeutral: true)).inBudget, 0);

      await txns.setAbsorbed(id: row.id, absorbed: true);
      final sums = await txns.sumsBetween(start, end, excludeNeutral: true);
      expect(sums.inBudget, 2000, reason: 'borrowed money is income of that month once absorbed');
    });
  });

  group('budget status reads income as the yardstick (#7)', () {
    const buckets = [Bucket(name: 'need', pct: 50), Bucket(name: 'want', pct: 30), Bucket(name: 'invest', pct: 20)];

    BudgetStatusReport report({required double income, required double spent, Map<String, double> byBucket = const {}}) =>
        buildBudgetStatus(
          income: income,
          budgetTotal: 60000,
          spent: spent,
          sourceMonth: '2026-09',
          buckets: buckets,
          bucketSpend: byBucket,
        );

    test('healthy when spend is well under the plan', () {
      final r = report(income: 60000, spent: 10000);
      expect(r.level, BudgetLevel.healthy);
      expect(r.left, 50000);
      expect(r.alerts, isEmpty);
    });

    test('low at 75% and over at 100%', () {
      expect(report(income: 60000, spent: 47000).level, BudgetLevel.low);
      expect(report(income: 60000, spent: 60000).level, BudgetLevel.over);
    });

    test('spending with no income recorded is called out, not silently 100%', () {
      final r = report(income: 0, spent: 5000);
      expect(r.alerts.first, contains('nothing recorded as income'));
    });

    test('spending above income is called out', () {
      final r = report(income: 30000, spent: 45000);
      expect(r.alerts.any((l) => l.contains('above this month')), true);
    });

    test('a bucket at its limit warns, and an unbudgeted spend is visible', () {
      final r = report(
        income: 60000,
        spent: 31000,
        byBucket: {'need': 30000, 'fun money': 1000},
      );
      final need = r.buckets.firstWhere((b) => b.name == 'need');
      expect(need.level, BudgetLevel.over);
      final unplanned = r.buckets.firstWhere((b) => b.name == 'fun money');
      expect(unplanned.level, BudgetLevel.unfunded);
      expect(r.alerts.any((l) => l.contains('no budget set')), true);
    });

    test('the planned split comes from the bucket percentages', () {
      final r = report(income: 60000, spent: 0);
      final need = r.buckets.firstWhere((b) => b.name == 'need');
      expect(need.planned, 30000);
    });
  });

  group('scoped search (#4)', () {
    late AppDatabase db;
    late TransactionRepository txns;

    setUp(() async {
      db = AppDatabase.memory();
      txns = TransactionRepository(db);
    });

    tearDown(() => db.close());

    Future<void> seed(DateTime at, String category) => txns.add(
          kind: 'out',
          actual: -100,
          budgetImpact: -100,
          dateTime: at,
          categoryRaw: category,
        );

    test('no query + a window lists that window', () async {
      await seed(DateTime(2026, 8, 4), 'food chai cutting');
      await seed(DateTime(2026, 9, 4), 'food junk gobi-65');
      final rows = await txns.within(from: DateTime(2026, 9), to: DateTime(2026, 9, 30, 23, 59));
      expect([for (final r in rows) r.categoryRaw], ['food junk gobi-65']);
    });

    test('a query inside a window only returns that window', () async {
      await seed(DateTime(2026, 8, 4), 'food chai cutting');
      await seed(DateTime(2026, 9, 4), 'food junk gobi-65');
      final rows = await txns.searchIn('food', from: DateTime(2026, 8), to: DateTime(2026, 8, 31, 23, 59));
      expect([for (final r in rows) r.categoryRaw], ['food chai cutting']);
    });

    test('all time still finds everything', () async {
      await seed(DateTime(2026, 8, 4), 'food chai cutting');
      await seed(DateTime(2026, 9, 4), 'food junk gobi-65');
      expect(await txns.search('food'), hasLength(2));
      expect(await txns.within(), isEmpty, reason: 'no window and no query = nothing to show');
    });
  });

  group('groups: code, balances, settle-up (#9)', () {
    late AppDatabase db;
    late GroupRepository groups;

    setUp(() {
      db = AppDatabase.memory();
      groups = GroupRepository(db);
    });

    tearDown(() => db.close());

    test('a group needs a name and at least one person', () async {
      expect(() => groups.create(name: '  ', monthKey: '2026-09', people: const ['Me']), throwsArgumentError);
      expect(() => groups.create(name: 'Flat', monthKey: '2026-09', people: const []), throwsArgumentError);
      expect(
        () => groups.create(name: 'Flat', monthKey: '2026-09', people: const ['Me', 'me']),
        throwsArgumentError,
      );
    });

    test('the code identifies the group and refuses a duplicate', () async {
      final g = await groups.create(name: 'Flat', monthKey: '2026-09', people: const ['Me', 'Ravi']);
      expect(g.code, startsWith('ET-'));
      expect(await groups.byCode(g.code), isNotNull);
      expect(
        () => groups.create(name: 'Other', monthKey: '2026-09', people: const ['Me'], code: g.code),
        throwsArgumentError,
      );
    });

    test('joining with the code adds people to the same group', () async {
      final g = await groups.create(name: 'Flat', monthKey: '2026-09', people: const ['Me', 'Ravi']);
      await groups.join(code: g.code, people: const ['Asha', 'ravi']);
      final people = [for (final m in await groups.people(g.id)) m.name];
      expect(people, ['Me', 'Ravi', 'Asha'], reason: 'a name is never added twice');
    });

    test('balances: even split, payer credited, settle-up in whole rupees', () async {
      final g = await groups.create(name: 'Trip', monthKey: '2026-09', people: const ['Me', 'Ravi', 'Asha']);
      await groups.addExpense(groupId: g.id, title: 'Hotel', amount: 900, paidBy: 'Ravi');
      var b = await groups.balances(g.id);
      expect(b.totalSpent, 900);
      final ravi = b.balances.firstWhere((x) => x.name == 'Ravi');
      final me = b.balances.firstWhere((x) => x.name == 'Me');
      expect(ravi.net, 600);
      expect(me.net, -300);
      expect(b.settleUp.map((m) => (m.from, m.to)).toList(), [
        ('Me', 'Ravi'),
        ('Asha', 'Ravi'),
      ]);

      await groups.addPayment(groupId: g.id, paidBy: 'Me', paidTo: 'Ravi', amount: 300);
      b = await groups.balances(g.id);
      expect(b.balances.firstWhere((x) => x.name == 'Me').net, 0);
      expect(b.balances.fold<double>(0, (s, x) => s + x.net), closeTo(0, 0.01));
    });

    test('an expense with no payer is split evenly', () async {
      final g = await groups.create(name: 'Dinner', monthKey: '2026-09', people: const ['Me', 'Ravi']);
      await groups.addExpense(groupId: g.id, title: 'Pizza', amount: 1000);
      final b = await groups.balances(g.id);
      for (final x in b.balances) {
        expect(x.net, closeTo(0, 0.01));
      }
    });

    test('a payment between non-members is rejected', () async {
      final g = await groups.create(name: 'Trip', monthKey: '2026-09', people: const ['Me', 'Ravi']);
      expect(
        () => groups.addPayment(groupId: g.id, paidBy: 'Me', paidTo: 'Stranger', amount: 100),
        throwsArgumentError,
      );
    });

    test('export/import round-trips a group without duplicating rows', () async {
      final g = await groups.create(name: 'Flat', monthKey: '2026-09', people: const ['Me', 'Ravi']);
      await groups.addExpense(groupId: g.id, title: 'Groceries', amount: 1500, paidBy: 'Me');
      await groups.addPayment(groupId: g.id, paidBy: 'Ravi', paidTo: 'Me', amount: 500);
      final payload = await groups.encodeGroup(g.id);

      // A second device: fresh database, same export.
      final other = AppDatabase.memory();
      final groups2 = GroupRepository(other);
      final joined = await groups2.decodeGroup(payload);
      expect(joined!.id, g.id);
      expect((await groups2.people(g.id)).length, 2);
      expect((await groups2.expenses(g.id)).length, 1);
      expect((await groups2.payments(g.id)).length, 1);
      // Importing twice must not double anything.
      await groups2.decodeGroup(payload);
      expect((await groups2.expenses(g.id)).length, 1);
      expect((await groups2.payments(g.id)).length, 1);
      await other.close();
    });
  });

  group('shared-screen totals (#11)', () {
    test('lent and borrowed totals only count what is still open', () {
      final debts = [
        Debt(
          id: '1',
          counterparty: 'Ravi',
          direction: 'lent',
          principal: 1000,
          paid: 400,
          note: null,
          dueDate: null,
          nudgeDate: null,
          status: 'open',
          createdAt: DateTime(2026, 9, 1),
        ),
        Debt(
          id: '2',
          counterparty: 'Asha',
          direction: 'lent',
          principal: 500,
          paid: 500,
          note: null,
          dueDate: null,
          nudgeDate: null,
          status: 'settled',
          createdAt: DateTime(2026, 8, 1),
        ),
      ];
      expect(sharedDebtTotals(debts), 600);
    });

    test('split outstanding excludes my own share', () {
      final split = Split(
        id: '1',
        title: 'Dinner',
        totalPaid: 1000,
        myShare: 100,
        received: 300,
        absorbed: 0,
        membersJson: '["Me","Ravi"]',
        code: 'SP-ABCD',
        note: null,
        status: 'open',
        createdAt: DateTime(2026, 9, 1),
      );
      expect(splitOutstandingTotal([split]), 600);
    });
  });

  group('split share is derived from the headcount (#13)', () {
    test('my share is total / people, never typed', () {
      expect(myShareFor(total: 1000, people: 10), 100);
      expect(myShareFor(total: 999, people: 3), 333);
    });

    test('members must be named and unique', () {
      expect(validateMembers(const []), isNotNull);
      expect(validateMembers(const ['  ']), isNotNull);
      expect(validateMembers(const ['Me', 'me']), isNotNull);
      expect(validateMembers(const ['Me', 'Ravi']), isNull);
    });

    test('codes avoid characters people mishear', () {
      expect(newCode('SP', (max) => 0), 'SP-AAAA');
      expect(newCode('ET', (max) => max - 1), matches(RegExp(r'^ET-[A-Z2-9]{4}$')));
    });
  });

  group('instrument sections (#15)', () {
    test('kinds get a readable label, a colour and an icon', () {
      expect(kindLabel('fd'), 'FD');
      expect(kindLabel('credit card'), 'Credit Card');
      expect(kindLabel('stock'), 'Stock');
      expect(kindLabel('gold'), 'Gold');
      // Never the same colour twice for different kinds.
      final colours = {for (final k in ['stock', 'mutual', 'fd', 'loan', 'card', 'paper', 'plan']) kindAccent(k)};
      expect(colours.length, 7);
      expect(kindIcon('fd'), isNot(Icons.category_outlined));
      expect(kindIcon('unknown thing'), Icons.category_outlined);
    });
  });
}
