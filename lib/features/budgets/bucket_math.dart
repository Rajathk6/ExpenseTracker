/// Pure budget-bucket math. No DB, no UI — fully unit-testable.
///
/// Buckets are fully user-defined: any count, any names, any split as long as
/// percentages sum to 100 (within a cent). Presets are starting points only.
class Bucket {
  final String name;
  final double pct;
  const Bucket({required this.name, required this.pct});

  Map<String, dynamic> toJson() => {'name': name, 'pct': pct};

  static Bucket fromJson(Map<String, dynamic> json) =>
      Bucket(name: json['name'] as String, pct: (json['pct'] as num).toDouble());
}

/// Suggested starting points. Users can edit/ignore all of these.
const Map<String, List<Bucket>> bucketPresets = {
  '30/40/30': [
    Bucket(name: 'Needs', pct: 30),
    Bucket(name: 'Wants', pct: 40),
    Bucket(name: 'Invest', pct: 30),
  ],
  '50/30/20': [
    Bucket(name: 'Needs', pct: 50),
    Bucket(name: 'Wants', pct: 30),
    Bucket(name: 'Invest', pct: 20),
  ],
  '60/20/20': [
    Bucket(name: 'Needs', pct: 60),
    Bucket(name: 'Wants', pct: 20),
    Bucket(name: 'Invest', pct: 20),
  ],
};

/// Returns an error message when invalid, null when valid.
String? validateBuckets(List<Bucket> buckets) {
  if (buckets.isEmpty) return 'Add at least one bucket';
  final names = buckets.map((b) => b.name.trim().toLowerCase()).toList();
  if (names.any((n) => n.isEmpty)) return 'Bucket names cannot be empty';
  if (names.toSet().length != names.length) return 'Bucket names must be unique';
  if (buckets.any((b) => b.pct < 0)) return 'Percentages cannot be negative';
  if (buckets.any((b) => b.pct > 100)) return 'No bucket can exceed 100%';
  final sum = buckets.fold<double>(0, (s, b) => s + b.pct);
  if ((sum - 100).abs() > 0.01) return 'Buckets must sum to 100% (now ${sum.toStringAsFixed(1)}%)';
  return null;
}

/// Splits [total] across buckets. Validates first; throws [ArgumentError] if invalid.
Map<String, double> allocate(double total, List<Bucket> buckets) {
  final err = validateBuckets(buckets);
  if (err != null) throw ArgumentError(err);
  return {for (final b in buckets) b.name: total * b.pct / 100};
}
