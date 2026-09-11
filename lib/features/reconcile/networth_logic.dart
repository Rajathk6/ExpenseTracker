/// Pure net-worth math over plain records. No DB — testable.
///
/// Definition: netWorth = bankCash + investments − debtLiabilities +
/// lentReceivables, i.e. (openings + all ledger actuals) + instruments
/// current + lentRemaining − borrowedRemaining.
///
/// Honest limitation (documented in UI): investments and debts are current
/// manual values with no per-month history, so the timeline varies only
/// with bank/cash ledger movement. Per-month snapshots land in Phase 10.
library;

import 'reconcile_logic.dart';

typedef MoneyMove = ({DateTime at, double actual});
typedef DebtState = ({String direction, double principal, double paid});

/// Outstanding on one contract. Never negative (overpay rejected upstream).
double debtRemaining(double principal, double paid) =>
    (principal - paid).clamp(0, double.infinity);

/// Net debt position: lent outstanding is an asset (+), borrowed is a
/// liability (−).
double debtNet(List<DebtState> debts) {
  var net = 0.0;
  for (final d in debts) {
    final left = debtRemaining(d.principal, d.paid);
    net += d.direction == 'lent' ? left : -left;
  }
  return net;
}

/// Bank/cash position at [monthEnd] (inclusive): openings plus every ledger
/// actual up to that instant. All neutral/split/settle moves are actuals,
/// so they reconcile here by construction.
double bankAt({required double openings, required List<MoneyMove> moves, required DateTime monthEnd}) {
  var v = openings;
  for (final m in moves) {
    if (!m.at.isAfter(monthEnd)) v += m.actual;
  }
  return v;
}

/// Trailing [months] month-end points ending at [endKey] (oldest first).
List<({String key, double value})> netWorthTimeline({
  required double openings,
  required List<MoneyMove> moves,
  required double investCurrent,
  required double debtNetValue,
  required String endKey,
  int months = 12,
}) {
  final out = <({String key, double value})>[];
  for (var back = months - 1; back >= 0; back--) {
    final key = shiftMonthKey(endKey, -back);
    final end = monthBounds(key).end;
    out.add(
      (
        key: key,
        value: bankAt(openings: openings, moves: moves, monthEnd: end) + investCurrent + debtNetValue,
      ),
    );
  }
  return out;
}
