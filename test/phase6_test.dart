import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/instruments/instrument_logic.dart';
import 'package:expense_tracker/features/instruments/instrument_repository.dart';

void main() {
  group('instrument math (pure)', () {
    test('P/L% = (cur-inv)/inv*100, 0 when invested=0', () {
      expect(instrumentPnlPct(invested: 10000, current: 11500), closeTo(15, 0.001));
      expect(instrumentPnlPct(invested: 10000, current: 9000), closeTo(-10, 0.001));
      expect(instrumentPnlPct(invested: 0, current: 5000), 0);
      expect(pnl(invested: 10000, current: 11500), 1500);
    });

    test('simple interest + maturity', () {
      expect(simpleInterest(principal: 10000, annualRatePct: 7, years: 1), closeTo(700, 0.001));
      expect(maturitySimple(principal: 10000, annualRatePct: 7, years: 2), closeTo(11400, 0.001));
      expect(simpleInterest(principal: 0, annualRatePct: 7, years: 1), 0);
    });

    test('compound maturity yearly', () {
      expect(
        maturityCompound(principal: 10000, annualRatePct: 10, years: 2),
        closeTo(12100, 0.01),
      );
    });

    test('validation rejects empty name + negatives', () {
      expect(validateInstrument(name: '  ', invested: 100, current: 100), contains('empty'));
      expect(validateInstrument(name: 'X', invested: -1, current: 0), contains('negative'));
      expect(validateInstrument(name: 'X', invested: 0, current: -5), contains('negative'));
      expect(validateInstrument(name: 'RELIANCE', invested: 10000, current: 11500), isNull);
    });

    test('portfolio totals sum + blended pct', () {
      final t = portfolioTotals([
        (invested: 10000, current: 11500),
        (invested: 5000, current: 4500),
      ]);
      expect(t.invested, 15000);
      expect(t.current, 16000);
      expect(t.pnl, 1000);
      expect(t.pnlPct, closeTo(1000 / 15000 * 100, 0.001));
    });
  });

  group('instruments vault lifecycle (tracking-only)', () {
    late AppDatabase db;
    late InstrumentRepository vault;

    setUp(() async {
      db = AppDatabase.memory();
      vault = InstrumentRepository(db);
    });

    tearDown(() => db.close());

    test('create → revalue → archive → restore → delete', () async {
      final s0 = await vault.create(name: 'RELIANCE', kind: 'stock', invested: 10000, current: 10000, note: '10 shares');
      expect(s0.status, 'open');
      expect(s0.kind, 'stock');

      var s = await vault.revalue(s0.id, 11500);
      expect(s.current, 11500);
      expect(instrumentPnlPct(invested: s.invested, current: s.current), closeTo(15, 0.001));

      expect((await vault.open()).map((e) => e.id), contains(s0.id));
      s = await vault.archive(s0.id);
      expect(s.status, 'archived');
      expect((await vault.open()).map((e) => e.id), isNot(contains(s0.id)));

      s = await vault.unarchive(s0.id);
      expect(s.status, 'open');

      await vault.remove(s0.id);
      expect((await vault.all()).map((e) => e.id), isNot(contains(s0.id)));
    });

    test('paper trades + plans + notes share one vault', () async {
      await vault.create(name: 'Paper NIFTY', kind: 'paper', invested: 50000, current: 52000);
      await vault.create(name: 'Tax plan 2026', kind: 'plan', invested: 0, current: 0, note: '80C review');
      final open = await vault.open();
      expect(open.map((e) => e.kind).toSet(), containsAll(['paper', 'plan']));
      final t = portfolioTotals([for (final e in open) (invested: e.invested, current: e.current)]);
      expect(t.invested, 50000);
      expect(t.current, 52000);
    });

    test('bad inputs rejected, negative revalue rejected', () async {
      expect(() => vault.create(name: '  ', invested: 100, current: 100), throwsArgumentError);
      final ok = await vault.create(name: 'HDFC-FD', kind: 'fd', invested: 20000, current: 20000);
      expect(() => vault.revalue(ok.id, -5), throwsArgumentError);
    });
  });
}
