import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/reconcile/networth_logic.dart';
import 'package:expense_tracker/features/reconcile/price_logic.dart';
import 'package:expense_tracker/features/reconcile/reconcile_logic.dart';
import 'package:expense_tracker/features/reconcile/reconcile_repository.dart';

void main() {
  group('reconcile math (pure)', () {
    test('month keys shift across year roll', () {
      expect(monthKey(DateTime(2026, 9, 15)), '2026-09');
      expect(shiftMonthKey('2026-01', -1), '2025-12');
      expect(shiftMonthKey('2026-12', 1), '2027-01');
      final b = monthBounds('2026-09');
      expect(b.start, DateTime(2026, 9, 1));
      expect(b.end.month, 9);
    });

    test('expected / gap / status', () {
      expect(expectedClose(open: 2000, inflows: 500, outflows: 300), 2200);
      expect(reconcileGap(expected: 2200, counted: 2200), 0);
      expect(reconcileGap(expected: 2200, counted: 2100), 100); // short
      expect(reconcileGap(expected: 2200, counted: 2300), -100); // excess
      expect(reconcileStatus(0), 'balanced');
      expect(reconcileStatus(100), 'short');
      expect(reconcileStatus(-100), 'excess');
    });
  });

  group('price memory (pure)', () {
    test('avg/min/max + overpay vs average', () {
      final s = priceStats([450, 500, 550]);
      expect(s.avg, 500);
      expect(s.min, 450);
      expect(s.max, 550);
      expect(s.latest, 550);
      expect(s.count, 3);
      expect(s.overpay, isTrue); // 550 > 500
      expect(priceStats([550, 500, 450]).overpay, isFalse);
      expect(priceStats([450]).overpay, isFalse); // single sighting: no flag
      expect(priceStats([]).count, 0);
    });

    test('only spends become prices', () {
      expect(pricesOf([-450, 2000, -500]), [450, 500]);
    });
  });

  group('net worth (pure)', () {
    test('lent adds, borrowed subtracts', () {
      expect(
        debtNet([
          (direction: 'lent', principal: 5000, paid: 2000),
          (direction: 'borrowed', principal: 10000, paid: 1000),
        ]),
        (3000 - 9000),
      );
    });

    test('timeline rises and falls with the ledger', () {
      final pts = netWorthTimeline(
        openings: 10000,
        moves: [
          (at: DateTime(2026, 7, 5), actual: -2000),
          (at: DateTime(2026, 8, 5), actual: 5000),
        ],
        investCurrent: 20000,
        debtNetValue: 0,
        endKey: '2026-09',
        months: 3,
      );
      expect([for (final p in pts) p.key], ['2026-07', '2026-08', '2026-09']);
      expect(pts[0].value, 10000 - 2000 + 20000); // Jul end
      expect(pts[1].value, 10000 - 2000 + 5000 + 20000); // Aug end
      expect(pts[2].value, pts[1].value); // Sep: no moves
    });
  });

  group('snapshots lifecycle (open → count → report)', () {
    late AppDatabase db;
    late ReconcileRepository recon;
    late String cashId;

    setUp(() async {
      db = AppDatabase.memory();
      recon = ReconcileRepository(db);
      cashId = (await AccountRepository(db).create(name: 'Cash')).id;
    });

    tearDown(() => db.close());

    test('missing shows only after the physical count', () async {
      await recon.setOpen(month: '2026-09', accountId: cashId, value: 2000);
      var r = await recon.report('2026-09');
      expect(r.rows.single.counted, isNull);
      expect(r.countedCount, 0);

      // 300 spent somewhere (ledger read via report, never written here).
      await recon.setClose(month: '2026-09', accountId: cashId, value: 1700);
      r = await recon.report('2026-09');
      final row = r.rows.single;
      expect(row.expected, 2000);
      expect(row.counted, 1700);
      expect(row.gap, 300); // short: 300 left with no entry
      expect(row.status, 'short');
    });

    test('balanced when counted matches expected', () async {
      await recon.setOpen(month: '2026-09', accountId: cashId, value: 2000);
      await recon.setClose(month: '2026-09', accountId: cashId, value: 2000);
      final r = await recon.report('2026-09');
      expect(r.rows.single.status, 'balanced');
      expect(r.totalGap, 0);
    });
  });
}
