/// Pure reconcile math. Month keys live in core/months.dart (re-exported
/// here so existing importers keep working). No DB — testable.
///
/// Model: each account snapshots an opening balance at month-start and a
/// physically-counted close at month-end. Expected close comes from the
/// ledger; the gap is untracked money.
library;

export '../../core/months.dart';

/// Statement-truth close: what the ledger says should be there.
/// [inflows] and [outflows] are absolute (non-negative) sums.
double expectedClose({required double open, required double inflows, required double outflows}) =>
    open + inflows - outflows;

/// Untracked money: positive = cash left with no entry (short),
/// negative = extra cash with no entry (excess).
double reconcileGap({required double expected, required double counted}) => expected - counted;

/// Labels the gap: balanced within [tolerance], else short/excess.
String reconcileStatus(double gap, [double tolerance = 0.005]) {
  if (gap.abs() <= tolerance) return 'balanced';
  return gap > 0 ? 'short' : 'excess';
}
