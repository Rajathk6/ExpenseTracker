/// Pure instruments math: P/L, interest, totals, validation. No DB — testable.
///
/// Vault rule: tracking-only. Buying/selling never auto-writes ledger rows,
/// so the dual-amount invariant (actual vs budgetImpact) stays untouched.
/// P/L% delegates to the single definition in core/ledger.dart.
library;

import 'dart:math' as math;

import '../../core/ledger.dart' show pnlPct;

/// Absolute profit/loss: positive = gain, negative = loss.
double pnl({required double invested, required double current}) => current - invested;

/// P/L% re-export of the ledger definition: (cur-inv)/inv*100, 0 when inv=0.
double instrumentPnlPct({required double invested, required double current}) =>
    pnlPct(invested: invested, current: current);

/// Simple interest: P*R*T/100. Rate is annual %, time in years.
double simpleInterest({required double principal, required double annualRatePct, required double years}) {
  if (principal <= 0 || years <= 0) return 0;
  return principal * annualRatePct / 100 * years;
}

/// Maturity value under simple interest.
double maturitySimple({required double principal, required double annualRatePct, required double years}) =>
    principal + simpleInterest(principal: principal, annualRatePct: annualRatePct, years: years);

/// Compound maturity: P*(1+r/n)^(n*t). Rate is annual %, n = compounds/year.
double maturityCompound({
  required double principal,
  required double annualRatePct,
  required double years,
  int compoundsPerYear = 1,
}) {
  if (principal <= 0 || years <= 0) return principal;
  final n = compoundsPerYear < 1 ? 1 : compoundsPerYear;
  final r = annualRatePct / 100;
  return (principal * math.pow(1 + r / n, n * years)).toDouble();
}

/// Validates a vault entry form. Returns error text, null when valid.
String? validateInstrument({required String name, required double invested, required double current}) {
  if (name.trim().isEmpty) return 'Name cannot be empty';
  if (invested < 0) return 'Invested cannot be negative';
  if (current < 0) return 'Current value cannot be negative';
  return null;
}

/// Portfolio totals over open holdings.
({double invested, double current, double pnl, double pnlPct}) portfolioTotals(
  List<({double invested, double current})> holdings,
) {
  var inv = 0.0, cur = 0.0;
  for (final h in holdings) {
    inv += h.invested;
    cur += h.current;
  }
  final p = cur - inv;
  return (invested: inv, current: cur, pnl: p, pnlPct: pnlPct(invested: inv, current: cur));
}
