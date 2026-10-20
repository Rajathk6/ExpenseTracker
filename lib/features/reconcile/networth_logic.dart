/// Net worth, done properly.
///
/// The owner's question is "what am I actually worth right now?", and the
/// answer is **what I hold − what I owe**:
///
/// ```text
/// assets   = cash in my accounts
///          + investments (FD, MF, stocks… at their marked value)
///          + money others owe me (lends not returned, split shares not paid back)
/// liabilities = money I owe others (borrowings not repaid)
/// net worth = assets − liabilities
/// ```
///
/// The old version counted the ledger's movements and added investments, which
/// double-counted lends (the cash left *and* the receivable was missing) and
/// ignored what the owner owes. This is the version that balances: every
/// rupee is either held, owed to the owner, or owed by the owner.
library;

/// One month-end snapshot.
class NetWorthPoint {
  final String monthKey;
  /// Cash across the owner's accounts (opening balances + everything that moved).
  final double cash;
  /// Investments at their current marked value.
  final double investments;
  /// Lends not returned + split shares not paid back.
  final double owedToYou;
  /// Borrowings not repaid.
  final double youOwe;

  const NetWorthPoint({
    required this.monthKey,
    required this.cash,
    required this.investments,
    required this.owedToYou,
    required this.youOwe,
  });

  double get assets => cash + investments + owedToYou;
  double get liabilities => youOwe;
  double get net => assets - liabilities;
}

/// A money movement that is not a neutral one (a lend/borrow is handled by the
/// obligations below, not as a plain movement).
class NetMove {
  final DateTime at;
  final double actual;
  const NetMove(this.at, this.actual);
}

/// What the owner is owed and owes at a point in time.
class Obligations {
  /// Lends not returned yet.
  final double lent;
  /// Split shares still to come back.
  final double splitReceivable;
  /// Borrowings not repaid yet.
  final double borrowed;

  const Obligations({
    required this.lent,
    required this.splitReceivable,
    required this.borrowed,
  });

  static const zero = Obligations(lent: 0, splitReceivable: 0, borrowed: 0);
}

/// Month-end net worth for the window ending at [endMonthKey].
///
/// [moves] are the plain money movements (spending and income; lends and
/// borrows are *not* here — they show up as obligations, so the cash that
/// left for a lend is not counted twice).
/// [obligationsByMonth] is the owed/owing picture at each month end.
/// [investments] is the current marked value of the vault.
List<NetWorthPoint> netWorthTimeline({
  required List<NetMove> moves,
  required List<({String monthKey, Obligations obligations})> obligationsByMonth,
  required double investments,
  required String endMonthKey,
  int months = 12,
}) {
  final end = _parse(endMonthKey);
  final points = <NetWorthPoint>[];
  var cash = 0.0;
  var index = 0;
  for (var back = months - 1; back >= 0; back--) {
    final month = DateTime(end.year, end.month - back);
    final key = _key(month);
    // Everything that happened up to the end of this month.
    while (index < moves.length && !moves[index].at.isAfter(DateTime(month.year, month.month + 1))) {
      cash += moves[index].actual;
      index++;
    }
    final obligations = _obligationsFor(obligationsByMonth, key);
    points.add(
      NetWorthPoint(
        monthKey: key,
        cash: cash,
        investments: investments,
        owedToYou: obligations.lent + obligations.splitReceivable,
        youOwe: obligations.borrowed,
      ),
    );
  }
  return points;
}

/// The obligations in force at [monthKey]: the last snapshot at or before it.
Obligations _obligationsFor(
  List<({String monthKey, Obligations obligations})> snapshots,
  String monthKey,
) {
  Obligations best = Obligations.zero;
  var bestKey = '';
  for (final s in snapshots) {
    if (s.monthKey.compareTo(monthKey) <= 0 && s.monthKey.compareTo(bestKey) >= 0) {
      best = s.obligations;
      bestKey = s.monthKey;
    }
  }
  return best;
}

String _key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

DateTime _parse(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]));
}
