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

/// My share of a split that is simply divided between the people in it
/// (#13: the owner picks how many, the maths does the rest).
double myShareFor({required double total, required int people}) => equalShare(total, people);

/// Share codes: four unambiguous characters, prefixed so a code says what it
/// is when it is read out over the phone.
String newCode(String prefix, int Function(int length) randomIndex) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I
  return '$prefix-${List.generate(4, (_) => alphabet[randomIndex(alphabet.length)]).join()}';
}

/// Validates a new split. Returns error text, null when valid.
/// [myShare] is derived from [people] now, but is still checked so a custom
/// share can never break the contract math.
String? validateSplit({required double total, required double myShare}) {
  if (total <= 0) return 'Total paid must be above zero';
  if (myShare < 0) return 'My share cannot be negative';
  if (myShare > total + 0.005) return 'My share cannot exceed the total paid';
  return null;
}

/// A split needs its people named — an unlabelled share cannot be settled
/// honestly (#14). The same person cannot be in it twice: you cannot be in a
/// split with yourself twice (#8).
String? validateMembers(List<String> names) {
  final clean = [for (final n in names) n.trim()].where((n) => n.isNotEmpty).toList();
  if (clean.isEmpty) return 'Add at least one person (your own name too)';
  final lowered = [for (final n in clean) n.toLowerCase()];
  if (lowered.toSet().length != lowered.length) return 'The same name is listed twice';
  return null;
}

/// A payment between two of the same name is a payment to yourself, which
/// would move no money and hide a mistake (#8).
String? validatePayBetween({required String from, required String to}) {
  if (from.trim().toLowerCase() == to.trim().toLowerCase()) {
    return 'That would be paying yourself';
  }
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
