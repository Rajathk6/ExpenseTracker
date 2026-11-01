/// Interactive analytics for one group: category mix, daily spend, who
/// fronted the money, settlement progress and the biggest entries.
///
/// Everything is built from [GroupInsightReport], the same model the group
/// report exports, so the dashboard and the files always agree.
library;

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../core/providers.dart';
import 'group_insight.dart';
import 'group_report.dart';

final groupAnalyticsProvider = FutureProvider.family<GroupInsightReport?, String>((ref, groupId) async {
  // Balances are invalidated by local edits and by sync, so analytics refresh
  // with the rest of the group screen instead of showing a stale snapshot.
  ref.watch(groupBalancesProvider(groupId));
  final repo = ref.watch(groupRepositoryProvider);
  final group = (await repo.all()).where((g) => g.id == groupId).firstOrNull;
  if (group == null) return null;
  return buildGroupReport(repo, group);
});

final _day = DateFormat('d MMM');

class GroupAnalyticsScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupAnalyticsScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupAnalyticsScreen> createState() => _GroupAnalyticsScreenState();
}

class _GroupAnalyticsScreenState extends ConsumerState<GroupAnalyticsScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(groupAnalyticsProvider(widget.groupId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          report.maybeWhen(
            data: (r) => r == null ? 'Group analytics' : '${r.name} · analytics',
            orElse: () => 'Group analytics',
          ),
        ),
      ),
      body: report.when(
        data: (r) => r == null
            ? const Center(child: Text('This group is gone.'))
            : _Dashboard(
                report: r,
                selectedCategory: _category,
                onCategory: (category) => setState(() => _category = category),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load analytics: $e')),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final GroupInsightReport report;
  final String? selectedCategory;
  final ValueChanged<String?> onCategory;

  const _Dashboard({
    required this.report,
    required this.selectedCategory,
    required this.onCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = selectedCategory == null
        ? report.expenses
        : [
            for (final e in report.expenses)
              if (categoryOf(e) == selectedCategory) e,
          ];
    final daily = _dailyFor(expenses);
    final visibleTotal = selectedCategory == null
        ? report.totalSpent
        : expenses.fold<double>(0, (sum, e) => sum + e.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatCard(
              label: selectedCategory == null ? 'Total spent' : selectedCategory!,
              value: '₹${visibleTotal.round()}',
              icon: Icons.account_balance_wallet_outlined,
            ),
            _StatCard(
              label: 'Entries',
              value: '${expenses.length}',
              icon: Icons.receipt_long_outlined,
            ),
            _StatCard(
              label: 'Average entry',
              value: '₹${(expenses.isEmpty ? 0 : visibleTotal / expenses.length).round()}',
              icon: Icons.trending_up,
            ),
            _StatCard(
              label: 'Settled',
              value: '₹${report.settledAmount.round()}',
              icon: Icons.handshake_outlined,
            ),
          ],
        ),
        if (selectedCategory != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.filter_alt_off_outlined, size: 16),
                label: Text('Clear $selectedCategory filter'),
                onPressed: () => onCategory(null),
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (report.expenses.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No spending yet', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Add an expense from the group screen and the category, daily and '
                    'performance charts fill in here.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          )
        else ...[
          _CategoryCard(
            report: report,
            selected: selectedCategory,
            onSelected: onCategory,
          ),
          const SizedBox(height: 12),
          _DailyCard(days: daily),
          const SizedBox(height: 12),
          _PerformanceCard(report: report),
          const SizedBox(height: 12),
          _TopExpensesCard(
            expenses: expenses,
            category: selectedCategory,
            onClear: () => onCategory(null),
          ),
        ],
        const SizedBox(height: 12),
        _SettlementCard(report: report),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 150,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                    Text(value, style: theme.textTheme.titleSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final GroupInsightReport report;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CategoryCard({required this.report, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = report.perCategory;
    if (categories.isEmpty) return const SizedBox.shrink();
    final total = report.totalSpent <= 0 ? 1 : report.totalSpent;
    final palette = _palette(categories.length);
    final selectedIndex = selected == null ? -1 : categories.indexWhere((c) => c.label == selected);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Where the money went', style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text('Tap a slice or a category to filter the dashboard.', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 190,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 38,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions) return;
                      final index = response?.touchedSection?.touchedSectionIndex;
                      if (index == null || index < 0 || index >= categories.length) return;
                      onSelected(selected == categories[index].label ? null : categories[index].label);
                    },
                  ),
                  sections: [
                    for (var i = 0; i < categories.length; i++)
                      PieChartSectionData(
                        value: categories[i].amount,
                        color: palette[i],
                        radius: i == selectedIndex ? 58 : 48,
                        title: '${(categories[i].amount / total * 100).toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < categories.length; i++)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelected(selected == categories[i].label ? null : categories[i].label),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: palette[i], shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          categories[i].label,
                          style: TextStyle(
                            fontWeight: selected == categories[i].label ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Text(
                        '₹${categories[i].amount.round()} · ${(categories[i].amount / total * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  final List<GroupDay> days;
  const _DailyCard({required this.days});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (days.isEmpty) return const SizedBox.shrink();
    final maxAmount = days.fold<double>(0, (max, d) => math.max(max, d.amount));
    final maxY = maxAmount <= 0 ? 1.0 : maxAmount * 1.2;
    final step = math.max(1, (days.length / 6).ceil());
    final interval = _niceInterval(maxY);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spending by day', style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text('Tap a bar to see the amount.', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) => const FlLine(color: Colors.black12, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: interval,
                        getTitlesWidget: (value, meta) => Text(_compact(value), style: theme.textTheme.bodySmall),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= days.length || index % step != 0) return const SizedBox.shrink();
                          return Text('${days[index].date.day}', style: theme.textTheme.bodySmall);
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem('₹${rod.toY.round()}', const TextStyle(color: Colors.white)),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < days.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: days[i].amount,
                            width: 8,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final GroupInsightReport report;
  const _PerformanceCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topCategory = report.perCategory.isEmpty ? null : report.perCategory.first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _Metric(
              label: 'How evenly the cost was shared',
              value: '${(report.evenness * 100).round()}%',
              progress: report.evenness,
              colour: Colors.green,
            ),
            _Metric(
              label: 'How much has been settled',
              value: '${(report.settlementShare * 100).round()}% · ₹${report.settledAmount.round()}',
              progress: report.settlementShare,
              colour: Colors.blue,
            ),
            if (topCategory != null)
              _Metric(
                label: 'Top category',
                value: '${topCategory.label} · ₹${topCategory.amount.round()}',
                progress: report.totalSpent <= 0 ? 0 : topCategory.amount / report.totalSpent,
                colour: Colors.orange,
              ),
            const Divider(height: 18),
            Row(
              children: [
                Expanded(child: _Mini(label: 'Largest entry', value: report.largest == null ? '—' : '₹${report.largest!.amount.round()}')),
                Expanded(child: _Mini(label: 'Settlements', value: '${report.settlementCount}')),
                Expanded(child: _Mini(label: 'Per person', value: '₹${report.peopleCount == 0 ? 0 : (report.totalSpent / report.peopleCount).round()}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color colour;

  const _Metric({
    required this.label,
    required this.value,
    required this.progress,
    required this.colour,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
              Text(value, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(colour),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  const _Mini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    );
  }
}

class _TopExpensesCard extends StatelessWidget {
  final List<GroupExpense> expenses;
  final String? category;
  final VoidCallback onClear;

  const _TopExpensesCard({required this.expenses, required this.category, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = expenses.take(8).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Top expenses', style: theme.textTheme.titleSmall)),
                if (category != null)
                  TextButton(onPressed: onClear, child: const Text('Show all')),
              ],
            ),
            if (rows.isEmpty)
              const Text('No entries match this category.')
            else
              for (final e in rows)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.title),
                  subtitle: Text(
                    '${_day.format(e.occurredAt)} · ${categoryOf(e)}'
                    '${e.paidBy.isEmpty ? '' : ' · paid by ${e.paidBy}'}',
                  ),
                  trailing: Text('₹${e.amount.round()}'),
                ),
          ],
        ),
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final GroupInsightReport report;
  const _SettlementCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settlements', style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              'Recorded separately from expenses · ${report.settlementCount} '
              '${report.settlementCount == 1 ? 'payment' : 'payments'}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            if (report.settleUp.isNotEmpty) ...[
              Text('Still to settle', style: theme.textTheme.bodySmall),
              for (final move in report.settleUp)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('${move.from} pays ${move.to} ₹${move.amount.round()}'),
                ),
              const SizedBox(height: 6),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('Everyone is settled up.', style: theme.textTheme.bodySmall),
              ),
            if (report.payments.isEmpty)
              const Text('No settlements recorded yet.')
            else
              for (final p in report.payments.take(6))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.handshake_outlined, size: 20),
                  title: Text('${p.paidBy} → ${p.paidTo}'),
                  subtitle: Text(_day.format(p.occurredAt)),
                  trailing: Text('₹${p.amount.round()}'),
                ),
          ],
        ),
      ),
    );
  }
}

