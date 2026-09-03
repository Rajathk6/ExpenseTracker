/// Dual-amount ledger math. Single place where money meaning is decided.
///
/// actual       = bank/cash impact (statement truth)
/// budgetImpact = what counts toward the monthly budget (planning truth)
/// Invariant: transfers and lending move actual but leave budgetImpact = 0.
class LedgerEntry {
  final double actual;
  final double budgetImpact;
  const LedgerEntry({required this.actual, required this.budgetImpact});
}

/// Plain spend: both move together.
LedgerEntry spend(double amount) => LedgerEntry(actual: -amount, budgetImpact: -amount);

/// Income: both move together.
LedgerEntry income(double amount) => LedgerEntry(actual: amount, budgetImpact: amount);

/// Transfer (e.g. ATM Bank->Cash): no budget effect.
LedgerEntry transfer(double amount) => LedgerEntry(actual: -amount, budgetImpact: 0);

/// Lend/borrow principal: excluded from budget by design.
LedgerEntry neutralOut(double amount) => LedgerEntry(actual: -amount, budgetImpact: 0);
LedgerEntry neutralIn(double amount) => LedgerEntry(actual: amount, budgetImpact: 0);

/// Split: I pay [total] now, my fair share is [myShare].
/// Returns (entry for me now, receivable from others).
({LedgerEntry entry, double receivable}) splitPay({required double total, required double myShare}) {
  assert(myShare <= total, 'myShare cannot exceed total paid');
  return (entry: LedgerEntry(actual: -total, budgetImpact: -myShare), receivable: total - myShare);
}

/// Month reconciliation: expected end vs counted end.
/// missing > 0 means money left without a tracked entry.
double reconcileMissing({required double open, required double inflows, required double outflows, required double countedClose}) {
  return (open + inflows - outflows) - countedClose;
}

/// Investment P/L %.
double pnlPct({required double invested, required double current}) {
  if (invested == 0) return 0;
  return (current - invested) / invested * 100;
}
