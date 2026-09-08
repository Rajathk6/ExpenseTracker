/// Pure debt math: directions, payoff validation, aging. No DB — testable.
/// All money moves through Transactions with budgetImpact 0 (neutral ledger).
library;

/// Outstanding on a contract. Never negative (overpay is rejected upstream).
double remaining(double principal, double paid) => (principal - paid).clamp(0, double.infinity);

/// Full days since [createdAt] as of [now]. Negative dates clamp to 0.
int agingDays(DateTime createdAt, DateTime now) {
  final days = now.difference(createdAt).inDays;
  return days < 0 ? 0 : days;
}

/// True when past due and still open.
bool isOverdue({required DateTime? dueDate, required String status, required DateTime now}) {
  if (dueDate == null || status != 'open') return false;
  return !now.isBefore(DateTime(dueDate.year, dueDate.month, dueDate.day + 1));
}

/// True when a local nudge is due (nudge date reached, still open).
bool nudgeDue({required DateTime? nudgeDate, required String status, required DateTime now}) {
  if (nudgeDate == null || status != 'open') return false;
  return !now.isBefore(nudgeDate);
}

/// Signed statement amount for a payoff chunk: lending returns money (+),
/// borrowing repays money (−). Throws on non-positive amounts or overpay.
double payoffActual({required String direction, required double amount, required double principal, required double paid}) {
  if (direction != 'lent' && direction != 'borrowed') {
    throw ArgumentError('direction must be lent/borrowed (got "$direction")');
  }
  if (amount <= 0) throw ArgumentError('Payment must be above zero');
  if (paid + amount > principal + 0.005) {
    throw ArgumentError(
      'Overpay rejected: ${remaining(principal, paid).toStringAsFixed(2)} left, got ${amount.toStringAsFixed(2)}',
    );
  }
  return direction == 'lent' ? amount : -amount;
}
