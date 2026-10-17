/// Month budget truth, as one pure function so the alerts, the budget screen
/// and the front card can never disagree.
///
/// Owner rules (2026-09-27):
/// - the month's **income** is the yardstick: the budget is what came in, so
///   a ₹60k salary budgeted against ₹0 income has to read as "not funded yet",
///   not as "on track";
/// - the bucket split is carried forward until it is changed, and changing it
///   only affects months from that point on (every month is its own row);
/// - spending is measured against the *planned* amount for the bucket, so the
///   alert fires when money is nearly gone, not only when it is gone.
library;

import 'bucket_math.dart';

/// How a bucket is doing. [planned] is 0 when the owner has not funded it yet.
enum BudgetLevel {
  /// No budget set for this bucket.
  unfunded,

  /// Spending has not started.
  untouched,

  /// Under 75% used.
  healthy,

  /// 75–99% used — worth knowing before the rest of the month.
  low,

  /// 100% used or more.
  over,
}

class BucketStatus {
  final String name;
  final double planned;
  final double spent;
  BucketStatus(this.name, this.planned, this.spent);

  double get left => planned - spent;
  double get usedFraction => planned <= 0 ? (spent > 0 ? 1 : 0) : spent / planned;
  BudgetLevel get level {
    if (planned <= 0) return spent > 0 ? BudgetLevel.unfunded : BudgetLevel.untouched;
    final used = usedFraction;
    if (used >= 1) return BudgetLevel.over;
    if (used >= 0.75) return BudgetLevel.low;
    if (spent <= 0) return BudgetLevel.untouched;
    return BudgetLevel.healthy;
  }
}

class BudgetStatusReport {
  final double income;
  final double budgetTotal;
  final double spent;
  final String sourceMonth;
  final List<BucketStatus> buckets;

  const BudgetStatusReport({
    required this.income,
    required this.budgetTotal,
    required this.spent,
    required this.sourceMonth,
    required this.buckets,
  });

  /// Money left to spend this month, never below zero in the UI maths.
  double get left => budgetTotal - spent;

  /// Spend as a share of what actually came in (the owner's yardstick).
  double get usedOfIncome => income <= 0 ? (spent > 0 ? 1 : 0) : spent / income;

  BudgetLevel get level {
    if (budgetTotal <= 0) return BudgetLevel.unfunded;
    final used = spent / budgetTotal;
    if (used >= 1) return BudgetLevel.over;
    if (used >= 0.75) return BudgetLevel.low;
    if (spent <= 0) return BudgetLevel.untouched;
    return BudgetLevel.healthy;
  }

  /// Lines worth showing the owner. Empty when everything is fine — an alert
  /// that is always on is an alert nobody reads.
  List<String> get alerts {
    final lines = <String>[];
    if (budgetTotal > 0 && income <= 0 && spent > 0) {
      lines.add('₹${spent.round()} spent but nothing recorded as income this month — set your income so the budget has a scale.');
    }
    if (budgetTotal > 0 && income > 0 && spent > income) {
      lines.add('Spending (₹${spent.round()}) is above this month\'s income (₹${income.round()}) by ₹${(spent - income).round()}.');
    }
    for (final b in buckets) {
      switch (b.level) {
        case BudgetLevel.over:
          lines.add('${b.name}: over by ₹${(-b.left).round()} (${b.planned.round()} planned).');
        case BudgetLevel.low:
          lines.add('${b.name}: ₹${b.left.round()} left of ₹${b.planned.round()}.');
        case BudgetLevel.unfunded:
          lines.add('${b.name}: ₹${b.spent.round()} spent with no budget set for it.');
        case BudgetLevel.healthy:
        case BudgetLevel.untouched:
          break;
      }
    }
    return lines;
  }
}

/// Builds the report from raw numbers. [bucketSpend] maps a bucket label to its
/// spend (negative budgetImpact sums, per the repository's convention).
BudgetStatusReport buildBudgetStatus({
  required double income,
  required double budgetTotal,
  required double spent,
  required String sourceMonth,
  required List<Bucket> buckets,
  Map<String, double> bucketSpend = const {},
}) {
  final planned = budgetTotal <= 0 || buckets.isEmpty ? const <String, double>{} : allocate(budgetTotal, buckets);
  // Spend with no bucket goes to an explicit "unassigned" line rather than
  // disappearing — untracked spending is exactly what the owner wants to see.
  final known = {...planned.keys};
  final unassigned = <String, double>{};
  for (final entry in bucketSpend.entries) {
    final label = entry.key.trim().isEmpty ? 'unassigned' : entry.key;
    final value = entry.value.abs();
    if (known.contains(label)) {
      planned[label] = planned[label]! + value;
    } else {
      unassigned[label] = (unassigned[label] ?? 0) + value;
    }
  }
  final statuses = <BucketStatus>[
    for (final b in buckets) BucketStatus(b.name, planned[b.name] ?? 0, bucketSpend[b.name]?.abs() ?? 0),
  ];
  if (unassigned.isNotEmpty) {
    for (final entry in unassigned.entries) {
      statuses.add(BucketStatus(entry.key, 0, entry.value));
    }
  }
  return BudgetStatusReport(
    income: income,
    budgetTotal: budgetTotal,
    spent: spent,
    sourceMonth: sourceMonth,
    buckets: statuses,
  );
}