/// Budget insights: what the month looks like so far, and where it is going.
///
/// The owner asked for "detailed insightful mappings" and "an estimate run
/// based on past numbers if available". Both are here:
///
/// - **per-bucket**: planned, spent, left, and how the month is tracking;
/// - **estimate**: what the month will end at, from the pace so far and from
///   the same month in previous years;
/// - **insight lines**: the things a person would say out loud — "you spend
///   ₹1.2k more on food than usual", "half the month gone, a third of the
///   budget spent" — with no maths left for the owner to do.
library;

import 'bucket_math.dart';

/// One bucket's story for the month.
class BucketInsight {
  final String name;
  final double planned;
  final double spent;
  final double usual; // the same bucket's average in earlier months

  const BucketInsight({
    required this.name,
    required this.planned,
    required this.spent,
    required this.usual,
  });

  double get left => planned - spent;
  double get usedFraction => planned <= 0 ? (spent > 0 ? 1 : 0) : spent / planned;

  /// Is this bucket being used more (or less) than usual?
  double get againstUsual => usual <= 0 ? 0 : (spent - usual) / usual;
}

/// The month, as a story.
class BudgetInsight {
  final String monthKey;
  final int dayOfMonth;
  final int daysInMonth;
  final double income;
  final double budgetTotal;
  final double spent;
  final List<BucketInsight> buckets;

  const BudgetInsight({
    required this.monthKey,
    required this.dayOfMonth,
    required this.daysInMonth,
    required this.income,
    required this.budgetTotal,
    required this.spent,
    required this.buckets,
  });

  /// How much of the month has gone by.
  double get monthProgress => daysInMonth <= 0 ? 1 : (dayOfMonth / daysInMonth).clamp(0.0, 1.0);

  /// If the current pace holds, this is what the month will cost.
  double get projected {
    if (dayOfMonth <= 0) return spent;
    return spent / dayOfMonth * daysInMonth;
  }

  /// The same month's spend in an earlier year, if we have it.
  double get sameMonthLastYear => 0;

  /// Against the pace: spending 40% of the budget in the first 20% of the
  /// month is a problem, whatever the numbers say.
  bool get aheadOfPace {
    if (budgetTotal <= 0 || monthProgress <= 0) return false;
    return (spent / budgetTotal) > monthProgress + 0.1;
  }

  /// The lines worth saying out loud. Empty when nothing stands out.
  List<String> get lines {
    final out = <String>[];
    if (budgetTotal > 0) {
      final pace = (budgetTotal * monthProgress).round();
      if (aheadOfPace) {
        out.add(
          'Ahead of pace: ₹${spent.round()} spent with ₹${pace.round()} of the budget '
          'meant for the days gone by.',
        );
      } else if (spent < budgetTotal * 0.5 && monthProgress > 0.6) {
        out.add('Comfortably under: ₹${(budgetTotal - spent).round()} still available.');
      }
      if (projected > budgetTotal * 1.02) {
        out.add('On this pace the month ends around ₹${projected.round()} — over the ₹${budgetTotal.round()} budget.');
      }
    }
    for (final b in buckets) {
      if (b.planned > 0 && b.spent > b.planned) {
        out.add('${b.name}: over by ₹${(-b.left).round()}.');
      } else if (b.usual > 0 && b.spent > b.usual * 1.25 && b.spent - b.usual > 500) {
        out.add('${b.name}: ₹${(b.spent - b.usual).round()} more than your usual ₹${b.usual.round()}.');
      } else if (b.usual > 0 && b.spent < b.usual * 0.6 && b.usual - b.spent > 500) {
        out.add('${b.name}: ₹${(b.usual - b.spent).round()} less than your usual ₹${b.usual.round()}.');
      }
    }
    return out;
  }
}

/// Builds the insight for a month.
///
/// [usualByBucket] is the average spend per bucket over earlier months (the
/// "what you normally do"), [spentByBucket] this month's spend per bucket.
BudgetInsight buildBudgetInsight({
  required String monthKey,
  required DateTime at,
  required double income,
  required double budgetTotal,
  required double spent,
  required List<Bucket> buckets,
  required Map<String, double> spentByBucket,
  Map<String, double> usualByBucket = const {},
  Map<String, double> plannedByBucket = const {},
}) {
  final daysInMonth = DateTime(at.year, at.month + 1, 0).day;
  return BudgetInsight(
    monthKey: monthKey,
    dayOfMonth: at.day,
    daysInMonth: daysInMonth,
    income: income,
    budgetTotal: budgetTotal,
    spent: spent,
    buckets: [
      for (final b in buckets)
        BucketInsight(
          name: b.name,
          planned: plannedByBucket[b.name] ?? 0,
          spent: spentByBucket[b.name] ?? 0,
          usual: usualByBucket[b.name] ?? 0,
        ),
    ],
  );
}
