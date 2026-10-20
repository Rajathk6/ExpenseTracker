import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/reconcile/networth_logic.dart';
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

  group('net worth (pure) — what you hold minus what you owe', () {
    test('a lend is neither a loss nor a gain: the cash left, the receivable stayed', () {
      final pts = netWorthTimeline(
        moves: const [],
        obligationsByMonth: const [
          (monthKey: '2026-09', obligations: Obligations(lent: 5000, splitReceivable: 0, borrowed: 0)),
        ],
        investments: 0,
        endMonthKey: '2026-09',
        months: 1,
      );
      final p = pts.single;
      expect(p.cash, 0);
      expect(p.owedToYou, 5000);
      expect(p.liabilities, 0);
      expect(p.net, 5000, reason: 'the money is still mine — it is just in the other pocket');
    });

    test('borrowed money is a liability, not wealth', () {
      final pts = netWorthTimeline(
        moves: [NetMove(DateTime(2026, 9, 1), 10000)],
        obligationsByMonth: const [
          (monthKey: '2026-09', obligations: Obligations(lent: 0, splitReceivable: 0, borrowed: 10000)),
        ],
        investments: 0,
        endMonthKey: '2026-09',
        months: 1,
      );
      final p = pts.single;
      expect(p.cash, 10000);
      expect(p.liabilities, 10000);
      expect(p.net, 0, reason: 'borrowed cash is not mine');
    });

    test('a split receivable counts; my own share does not', () {
      final pts = netWorthTimeline(
        moves: const [],
        obligationsByMonth: const [
          (monthKey: '2026-09', obligations: Obligations(lent: 0, splitReceivable: 900, borrowed: 0)),
        ],
        investments: 0,
        endMonthKey: '2026-09',
        months: 1,
      );
      expect(pts.single.net, 900);
    });

    test('the timeline walks month by month and picks up each snapshot in force', () {
      final pts = netWorthTimeline(
        moves: [
          NetMove(DateTime(2026, 7, 5), -2000),
          NetMove(DateTime(2026, 8, 5), 5000),
        ],
        obligationsByMonth: const [
          (monthKey: '2026-08', obligations: Obligations(lent: 0, splitReceivable: 0, borrowed: 1000)),
          (monthKey: '2026-09', obligations: Obligations(lent: 0, splitReceivable: 0, borrowed: 0)),
        ],
        investments: 20000,
        endMonthKey: '2026-09',
        months: 3,
      );
      expect([for (final p in pts) p.monthKey], ['2026-07', '2026-08', '2026-09']);
      expect(pts[0].cash, -2000);
      expect(pts[0].net, -2000 + 20000);
      expect(pts[1].cash, 3000);
      expect(pts[1].net, 3000 + 20000 - 1000, reason: 'August still had the borrowing');
      expect(pts[2].net, 3000 + 20000, reason: 'September it was repaid');
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
