import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/category_parser.dart';
import 'package:expense_tracker/core/ledger.dart';
import 'package:expense_tracker/core/intake/share_parser.dart';

void main() {
  group('category parser (flexible levels)', () {
    test('food junk gobi-65', () {
      final p = parseCategory('food junk gobi-65');
      expect(p.levels, ['food', 'junk', 'gobi']);
      expect(p.item, 'gobi-65');
    });
    test('food healthy sweet-potato', () {
      final p = parseCategory('food healthy sweet-potato');
      expect(p.levels, ['food', 'healthy', 'sweet']);
      expect(p.item, 'sweet-potato');
    });
    test('single level', () {
      final p = parseCategory('rent');
      expect(p.levels, ['rent']);
      expect(p.item, isNull);
    });
  });

  group('ledger dual-amount', () {
    test('split 1000/10', () {
      final r = splitPay(total: 1000, myShare: 100);
      expect(r.entry.actual, -1000);
      expect(r.entry.budgetImpact, -100);
      expect(r.receivable, 900);
    });
    test('lend excludes budget', () {
      expect(neutralOut(5000).budgetImpact, 0);
      expect(neutralOut(5000).actual, -5000);
    });
    test('reconcile missing', () {
      expect(reconcileMissing(open: 10000, inflows: 2000, outflows: 3000, countedClose: 9000), 0);
      expect(reconcileMissing(open: 10000, inflows: 2000, outflows: 3000, countedClose: 8500), 500);
    });
    test('pnl', () {
      expect(pnlPct(invested: 1000, current: 1100), 10);
    });
  });

  group('share parser', () {
    test('Paid Rs.450 to Swiggy', () {
      final s = parseSharedText('Paid Rs.450 to Swiggy');
      expect(s.amount, 450);
    });
  });
}
