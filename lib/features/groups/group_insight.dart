/// Group insights: what the group spent, who spent it, on what, and the
/// biggest single item — plus the balances and the settle-up.
///
/// Pure maths over the group's expenses and payments, so the numbers in the
/// screen and in the group's report come from one place.
library;

import '../../core/database.dart';
import 'group_repository.dart';

/// One line of a group's spending story.
class GroupInsight {
  final String label;
  final double amount;
  final int count;
  const GroupInsight(this.label, this.amount, this.count);
}

class GroupInsightReport {
  final String name;
  final String code;
  final String monthKey;
  final double totalSpent;
  final int expenseCount;
  final int peopleCount;

  /// Spend per person (who fronted the most).
  final List<GroupInsight> perPerson;

  /// Spend per category/title.
  final List<GroupInsight> perTitle;

  /// The single biggest expense.
  final GroupInsight? largest;

  /// What each person is owed or owes.
  final List<Balance> balances;

  /// The minimum set of transfers that settles the group up.
  final List<({String from, String to, double amount})> settleUp;

  /// How evenly the spending was shared: 1.0 = perfectly even, lower = one
  /// person carried more.
  final double evenness;

  const GroupInsightReport({
    required this.name,
    required this.code,
    required this.monthKey,
    required this.totalSpent,
    required this.expenseCount,
    required this.peopleCount,
    required this.perPerson,
    required this.perTitle,
    required this.largest,
    required this.balances,
    required this.settleUp,
    required this.evenness,
  });

  /// The lines worth saying out loud.
  List<String> get lines {
    final out = <String>[];
    if (totalSpent > 0 && peopleCount > 0) {
      out.add('₹${totalSpent.round()} over $expenseCount ${expenseCount == 1 ? 'entry' : 'entries'} · '
          'about ₹${(totalSpent / peopleCount).round()} each.');
    }
    if (largest != null && largest!.amount > 0) {
      out.add('Biggest: ${largest!.label} ₹${largest!.amount.round()}'
          '${largest!.count > 1 ? ' (${largest!.count}×)' : ''}');
    }
    if (perPerson.isNotEmpty) {
      final top = perPerson.first;
      out.add('${top.label} fronted the most: ₹${top.amount.round()}');
    }
    if (evenness < 0.8 && perPerson.length > 1) {
      out.add('Not shared evenly — the difference between the most and the least is '
          '₹${(perPerson.first.amount - perPerson.last.amount).round()}');
    }
    if (settleUp.isNotEmpty) {
      for (final move in settleUp) {
        out.add('${move.from} pays ${move.to} ₹${move.amount.round()}');
      }
    } else if (balances.isNotEmpty) {
      out.add('Everyone is settled up.');
    }
    return out;
  }
}

/// Builds the insight for one group.
GroupInsightReport buildGroupInsight({
  required String name,
  required String code,
  required String monthKey,
  required List<GroupMember> members,
  required List<GroupExpense> expenses,
  required List<GroupPayment> payments,
}) {
  var total = 0.0;
  final perPerson = <String, double>{};
  final perTitle = <String, double>{};
  final titleCounts = <String, int>{};
  GroupInsight? largest;

  for (final e in expenses) {
    total += e.amount;
    final payer = e.paidBy.isEmpty ? 'split evenly' : e.paidBy;
    perPerson[payer] = (perPerson[payer] ?? 0) + e.amount;
    perTitle[e.title] = (perTitle[e.title] ?? 0) + e.amount;
    titleCounts[e.title] = (titleCounts[e.title] ?? 0) + 1;
    if (largest == null || e.amount > largest.amount) {
      largest = GroupInsight(e.title, e.amount, 1);
    }
  }
  if (largest != null) {
    final key = perTitle.entries.firstWhere((e) => e.value == largest!.amount).key;
    largest = GroupInsight(key, largest.amount, titleCounts[key] ?? 1);
  }

  final net = <String, double>{for (final m in members) m.name: 0};
  for (final e in expenses) {
    if (e.paidBy.isEmpty) continue;
    final share = e.amount / (members.isEmpty ? 1 : members.length);
    for (final m in members) {
      net[m.name] = net[m.name]! - share;
    }
    net[e.paidBy] = net[e.paidBy]! + e.amount;
  }
  for (final p in payments) {
    if (net.containsKey(p.paidBy)) net[p.paidBy] = net[p.paidBy]! + p.amount;
    if (net.containsKey(p.paidTo)) net[p.paidTo] = net[p.paidTo]! - p.amount;
  }
  final balances = [
    for (final m in members) Balance(m.name, (net[m.name]! * 100).round() / 100),
  ];

  final people = balances.length;
  final amounts = perPerson.values.toList()..sort();
  var evenness = 1.0;
  if (people > 1 && amounts.length > 1 && amounts.last > 0) {
    evenness = 1 - ((amounts.last - amounts.first) / amounts.last).clamp(0.0, 1.0);
  }

  return GroupInsightReport(
    name: name,
    code: code,
    monthKey: monthKey,
    totalSpent: total,
    expenseCount: expenses.length,
    peopleCount: people,
    perPerson: [
      for (final e in perPerson.entries) GroupInsight(e.key, e.value, 1),
    ]..sort((a, b) => b.amount.compareTo(a.amount)),
    perTitle: [
      for (final e in perTitle.entries) GroupInsight(e.key, e.value, titleCounts[e.key] ?? 1),
    ]..sort((a, b) => b.amount.compareTo(a.amount)),
    largest: largest,
    balances: balances,
    settleUp: settleUpFor(balances),
    evenness: evenness,
  );
}

/// The minimum set of transfers that settles [balances] up.
List<({String from, String to, double amount})> settleUpFor(List<Balance> balances) {
  final debtors = [
    for (final b in balances)
      if (b.owes) (name: b.name, amount: -b.net),
  ]..sort((a, b) => b.amount.compareTo(a.amount));
  final creditors = [
    for (final b in balances)
      if (b.isOwed) (name: b.name, amount: b.net),
  ]..sort((a, b) => b.amount.compareTo(a.amount));
  final out = <({String from, String to, double amount})>[];
  var i = 0, j = 0;
  while (i < debtors.length && j < creditors.length) {
    final pay = debtors[i].amount < creditors[j].amount ? debtors[i].amount : creditors[j].amount;
    out.add((from: debtors[i].name, to: creditors[j].name, amount: (pay * 100).round() / 100));
    debtors[i] = (name: debtors[i].name, amount: debtors[i].amount - pay);
    creditors[j] = (name: creditors[j].name, amount: creditors[j].amount - pay);
    if (debtors[i].amount <= 0.005) i++;
    if (creditors[j].amount <= 0.005) j++;
  }
  return out;
}
