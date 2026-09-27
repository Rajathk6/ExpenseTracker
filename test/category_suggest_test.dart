import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:expense_tracker/core/category_suggest.dart';
import 'package:expense_tracker/core/backup/backup_service.dart';
import 'package:expense_tracker/core/backup/codec.dart';
import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/reconcile/month_open_repository.dart';
import 'package:expense_tracker/features/transactions/item_search_screen.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';

void main() {
  Transaction _row(DateTime at, double actual) => Transaction(
        id: '$at$actual',
        kind: 'out',
        actual: actual,
        budgetImpact: actual,
        occurredAt: at,
        categoryRaw: 'food staples maggi',
        createdAt: at,
      );

  group('category suggestions (pure ranking)', () {
    final past = [
      'food junk gobi-65',
      'food chai cutting',
      'food healthy salad-bowl',
      'rent',
      'transport auto cab',
    ];

    test('half an item word returns the full past category', () {
      final out = suggestCategories(past, query: 'gob');
      expect(out.first.value, 'food junk gobi-65');
      expect(out.first.matchedOn, 'item');
      expect(out.first.matchedToken, 'gobi-65');
    });

    test('half a level word returns the full past category', () {
      final out = suggestCategories(past, query: 'junk');
      expect(out.first.value, 'food junk gobi-65');
      expect(out.first.matchedOn, 'level');
      expect(out.first.matchedToken, 'junk');
    });

    test('partial levels bring back the sibling that starts with them', () {
      final out = suggestCategories(past, query: 'food j');
      expect([for (final s in out) s.value], ['food junk gobi-65']);
      // The highlighted span widens to whole words: `food junk`, not `food j`.
      expect(out.first.matchedToken, 'food junk');
      expect(out.first.matchedOn, 'whole');
    });

    test('typing a level plus trailing space keeps extending the list', () {
      final out = suggestCategories(past, query: 'food junk ');
      expect([for (final s in out) s.value], ['food junk gobi-65']);
      expect(out.first.matchedToken, 'food junk');
    });

    test('exact match outranks longer candidates', () {
      final out = suggestCategories(past, query: 'rent');
      expect(out.first.value, 'rent');
      expect(out.first.matchedOn, 'whole');
    });

    test('raw prefix beats item and level hits', () {
      final out = suggestCategories([...past, 'food'], query: 'food');
      expect(out.first.value, 'food');
      expect(out.where((s) => s.value != 'food').length, greaterThan(0));
    });

    test('substring in the middle still matches', () {
      final out = suggestCategories(past, query: 'auto');
      expect(out.single.value, 'transport auto cab');
      expect(out.single.matchedOn, 'level');
    });

    test('no match returns nothing — a new category is always allowed', () {
      expect(suggestCategories(past, query: 'zzzz'), isEmpty);
    });

    test('case-insensitive both ways', () {
      expect(suggestCategories(past, query: 'GOB').first.value, 'food junk gobi-65');
      expect(suggestCategories(['Food Chai Cutting'], query: 'cha').first.value, 'Food Chai Cutting');
    });

    test('empty query browses most-used first', () {
      final out = suggestCategories(
        past,
        uses: {'rent': 1, 'food junk gobi-65': 9, 'food chai cutting': 4},
      );
      expect([for (final s in out) s.value], [
        'food junk gobi-65',
        'food chai cutting',
        'rent',
        'food healthy salad-bowl',
        'transport auto cab',
      ]);
      expect(out.first.uses, 9);
      expect(out.first.matchedOn, 'recent');
      expect(out.first.matchedToken, isNull);
    });

    test('usage breaks ties inside a tier', () {
      final out = suggestCategories(
        ['food tea', 'food coffee', 'food water'],
        query: 'food ',
        uses: {'food tea': 1, 'food coffee': 7, 'food water': 3},
      );
      expect([for (final s in out) s.value], ['food coffee', 'food water', 'food tea']);
    });

    test('duplicates collapse case-insensitively, blanks dropped', () {
      final out = suggestCategories(['Food Chai', 'food chai', '   ', 'food chai'], query: 'cha');
      expect(out.length, 1);
      expect(out.single.value, 'Food Chai');
    });

    test('limit caps the list, no silent padding', () {
      expect(suggestCategories(past, query: 'food', limit: 2).length, 2);
      expect(suggestCategories(past, query: 'food', limit: 0), isEmpty);
    });
  });

  group('category suggestions over a real ledger', () {
    late AppDatabase db;
    late TransactionRepository txns;

    setUp(() {
      db = AppDatabase.memory();
      txns = TransactionRepository(db);
    });

    tearDown(() => db.close());

    Future<void> seed(String category, {int times = 1}) async {
      for (var i = 0; i < times; i++) {
        await txns.add(
          kind: 'out',
          actual: -65,
          budgetImpact: -65,
          dateTime: DateTime(2026, 9, 1 + i),
          categoryRaw: category,
        );
      }
    }

    test('usage counts drive the ranking', () async {
      await seed('food chai cutting', times: 3);
      await seed('food junk gobi-65');
      await seed('rent');
      final uses = await db.categoryUsage();
      expect(uses['food chai cutting'], 3);
      expect(uses['food junk gobi-65'], 1);
      expect(uses['rent'], 1);
    });

    test('half a word off the ledger finds the saved category', () async {
      await seed('food junk gobi-65');
      await seed('transport auto cab');
      final out = suggestCategories(await db.distinctCategories(), query: 'cab', uses: await db.categoryUsage());
      expect(out.single.value, 'transport auto cab');
    });

    test('a category just saved is offered on the very next entry', () async {
      expect(suggestCategories(await db.distinctCategories(), query: 'mag'), isEmpty);
      await seed('food staples maggi');
      expect(
        suggestCategories(await db.distinctCategories(), query: 'mag').first.value,
        'food staples maggi',
      );
    });
  });

  group('item search roll-ups (sum/count per month and per year)', () {
    test('counts and totals per period, plus the average', () async {
      final rows = [
        _row(DateTime(2025, 4, 2), -60),
        _row(DateTime(2025, 4, 20), -70),
        _row(DateTime(2025, 11, 3), -50),
        _row(DateTime(2026, 2, 9), -100),
      ];
      final byMonth = rollUpByPeriod(rows, DateFormat('MMM yyyy'));
      expect(byMonth['Apr 2025']!.times, 2);
      expect(byMonth['Apr 2025']!.total, -130);
      expect(byMonth['Apr 2025']!.average, -65);
      expect(byMonth['Nov 2025']!.times, 1);

      final byYear = rollUpByPeriod(rows, DateFormat('yyyy'));
      expect(byYear['2025']!.times, 3);
      expect(byYear['2025']!.total, -180);
      expect(byYear['2025']!.average, -60);
      expect(byYear['2026']!.total, -100);
    });

    test('no rows rolls up to nothing', () {
      expect(rollUpByPeriod(const <Transaction>[], DateFormat('yyyy')), isEmpty);
    });
  });

  group('backup carries every table (month_open included)', () {
    late AppDatabase db;
    late BackupService backup;

    setUp(() {
      db = AppDatabase.memory();
      backup = BackupService(db);
    });

    tearDown(() => db.close());

    test('export → wipe → import returns the month opener too', () async {
      final accounts = AccountRepository(db);
      final cash = await accounts.create(name: 'Cash');
      await MonthOpenRepository(db).save(month: '2026-09', cashBalance: 2500, budgetOut: 9000);
      await TransactionRepository(db).add(
        kind: 'out',
        actual: -300,
        budgetImpact: -300,
        dateTime: DateTime(2026, 9, 2),
        categoryRaw: 'food chai cutting',
        accountId: cash.id,
      );
      final packed = await encryptBackup(await backup.dumpTables(), 'pw12345');

      await db.delete(db.transactions).go();
      await db.delete(db.monthOpen).go();
      await db.delete(db.accounts).go();
      expect(await db.allMonthOpens(), isEmpty);

      final counts = await backup.restoreTables(await decryptBackup(packed, 'pw12345'));
      expect(counts['month_open'], 1);
      expect(counts['transactions'], 1);
      expect(counts['accounts'], 1);
      expect((await db.getMonthOpen('2026-09'))?.cashBalance, 2500);
      expect((await db.getMonthOpen('2026-09'))?.budgetOut, 9000);
    });

    test('every table in the manifest is dumped', () async {
      final tables = await backup.dumpTables();
      expect([for (final k in backupTables) k], tables.keys.toList());
    });
  });
}
