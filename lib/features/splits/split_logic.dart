/// Pure split math: shares, receivables, payoffs, absorb, settle-up.
/// I pay the whole bill; only my share hits the budget until someone defaults.
library;

/// What others still owe me. Never negative. My own share was never theirs.
double receivable(double totalPaid, double myShare, double received, double absorbed) =>
    (totalPaid - myShare - received - absorbed).clamp(0, double.infinity);

/// Outstanding on a split contract (same number, contract-centric name).
double splitRemaining(double totalPaid, double myShare, double received, double absorbed) =>
    receivable(totalPaid, myShare, received, absorbed);

/// Equal per-person share. Throws when headcount < 1.
double equalShare(double total, int people) {
  if (people < 1) throw ArgumentError('Need at least one person');
  return total / people;
}

/// Validates a new split. Returns error text, null when valid.
String? validateSplit({required double total, required double myShare}) {
  if (total <= 0) return 'Total paid must be above zero';
  if (myShare < 0) return 'My share cannot be negative';
  if (myShare > total + 0.005) return 'My share cannot exceed the total paid';
  return null;
}

/// Validates one incoming settlement. Returns error text, null when valid.
String? validateSettlement({required double amount, required double totalPaid, required double myShare, required double received, required double absorbed}) {
  if (amount <= 0) return 'Amount must be above zero';
  if (amount > receivable(totalPaid, myShare, received, absorbed) + 0.005) {
    return 'Over-settle rejected: ₹${receivable(totalPaid, myShare, received, absorbed).toStringAsFixed(2)} left';
  }
  return null;
}

/// One minimal-transfer suggestion: who pays whom how much.
/// Greedy debtor→creditor matching on net balances (owed positive = receives).
List<({String from, String to, double amount})> settleUp(Map<String, double> net) {
  final debtors = net.entries.where((e) => e.value < -0.005).map((e) => MapEntry(e.key, -e.value)).toList();
  final creditors = net.entries.where((e) => e.value > 0.005).map((e) => MapEntry(e.key, e.value)).toList();
  debtors.sort((a, b) => b.value.compareTo(a.value));
  creditors.sort((a, b) => b.value.compareTo(a.value));
  final out = <({String from, String to, double amount})>[];
  var i = 0, j = 0;
  while (i < debtors.length && j < creditors.length) {
    final pay = debtors[i].value < creditors[j].value ? debtors[i].value : creditors[j].value;
    out.add((from: debtors[i].key, to: creditors[j].key, amount: (pay * 100).round() / 100));
    debtors[i] = MapEntry(debtors[i].key, debtors[i].value - pay);
    creditors[j] = MapEntry(creditors[j].key, creditors[j].value - pay);
    if (debtors[i].value <= 0.005) i++;
    if (creditors[j].value <= 0.005) j++;
  }
  return out;
}
