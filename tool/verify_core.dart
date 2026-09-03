// Standalone core verification (no flutter_test needed).
// Mirrors test/core_test.dart using relative imports so plain `dart` can run it.
import '../lib/core/category_parser.dart';
import '../lib/core/ledger.dart';
import '../lib/core/intake/share_parser.dart';

void check(bool cond, String name) {
  if (!cond) throw StateError('FAIL: $name');
  print('ok: $name');
}

void main() {
  // Category parser
  var p = parseCategory('food junk gobi-65');
  check(p.levels.join(',') == 'food,junk,gobi', 'gobi-65 levels');
  check(p.item == 'gobi-65', 'gobi-65 item');

  p = parseCategory('food healthy sweet-potato');
  check(p.levels.join(',') == 'food,healthy,sweet', 'sweet-potato levels');
  check(p.item == 'sweet-potato', 'sweet-potato item');

  p = parseCategory('rent');
  check(p.levels.join(',') == 'rent' && p.item == null, 'single level');

  p = parseCategory('   ');
  check(p.levels.isEmpty && p.item == null, 'blank input');

  // Ledger
  final r = splitPay(total: 1000, myShare: 100);
  check(r.entry.actual == -1000 && r.entry.budgetImpact == -100 && r.receivable == 900, 'split 1000/10');
  check(neutralOut(5000).budgetImpact == 0 && neutralOut(5000).actual == -5000, 'lend excludes budget');
  check(reconcileMissing(open: 10000, inflows: 2000, outflows: 3000, countedClose: 9000) == 0, 'reconcile exact');
  check(reconcileMissing(open: 10000, inflows: 2000, outflows: 3000, countedClose: 8500) == 500, 'reconcile missing 500');
  check(pnlPct(invested: 1000, current: 1100) == 10, 'pnl 10%');
  check(pnlPct(invested: 0, current: 500) == 0, 'pnl zero guard');

  // Share parser
  var s = parseSharedText('Paid Rs.450 to Swiggy');
  check(s.amount == 450, 'share Rs.450');
  s = parseSharedText('Sent ₹1,000.00 to Rahul');
  check(s.amount == 1000.00, 'share ₹1,000.00');
  s = parseSharedText('');
  check(s.amount == null, 'share blank');

  print('ALL_CORE_CHECKS_PASSED');
}
