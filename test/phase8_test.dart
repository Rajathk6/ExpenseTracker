import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/core/months.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/reports/reports_logic.dart';
import 'package:expense_tracker/features/reports/reports_repository.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';

void main() {
  group('months core helper', () {
    test('keys shift across year roll', () {
      expect(monthKey(DateTime(2026, 9, 15)), '2026-09');
      expect(shiftMonthKey('2026-01', -1), '2025-12');
      expect(shiftMonthKey('2026-12', 1), '2027-01');
    });
  });

  group('reports math (pure)', () {
    test('sums fold blanks into other, ignores inflows', () {
      final sums = sumsByTag([
        (tag: 'food', out: 400),
        (tag: null, out: 100),
        (tag: '  ', out: 50),
        (tag: 'food', out: 100),
        (tag: 'travel', out: 0),
      ]);
      expect(sums, {'food': 500, 'other': 150});
    });

    test('top slices sort desc and bucket the tail', () {
      expect(topSlices({}, 8), isEmpty);
      expect(
        topSlices({'a': 300, 'b': 200, 'c': 100}, 2),
        [(label: 'a', out: 300), (label: 'b', out: 200), (label: 'other', out: 100)],
      );
      expect(pickTop({'a': 300, 'b': 900}), 'b');
      expect(pickTop({}), isNull);
    });

    test('cash kinds split from digital', () {
      final s = splitCashDigital([
        (kind: 'cash', out: 300),
        (kind: 'Cash Wallet', out: 100),
        (kind: 'upi', out: 700),
        (kind: 'digital', out: 0),
      ]);
      expect(s.cash, 400);
      expect(s.digital, 700);
    });
  });

  group('dashboard assembly (no new tables)', () {
    late AppDatabase db;
    late ReportsRepository reports;
    late TransactionRepository txns;
    late String cashId;
    late String bankId;

    setUp(() async {
      db = AppDatabase.memory();
      reports = ReportsRepository(db);
      txns = TransactionRepository(db);
      cashId = (await AccountRepository(db).create(name: 'Cash', kind: 'cash')).id;
      bankId = (await AccountRepository(db).create(name: 'SBI', kind: 'bank')).id;
    });

    tearDown(() => db.close());

    Future<void> seed() async {
      await txns.add(kind: 'out', actual: -400, budgetImpact: -400, dateTime: DateTime(2026, 9, 3), categoryRaw: 'food lunch meals', accountId: cashId);
      await txns.add(kind: 'out', actual: -700, budgetImpact: -700, dateTime: DateTime(2026, 9, 10), categoryRaw: 'travel metro pass', accountId: bankId);
      await txns.add(kind: 'out', actual: -1000, budgetImpact: 0, dateTime: DateTime(2026, 9, 12), categoryRaw: 'transfer atm', accountId: bankId);
    }

    test('categories + cash/digital use budget truth (transfers excluded)', () async {
      await seed();
      final d = await reports.dashboard('2026-09');
      expect(d.outBudget, 1100); // the 1000 transfer never counts
      expect(d.cashOut, 400);
      expect(d.digitalOut, 700);
      final labels = [for (final s in d.categories) s.label];
      expect(labels, contains('food'));
      expect(labels, contains('travel'));
      expect(d.monthTxns, hasLength(3)); // drill still sees every row
      expect(d.trend.last.key, '2026-09');
      expect(d.trend.last.outBudget, 1100);
    });

    test('wrapped picks tops across the year', () async {
      await seed();
      final w = await reports.wrapped(2026);
      expect(w.outBudget, 1100);
      expect(w.topCategory, 'travel');
      expect(w.biggestMonth, '2026-09');
      expect(w.txnCount, 3);
    });
  });
}
