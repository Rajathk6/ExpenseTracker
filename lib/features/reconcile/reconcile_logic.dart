/// Pure reconcile math + month-key helpers. No DB — testable.
///
/// Model: each account snapshots an opening balance at month-start and a
/// physically-counted close at month-end. Expected close comes from the
/// ledger; the gap is untracked money.
library;

/// `YYYY-MM` key for a date.
String monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

/// First day of the month described by [key].
DateTime monthStart(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]));
}

/// Inclusive [start, end] bounds covering the whole calendar month.
({DateTime start, DateTime end}) monthBounds(String key) {
  final start = monthStart(key);
  final end = DateTime(start.year, start.month + 1).subtract(const Duration(milliseconds: 1));
  return (start: start, end: end);
}

/// Shifts a month key by [delta] months (negative = back). Handles year roll.
String shiftMonthKey(String key, int delta) {
  var y = int.parse(key.split('-')[0]);
  var m = int.parse(key.split('-')[1]) + delta;
  while (m <= 0) {
    m += 12;
    y--;
  }
  while (m > 12) {
    m -= 12;
    y++;
  }
  return '$y-${m.toString().padLeft(2, '0')}';
}

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
