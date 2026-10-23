import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/budgets/bucket_math.dart';
import 'package:expense_tracker/features/budgets/budget_insight.dart';
import 'package:expense_tracker/features/groups/group_insight.dart';
import 'package:expense_tracker/features/groups/group_report.dart';

void main() {
  group('budget insight: pace and estimate (#7)', () {
    BudgetInsight insight({
      required int day,
      required int days,
      required double spent,
      required double budget,
      Map<String, double> spentByBucket = const {},
      Map<String, double> usual = const {},
    }) =>
        buildBudgetInsight(
          monthKey: '2026-09',
          at: DateTime(2026, 9, day),
          income: 60000,
          budgetTotal: budget,
          spent: spent,
          buckets: defaultBuckets,
          spentByBucket: spentByBucket,
          usualByBucket: usual,
          plannedByBucket: const {'need': 20000, 'want': 10000, 'invest': 10000},
        );

    test('the estimate follows the pace', () {
      // 10 days in, 10k spent in a 30-day month → 30k for the month.
      final i = insight(day: 10, days: 30, spent: 10000, budget: 30000);
      expect(i.projected, closeTo(30000, 1));
      expect(i.monthProgress, closeTo(1 / 3, 0.01));
    });

    test('spending faster than the days gone by is called out', () {
      final i = insight(day: 10, days: 30, spent: 20000, budget: 30000);
      expect(i.aheadOfPace, true);
      expect(i.lines.any((l) => l.contains('Ahead of pace')), true);
      expect(i.lines.any((l) => l.contains('ends around')), true);
    });

    test('a bucket more than your usual is called out', () {
      final i = insight(
        day: 30,
        days: 30,
        spent: 9000,
        budget: 30000,
        spentByBucket: const {'need': 9000},
        usual: const {'need': 4000},
      );
      expect(i.lines.any((l) => l.contains('more than your usual')), true);
    });

    test('a bucket under your usual is called out too', () {
      final i = insight(
        day: 30,
        days: 30,
        spent: 1000,
        budget: 30000,
        spentByBucket: const {'need': 1000},
        usual: const {'need': 4000},
      );
      expect(i.lines.any((l) => l.contains('less than your usual')), true);
    });

    test('a comfortable month says so instead of inventing a problem', () {
      final i = insight(day: 25, days: 30, spent: 5000, budget: 30000);
      expect(i.aheadOfPace, false);
      expect(i.lines.any((l) => l.contains('Comfortably under')), true);
    });

    test('over the plan for a bucket is called out', () {
      final i = insight(
        day: 30,
        days: 30,
        spent: 25000,
        budget: 30000,
        spentByBucket: const {'need': 25000},
      );
      expect(i.lines.any((l) => l.contains('need: over by')), true);
    });
  });

  group('group money insights (#15)', () {
    final members = [
      GroupMember(id: '1', groupId: 'g', name: 'Me', createdAt: DateTime(2026, 9, 1)),
      GroupMember(id: '2', groupId: 'g', name: 'Ravi', createdAt: DateTime(2026, 9, 1)),
      GroupMember(id: '3', groupId: 'g', name: 'Asha', createdAt: DateTime(2026, 9, 1)),
    ];
    final expenses = [
      GroupExpense(
        id: 'e1',
        groupId: 'g',
        title: 'Groceries',
        amount: 1500,
        paidBy: 'Ravi',
        sharedWithJson: '[]',
        occurredAt: DateTime(2026, 9, 2),
      ),
      GroupExpense(
        id: 'e2',
        groupId: 'g',
        title: 'Pizza',
        amount: 600,
        paidBy: 'Me',
        sharedWithJson: '[]',
        occurredAt: DateTime(2026, 9, 3),
      ),
      GroupExpense(
        id: 'e3',
        groupId: 'g',
        title: 'Groceries',
        amount: 300,
        paidBy: 'Me',
        sharedWithJson: '[]',
        occurredAt: DateTime(2026, 9, 4),
      ),
    ];

    test('total, per person, per what and the biggest item', () {
      final report = buildGroupInsight(
        name: 'Flat',
        code: 'ET-ABCD',
        monthKey: '2026-09',
        members: members,
        expenses: expenses,
        payments: const [],
      );
      expect(report.totalSpent, 2400);
      expect(report.expenseCount, 3);
      expect(report.perPerson.first.label, 'Ravi');
      expect(report.perPerson.first.amount, 1500);
      expect(report.perPerson[1].label, 'Me');
      expect(report.perPerson[1].amount, 900);
      expect(report.perTitle.first.label, 'Groceries');
      expect(report.perTitle.first.amount, 1800);
      expect(report.perTitle.first.count, 2);
      // The biggest *single* expense, not the biggest total.
      expect(report.largest!.label, 'Groceries');
      expect(report.largest!.amount, 1500);
      expect(report.lines.any((l) => l.contains('₹2,400')), true);
    });

    test('balances add up and the settle-up is the minimum set', () {
      final report = buildGroupInsight(
        name: 'Flat',
        code: 'ET-ABCD',
        monthKey: '2026-09',
        members: members,
        expenses: expenses,
        payments: const [],
      );
      expect(report.balances.fold<double>(0, (s, b) => s + b.net), closeTo(0, 0.05));
      expect(report.settleUp, isNotEmpty);
      // The bill was 2400, so 800 each. Ravi fronted 1500 (owed 700) and Me
      // fronted 900 (owed 100); Asha owes 800 and settles it in two transfers.
      expect(report.balances.firstWhere((b) => b.name == 'Ravi').net, closeTo(700, 0.05));
      expect(report.balances.firstWhere((b) => b.name == 'Me').net, closeTo(100, 0.05));
      expect(report.balances.firstWhere((b) => b.name == 'Asha').net, closeTo(-800, 0.05));
      expect(report.settleUp.length, 2);
      expect(report.settleUp.map((m) => m.to).toSet(), {'Ravi', 'Me'});
    });

    test('a pay-up cancels what was owed', () {
      final report = buildGroupInsight(
        name: 'Flat',
        code: 'ET-ABCD',
        monthKey: '2026-09',
        members: members,
        expenses: expenses,
        payments: [
          GroupPayment(
            id: 'p1',
            groupId: 'g',
            paidBy: 'Me',
            paidTo: 'Ravi',
            amount: 1000,
            occurredAt: DateTime(2026, 9, 5),
          ),
        ],
      );
      // Me was owed 100; paying 1000 back leaves 1100 owed to Me, and Ravi
      // is 300 out of pocket.
      expect(report.balances.firstWhere((b) => b.name == 'Me').net, closeTo(1100, 0.05));
      expect(report.balances.firstWhere((b) => b.name == 'Ravi').net, closeTo(-300, 0.05));
    });

    test('a payer outside the share list is owed the whole amount', () {
      final report = buildGroupInsight(
        name: 'Lend',
        code: 'ET-LEND',
        monthKey: '2026-09',
        members: members,
        expenses: [
          GroupExpense(
            id: 'e9',
            groupId: 'g',
            title: 'Ravi ticket',
            amount: 500,
            paidBy: 'Me',
            sharedWithJson: '["Ravi"]',
            occurredAt: DateTime(2026, 9, 8),
          ),
        ],
        payments: const [],
      );
      expect(report.balances.firstWhere((b) => b.name == 'Me').net, closeTo(500, 0.05));
      expect(report.balances.firstWhere((b) => b.name == 'Ravi').net, closeTo(-500, 0.05));
      expect(report.balances.firstWhere((b) => b.name == 'Asha').net, closeTo(0, 0.05));
      expect(report.settleUp.single.from, 'Ravi');
      expect(report.settleUp.single.to, 'Me');
    });

    test('the CSV report carries every section', () {
      final report = buildGroupInsight(
        name: 'Flat',
        code: 'ET-ABCD',
        monthKey: '2026-09',
        members: members,
        expenses: expenses,
        payments: const [],
      );
      final csv = renderGroupCsv(report);
      expect(csv, contains('GROUP'));
      expect(csv, contains('WHO SPENT WHAT'));
      expect(csv, contains('SPENT ON'));
      expect(csv, contains('BALANCES'));
      expect(csv, contains('SETTLE UP'));
      expect(csv, contains('Groceries'));
      expect(csv, contains('Ravi'));
    });
  });
}
