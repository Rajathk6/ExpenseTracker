import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/auth/pin_service.dart';
import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/budgets/bucket_math.dart';
import 'package:expense_tracker/features/budgets/budget_repository.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/neutral/debt_repository.dart';
import 'package:expense_tracker/features/reconcile/month_open_repository.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';

void main() {
  group('edit + delete entries', () {
    late AppDatabase db;
    late TransactionRepository txns;

    setUp(() {
      db = AppDatabase.memory();
      txns = TransactionRepository(db);
    });

    tearDown(() => db.close());

    test('full edit re-parses category + bucket', () async {
      final t = await txns.add(
        kind: 'out',
        actual: -65,
        budgetImpact: -65,
        dateTime: DateTime(2026, 9, 1),
        categoryRaw: 'food junk gobi-65',
        bucket: 'want',
      );
      final u = await txns.update(
        id: t.id,
        kind: 'out',
        actual: -120,
        budgetImpact: -120,
        dateTime: DateTime(2026, 9, 2),
        categoryRaw: 'food healthy salad-bowl',
        bucket: 'need',
        note: 'lunch',
      );
      expect(u.actual, -120);
      expect(u.item, 'salad-bowl');
      expect(u.level1, 'healthy');
      expect(u.bucket, 'need');
      expect(u.note, 'lunch');
    });

    test('linked rows refuse edit/delete', () async {
      final cash = await AccountRepository(db).create(name: 'Cash');
      final debts = DebtRepository(db);
      final d = await debts.lend(counterparty: 'Ravi', principal: 1000, accountId: cash.id);
      final trail = await debts.history(d.id);
      expect(
        () => txns.update(
          id: trail.first.id,
          kind: 'out',
          actual: -1,
          budgetImpact: 0,
          dateTime: DateTime(2026, 9, 1),
          categoryRaw: 'hack attempt',
        ),
        throwsStateError,
      );
      expect(() => txns.remove(trail.first.id), throwsStateError);
    });

    test('delete removes unlinked rows', () async {
      final t = await txns.add(
        kind: 'out',
        actual: -10,
        budgetImpact: -10,
        dateTime: DateTime(2026, 9, 1),
        categoryRaw: 'oops typo',
      );
      await txns.remove(t.id);
      expect(await txns.search('oops'), isEmpty);
    });
  });

  group('neutral exclusion on the front sheet', () {
    late AppDatabase db;
    late TransactionRepository txns;

    setUp(() async {
      db = AppDatabase.memory();
      txns = TransactionRepository(db);
      final cash = (await AccountRepository(db).create(name: 'Cash')).id;
      final debts = DebtRepository(db);
      await txns.add(kind: 'out', actual: -500, budgetImpact: -500, dateTime: DateTime(2026, 9, 2), categoryRaw: 'food lunch');
      await debts.lend(counterparty: 'Ravi', principal: 5000, accountId: cash, at: DateTime(2026, 9, 3));
      await debts.borrow(counterparty: 'Bank', principal: 2000, accountId: cash, at: DateTime(2026, 9, 4));
    });

    tearDown(() => db.close());

    test('default sums include everything; excluded sums hide neutral', () async {
      final all = await txns.sumsBetween(DateTime(2026, 9, 1), DateTime(2026, 9, 30, 23, 59));
      expect(all.outActual, -5500);
      expect(all.inActual, 2000);
      final clean = await txns.sumsBetween(DateTime(2026, 9, 1), DateTime(2026, 9, 30, 23, 59), excludeNeutral: true);
      expect(clean.outActual, -500);
      expect(clean.inActual, 0);
      expect(clean.outBudget, -500);
    });

    test('isNeutral flags lend/borrow/debt-settle only', () async {
      final rows = await txns.search('');
      expect(rows, isEmpty); // blank query → empty by design
      final all = await db.transactionsBetween(DateTime(2026, 9, 1), DateTime(2026, 9, 30, 23, 59));
      final neutral = all.where(TransactionRepository.isNeutral).toList();
      expect(neutral.map((t) => t.kind), containsAll(['lend', 'borrow']));
      expect(all.where((t) => !TransactionRepository.isNeutral(t)), hasLength(1));
    });
  });

  group('bucket spend + carry-forward', () {
    late AppDatabase db;
    late TransactionRepository txns;
    late BudgetRepository budgets;

    setUp(() async {
      db = AppDatabase.memory();
      txns = TransactionRepository(db);
      budgets = BudgetRepository(db);
    });

    tearDown(() => db.close());

    test('spend groups by bucket label', () async {
      Future<void> add(String cat, String? bucket, double amt) => txns.add(
            kind: 'out',
            actual: -amt,
            budgetImpact: -amt,
            dateTime: DateTime(2026, 9, 5),
            categoryRaw: cat,
            bucket: bucket,
          );
      await add('food lunch', 'need', 200);
      await add('movie night', 'want', 300);
      await add('random thing', null, 50);
      final m = await txns.bucketSpend(DateTime(2026, 9, 1), DateTime(2026, 9, 30, 23, 59));
      expect(m['need'], -200);
      expect(m['want'], -300);
      expect(m[''], -50);
    });

    test('budget carries forward until changed', () async {
      const buckets = [Bucket(name: 'need', pct: 60), Bucket(name: 'want', pct: 40)];
      await budgets.save(month: '2026-07', total: 10000, buckets: buckets);
      final sept = await budgets.getEffective('2026-09');
      expect(sept?.sourceMonth, '2026-07');
      expect(sept?.total, 10000);
      // Saving explicitly for September pins it there.
      await budgets.save(month: '2026-09', total: 12000, buckets: buckets);
      final pinned = await budgets.getEffective('2026-09');
      expect(pinned?.sourceMonth, '2026-09');
      expect(pinned?.total, 12000);
      // Earlier months are unaffected by later saves.
      expect((await budgets.getEffective('2026-08'))?.sourceMonth, '2026-07');
      expect(await budgets.getEffective('2026-01'), isNull);
    });
  });

  group('month opener', () {
    test('all-optional save + read + overwrite', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final repo = MonthOpenRepository(db);
      expect(await repo.get('2026-09'), isNull);
      await repo.save(month: '2026-09', budgetOut: 20000, cashBalance: 3500);
      final m = await repo.get('2026-09');
      expect(m?.budgetOut, 20000);
      expect(m?.cashBalance, 3500);
      expect(m?.bankBalance, isNull);
      await repo.save(month: '2026-09', bankBalance: 80000);
      expect((await repo.get('2026-09'))?.bankBalance, 80000);
      expect(() => repo.save(month: 'nope'), throwsArgumentError);
    });
  });

  group('forgot-PIN recovery', () {
    late AppDatabase db;
    late PinService pin;

    setUp(() {
      db = AppDatabase.memory();
      pin = PinService(db);
    });

    tearDown(() => db.close());

    test('question round-trip + reset, wrong answer fails shut', () async {
      expect(await pin.hasRecovery, isFalse);
      expect(await pin.verifyRecoveryAnswer('x'), isFalse);
      await pin.setPin('123456');
      await pin.setRecovery(question: 'First school?', answer: '  Maple High ');
      expect(await pin.hasRecovery, isTrue);
      expect(await pin.recoveryQuestion, 'First school?');
      expect(await pin.verifyRecoveryAnswer('maple high'), isTrue);
      expect(await pin.verifyRecoveryAnswer('other'), isFalse);
      await expectLater(
        pin.resetPinWithAnswer(answer: 'wrong', newPin: '654321'),
        throwsStateError,
      );
      await pin.resetPinWithAnswer(answer: 'MAPLE HIGH', newPin: '654321');
      expect(await pin.verify('654321'), 'real');
      expect(() => pin.setRecovery(question: '  ', answer: 'x'), throwsArgumentError);
    });
  });
}
