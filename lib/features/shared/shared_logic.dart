/// Pure helpers shared by the merged "Shared money" screen: totals that the
/// tabs show in their header, so a card can never quote a different number
/// from the list under it.
library;

import '../../core/database.dart';
import '../splits/split_logic.dart';

/// Total still outstanding across [debts] (one direction), whole rupees.
double sharedDebtTotals(List<Debt> debts) {
  var total = 0.0;
  for (final d in debts) {
    if (d.status != 'open') continue;
    total += remainingOn(d);
  }
  return total;
}

/// Never negative, never above the principal.
double remainingOn(Debt d) => (d.principal - d.paid).clamp(0, double.infinity);

/// Total still owed to the owner across open splits.
double splitOutstandingTotal(List<Split> splits) {
  var total = 0.0;
  for (final s in splits) {
    total += splitRemaining(s.totalPaid, s.myShare, s.received, s.absorbed);
  }
  return total;
}