List<GroupDay> _dailyFor(List<GroupExpense> expenses) {
  final byDay = <String, ({double amount, int count})>{};
  for (final e in expenses) {
    final key = '${e.occurredAt.year.toString().padLeft(4, '0')}-'
        '${e.occurredAt.month.toString().padLeft(2, '0')}-'
        '${e.occurredAt.day.toString().padLeft(2, '0')}';
    final current = byDay[key];
    byDay[key] = (amount: (current?.amount ?? 0) + e.amount, count: (current?.count ?? 0) + 1);
  }
  final out = [
    for (final entry in byDay.entries)
      GroupDay(DateTime.parse(entry.key), entry.value.amount, entry.value.count),
  ]..sort((a, b) => a.date.compareTo(b.date));
  return out;
}

List<Color> _palette(int count) {
  const colours = [
    Color(0xFF3F51B5),
    Color(0xFF009688),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFF795548),
    Color(0xFF607D8B),
  ];
  return [for (var i = 0; i < count; i++) colours[i % colours.length]];
}

double _niceInterval(double max) {
  if (max <= 0) return 1;
  final rough = max / 4;
  final magnitude = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  final normalised = rough / magnitude;
  final step = normalised <= 1 ? 1 : (normalised <= 2 ? 2 : (normalised <= 5 ? 5 : 10));
  return step * magnitude;
}

String _compact(double value) {
  if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  return value.round().toString();
}
