/// Pure reports aggregation over plain records. No DB — testable.
///
/// All spend figures use planning truth (budgetImpact): transfers and
/// lending never pollute the charts. Reports read the ledger, never write.
library;

/// One outflow tagged for grouping.
typedef TaggedOut = ({String? tag, double out});

/// Sums absolute outflows by tag (`level0`, item, ...). Null/blank tags
/// fold into 'other'. Only positive [out] values count.
Map<String, double> sumsByTag(List<TaggedOut> moves) {
  final sums = <String, double>{};
  for (final m in moves) {
    if (m.out <= 0) continue;
    final tag = (m.tag == null || m.tag!.trim().isEmpty) ? 'other' : m.tag!.trim().toLowerCase();
    sums[tag] = (sums[tag] ?? 0) + m.out;
  }
  return sums;
}

/// Top [limit] slices, largest first, with the tail folded into 'other'.
/// Returns an empty list for empty input (never a phantom 'other').
List<({String label, double out})> topSlices(Map<String, double> sums, [int limit = 8]) {
  final entries = sums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  if (entries.isEmpty) return const [];
  if (entries.length <= limit) return [for (final e in entries) (label: e.key, out: e.value)];
  final head = [for (final e in entries.take(limit)) (label: e.key, out: e.value)];
  var tail = 0.0;
  for (final e in entries.skip(limit)) {
    tail += e.value;
  }
  return [...head, (label: 'other', out: tail)];
}

/// Label with the largest value, null when empty.
String? pickTop(Map<String, double> sums) {
  if (sums.isEmpty) return null;
  var best = sums.entries.first;
  for (final e in sums.entries) {
    if (e.value > best.value) best = e;
  }
  return best.key;
}

/// Cash-vs-digital split of absolute outflows by account kind.
/// Kinds containing 'cash' count as cash; everything else (cards, banks,
/// unlinked) counts as digital.
({double cash, double digital}) splitCashDigital(List<({String kind, double out})> moves) {
  var cash = 0.0, digital = 0.0;
  for (final m in moves) {
    if (m.out <= 0) continue;
    if (m.kind.toLowerCase().contains('cash')) {
      cash += m.out;
    } else {
      digital += m.out;
    }
  }
  return (cash: cash, digital: digital);
}
