import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/core/providers.dart';
import 'package:expense_tracker/features/budgets/bucket_math.dart';
import 'package:expense_tracker/features/budgets/simulator.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';

void main() {
  group('simulator (pure)', () {
    test('30/40/30 over three months', () {
      final sim = simulate(bucketPresets['30/40/30']!, [10000, 20000, 30000]);
      expect(sim['Needs']!.perMonth, [3000, 6000, 9000]);
      expect(sim['Needs']!.avg, 6000);
      expect(sim['Wants']!.perMonth, [4000, 8000, 12000]);
      expect(sim['Invest']!.avg, 6000);
    });

    test('empty history averages zero', () {
      final sim = simulate(bucketPresets['50/30/20']!, []);
      expect(sim['Needs']!.perMonth, isEmpty);
      expect(sim['Needs']!.avg, 0);
    });
  });

  group('search (levels + items)', () {
    late AppDatabase db;
    late TransactionRepository txns;

    setUp(() async {
      db = AppDatabase.memory();
      txns = TransactionRepository(db);
      Future<void> add(String cat, double amt, DateTime at) =>
          txns.add(kind: 'out', actual: -amt, budgetImpact: -amt, dateTime: at, categoryRaw: cat);
      await add('food junk gobi-65', 65, DateTime(2026, 9, 1));
      await add('food healthy salad', 120, DateTime(2026, 9, 2));
      await add('rent monthly house', 8000, DateTime(2026, 9, 3));
    });

    tearDown(() => db.close());

    test('level query finds all matching rows', () async {
      final rows = await txns.search('food');
      expect(rows.map((r) => r.categoryRaw), containsAll(['food junk gobi-65', 'food healthy salad']));
      expect(rows, hasLength(2));
    });

    test('item query is case-insensitive', () async {
      expect((await txns.search('GOBI')).map((r) => r.item), ['gobi-65']);
      expect((await txns.search('rent monthly')).map((r) => r.categoryRaw), ['rent monthly house']);
    });

    test('no match and blank return empty', () async {
      expect(await txns.search('zzz-nope'), isEmpty);
      expect(await txns.search('   '), isEmpty);
    });
  });

  group('pastOut provider (oldest first)', () {
    test('three month keys with correct spend', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final txns = TransactionRepository(db);
      Future<void> add(String cat, double amt, DateTime at) =>
          txns.add(kind: 'out', actual: -amt, budgetImpact: -amt, dateTime: at, categoryRaw: cat);
      await add('food x', 100, DateTime(2026, 7, 5));
      await add('food y', 200, DateTime(2026, 8, 5));
      await add('food z', 300, DateTime(2026, 9, 5));
      final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
      addTearDown(container.dispose);
      final rows = await container.read(pastOutProvider('2026-09').future);
      expect([for (final r in rows) r.key], ['2026-07', '2026-08', '2026-09']);
      expect([for (final r in rows) r.out], [100, 200, 300]);
    });
  });
}
