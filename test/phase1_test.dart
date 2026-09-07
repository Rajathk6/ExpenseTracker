import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/budgets/bucket_math.dart';
import 'package:expense_tracker/features/budgets/budget_repository.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late AccountRepository accounts;
  late BudgetRepository budgets;
  late TransactionRepository txns;

  setUp(() {
    db = AppDatabase.memory();
    accounts = AccountRepository(db);
    budgets = BudgetRepository(db);
    txns = TransactionRepository(db);
  });

  tearDown(() => db.close());

  group('bucket math (pure)', () {
    test('30/40/30 preset allocates', () {
      final alloc = allocate(10000, bucketPresets['30/40/30']!);
      expect(alloc, {'Needs': 3000, 'Wants': 4000, 'Invest': 3000});
    });

    test('sum != 100 rejected', () {
      expect(
        validateBuckets(const [Bucket(name: 'A', pct: 50), Bucket(name: 'B', pct: 40)]),
        contains('100%'),
      );
      expect(
        () => allocate(1000, const [Bucket(name: 'A', pct: 50)]),
        throwsArgumentError,
      );
    });

    test('duplicate/empty names rejected', () {
      expect(
        validateBuckets(const [Bucket(name: 'X', pct: 50), Bucket(name: 'x ', pct: 50)]),
        contains('unique'),
      );
      expect(validateBuckets(const []), contains('at least one'));
    });

    test('custom 4-bucket split works', () {
      const b = [
        Bucket(name: 'Rent', pct: 40),
        Bucket(name: 'Food', pct: 25),
        Bucket(name: 'Fun', pct: 15),
        Bucket(name: 'Save', pct: 20),
      ];
      expect(validateBuckets(b), isNull);
      expect(allocate(20000, b)['Food'], 5000);
    });
  });

  group('budgets (persisted)', () {
    test('save + read + allocation', () async {
      await budgets.save(month: '2026-09', total: 10000, buckets: bucketPresets['30/40/30']!);
      final got = await budgets.get('2026-09');
      expect(got?.total, 10000);
      expect(got?.buckets.map((b) => b.name), ['Needs', 'Wants', 'Invest']);
      expect(await budgets.allocation('2026-09'), {'Needs': 3000, 'Wants': 4000, 'Invest': 3000});
    });

    test('bad month and bad ratios rejected, nothing persisted', () async {
      expect(() => budgets.save(month: 'Sept', total: 1, buckets: bucketPresets['50/30/20']!), throwsArgumentError);
      expect(
        () => budgets.save(
          month: '2026-09',
          total: 1,
          buckets: const [Bucket(name: 'A', pct: 10)],
        ),
        throwsArgumentError,
      );
      expect(await budgets.get('2026-09'), isNull);
    });
  });

  group('accounts (sources/dests)', () {
    test('create/list/rename/remove', () async {
      final a = await accounts.create(name: 'Cash Pocket', kind: 'cash', openingBalance: 2000);
      expect(a.openingBalance, 2000);
      await accounts.create(name: 'SBI-1234', kind: 'bank');
      expect((await accounts.list()).map((e) => e.name), ['Cash Pocket', 'SBI-1234']);
      await accounts.rename(a.id, 'Wallet');
      expect((await db.getAccount(a.id)).name, 'Wallet');
      await accounts.remove(a.id);
      expect((await accounts.list()).map((e) => e.name), ['SBI-1234']);
    });

    test('duplicate and blank names rejected', () async {
      await accounts.create(name: 'Cash');
      expect(() => accounts.create(name: 'Cash'), throwsA(isA<StateError>()));
      expect(() => accounts.create(name: '   '), throwsArgumentError);
    });

    test('kind is freeform (custom types allowed)', () async {
      final a = await accounts.create(name: 'Mess Card', kind: 'hostel-mess-card');
      expect(a.kind, 'hostel-mess-card');
    });
  });

  group('transactions (parsed + searchable)', () {
    test('insert auto-parses category levels/item', () async {
      final t = await txns.add(
        kind: 'out',
        actual: -65,
        budgetImpact: -65,
        dateTime: DateTime(2026, 9, 1, 20, 30),
        categoryRaw: 'food junk gobi-65',
      );
      expect(t.level0, 'food');
      expect(t.level1, 'junk');
      expect(t.level2, 'gobi');
      expect(t.item, 'gobi-65');
    });

    test('gobi-65 frequency search within month', () async {
      for (final day in [1, 5, 9]) {
        await txns.add(
          kind: 'out',
          actual: -60,
          budgetImpact: -60,
          dateTime: DateTime(2026, 9, day),
          categoryRaw: 'food junk gobi-65',
        );
      }
      await txns.add(
        kind: 'out',
        actual: -40,
        budgetImpact: -40,
        dateTime: DateTime(2026, 8, 15),
        categoryRaw: 'food junk gobi-65',
      );
      final sept = await txns.forItem('gobi-65', from: DateTime(2026, 9, 1), to: DateTime(2026, 9, 30, 23, 59));
      expect(sept, hasLength(3));
      expect(sept.fold<double>(0, (s, t) => s + t.actual), -180);
      expect(await txns.forItem('gobi-65'), hasLength(4));
      expect(await txns.allItems(), contains('gobi-65'));
    });

    test('any freeform category accepted', () async {
      final t = await txns.add(
        kind: 'out',
        actual: -10,
        budgetImpact: -10,
        dateTime: DateTime(2026, 9, 2),
        categoryRaw: 'weird custom thing xyz-123',
      );
      expect(t.item, 'xyz-123');
    });
  });
}
