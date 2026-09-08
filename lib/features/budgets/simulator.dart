/// Budget simulator (pure): preview any bucket split against real history.
/// Answers "what would 30/40/30 have given me for the last 3 months?"
/// No DB, no UI — fully unit-testable.
library;

import 'bucket_math.dart';

/// Per-bucket hypothetical amounts, one entry per past month (oldest first),
/// plus the monthly average. Assumes [buckets] already validated.
Map<String, ({List<double> perMonth, double avg})> simulate(
  List<Bucket> buckets,
  List<double> pastMonthlyOut,
) {
  return {
    for (final b in buckets)
      b.name: (
        perMonth: [for (final out in pastMonthlyOut) out * b.pct / 100],
        avg: pastMonthlyOut.isEmpty
            ? 0
            : pastMonthlyOut.fold<double>(0, (s, o) => s + o * b.pct / 100) / pastMonthlyOut.length,
      ),
  };
}
