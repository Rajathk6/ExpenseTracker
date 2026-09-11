/// Pure price-memory math: per-item price history stats. No DB — testable.
///
/// Prices are absolute spend amounts (outflows). The vault never guesses:
/// with fewer than 2 sightings there is no average and no overpay flag.
library;

/// Keeps only spends (negative actuals) as positive prices.
List<double> pricesOf(Iterable<double> actuals) =>
    [for (final a in actuals) if (a < 0) -a];

/// avg/min/max/latest over [prices] plus an overpay flag.
/// `overpay` is true when the latest sighting costs more than the average
/// of all sightings (needs count >= 2).
({double avg, double min, double max, double latest, int count, bool overpay}) priceStats(
  List<double> prices,
) {
  if (prices.isEmpty) return (avg: 0, min: 0, max: 0, latest: 0, count: 0, overpay: false);
  var sum = 0.0, min = prices.first, max = prices.first;
  for (final p in prices) {
    sum += p;
    if (p < min) min = p;
    if (p > max) max = p;
  }
  final avg = sum / prices.length;
  final latest = prices.last;
  return (
    avg: avg,
    min: min,
    max: max,
    latest: latest,
    count: prices.length,
    overpay: prices.length >= 2 && latest > avg,
  );
}
