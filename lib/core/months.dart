/// Shared month-key helpers. Pure functions, no dependencies.
///
/// Keys are `YYYY-MM`. Used by budgets, reconcile, net worth and reports —
/// lives in core so features never import each other.
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
