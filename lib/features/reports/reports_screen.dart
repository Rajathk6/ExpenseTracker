/// Reports dashboard: per-module graphs with tap-to-drill txn lists.
/// Read-only — every figure derives from the ledger at watch time.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../core/months.dart';
import '../../core/providers.dart';

final _dayFmt = DateFormat('d MMM yyyy');

const _shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _shortMonth(String key) {
  final m = int.parse(key.split('-')[1]);
  return _shortMonths[m - 1];
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _drill(String title, List<Transaction> txns) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _DrillScreen(title: title, txns: txns)));
  }

  @override
  Widget build(BuildContext context) {
    final key = monthKey(_month);
    final data = ref.watch(dashboardProvider(key));
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _month = monthStart(shiftMonthKey(key, -1))),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(key, style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                onPressed: () => setState(() => _month = monthStart(shiftMonthKey(key, 1))),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          data.when(
            data: (d) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TrendCard(trendKeys: [for (final t in d.trend) t.key], trendOut: [for (final t in d.trend) t.outBudget]),
                const SizedBox(height: 8),
                _CategoriesCard(
                  month: d.month,
                  slices: d.categories,
                  monthTxns: d.monthTxns,
                  onDrill: _drill,
                ),
                const SizedBox(height: 8),
                _CashDigitalCard(
                  cashOut: d.cashOut,
                  digitalOut: d.digitalOut,
                  monthTxns: d.monthTxns,
                  kinds: d.accountKinds,
                  onDrill: _drill,
                ),
                const SizedBox(height: 8),
                _BudgetCard(budgetTotal: d.budgetTotal, outBudget: d.outBudget),
                const SizedBox(height: 8),
                _WrappedCard(
                  year: d.wrapped.year,
                  inActual: d.wrapped.inActual,
                  outBudget: d.wrapped.outBudget,
                  topCategory: d.wrapped.topCategory,
                  topItem: d.wrapped.topItem,
                  biggestMonth: d.wrapped.biggestMonth,
                  txnCount: d.wrapped.txnCount,
                ),
              ],
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Reports unavailable: $e'),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final List<String> trendKeys;
  final List<double> trendOut;
  const _TrendCard({required this.trendKeys, required this.trendOut});

  @override
  Widget build(BuildContext context) {
    final spots = [for (var i = 0; i < trendOut.length; i++) FlSpot(i.toDouble(), trendOut[i])];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spend trend (budget truth)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.teal,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              '${_shortMonth(trendKeys.first)} ₹${trendOut.first.toStringAsFixed(0)} · · · '
              '${_shortMonth(trendKeys.last)} ₹${trendOut.last.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesCard extends StatelessWidget {
  final String month;
  final List<({String label, double out})> slices;
  final List<Transaction> monthTxns;
  final void Function(String title, List<Transaction> txns) onDrill;
  const _CategoriesCard({required this.month, required this.slices, required this.monthTxns, required this.onDrill});

  List<Transaction> _forSlice(String label) {
    if (label == 'other') {
      final shown = {for (final s in slices) s.label};
      return monthTxns
          .where((t) => t.budgetImpact < 0 && !shown.contains((t.level0 ?? 'other').trim().toLowerCase()))
          .toList();
    }
    return monthTxns.where((t) => t.budgetImpact < 0 && (t.level0 ?? 'other').trim().toLowerCase() == label).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('No spend this month — nothing to chart.')));
    }
    final maxOut = slices.map((s) => s.out).reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spend by category — tap a bar or row to drill', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  maxY: maxOut <= 0 ? 1 : maxOut * 1.1,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) return;
                      final idx = response?.spot?.touchedBarGroupIndex;
                      if (idx == null || idx < 0 || idx >= slices.length) return;
                      onDrill('${slices[idx].label} · $month', _forSlice(slices[idx].label));
                    },
                  ),
                  barGroups: [
                    for (var i = 0; i < slices.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [BarChartRodData(toY: slices[i].out, width: 18, color: Colors.teal)],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            for (final s in slices)
              ListTile(
                dense: true,
                title: Text(s.label),
                trailing: Text('₹${s.out.toStringAsFixed(0)}'),
                onTap: () => onDrill('${s.label} · $month', _forSlice(s.label)),
              ),
          ],
        ),
      ),
    );
  }
}

class _CashDigitalCard extends StatelessWidget {
  final double cashOut;
  final double digitalOut;
  final List<Transaction> monthTxns;
  final Map<String, String> kinds;
  final void Function(String title, List<Transaction> txns) onDrill;
  const _CashDigitalCard({
    required this.cashOut,
    required this.digitalOut,
    required this.monthTxns,
    required this.kinds,
    required this.onDrill,
  });

  bool _isCash(Transaction t) => (kinds[t.accountId] ?? 'digital').toLowerCase().contains('cash');

  @override
  Widget build(BuildContext context) {
    final total = cashOut + digitalOut;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cash vs digital', style: Theme.of(context).textTheme.titleSmall),
            ListTile(
              dense: true,
              leading: const Icon(Icons.money_outlined),
              title: const Text('Cash'),
              trailing: Text('₹${cashOut.toStringAsFixed(0)}'),
              onTap: () => onDrill(
                'Cash spend',
                monthTxns.where((t) => t.budgetImpact < 0 && _isCash(t)).toList(),
              ),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.smartphone_outlined),
              title: const Text('Digital'),
              trailing: Text('₹${digitalOut.toStringAsFixed(0)}'),
              onTap: () => onDrill(
                'Digital spend',
                monthTxns.where((t) => t.budgetImpact < 0 && !_isCash(t)).toList(),
              ),
            ),
            if (total > 0)
              LinearProgressIndicator(value: (cashOut / total).clamp(0.0, 1.0)),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final double budgetTotal;
  final double outBudget;
  const _BudgetCard({required this.budgetTotal, required this.outBudget});

  @override
  Widget build(BuildContext context) {
    if (budgetTotal <= 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text('No budget set — spent ₹${outBudget.toStringAsFixed(0)} (budget truth). Set one from Transactions → Budgets.'),
        ),
      );
    }
    final ratio = (outBudget / budgetTotal).clamp(0.0, 1.0);
    final over = outBudget > budgetTotal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget vs actual', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Spent ₹${outBudget.toStringAsFixed(0)} of ₹${budgetTotal.toStringAsFixed(0)}${over ? ' — over budget' : ''}',
              style: TextStyle(color: over ? Colors.red : null, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: ratio),
          ],
        ),
      ),
    );
  }
}

class _WrappedCard extends StatelessWidget {
  final int year;
  final double inActual;
  final double outBudget;
  final String? topCategory;
  final String? topItem;
  final String? biggestMonth;
  final int txnCount;
  const _WrappedCard({
    required this.year,
    required this.inActual,
    required this.outBudget,
    required this.topCategory,
    required this.topItem,
    required this.biggestMonth,
    required this.txnCount,
  });

  @override
  Widget build(BuildContext context) {
    if (txnCount == 0) {
      return Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('No entries in $year yet — your wrapped story starts with the first entry.')));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$year, wrapped', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('$txnCount entries · in ₹${inActual.toStringAsFixed(0)} · out ₹${outBudget.toStringAsFixed(0)}'),
            if (topCategory != null) Text('Top category: $topCategory'),
            if (topItem != null) Text('Top item: $topItem'),
            if (biggestMonth != null) Text('Biggest month: $biggestMonth'),
          ],
        ),
      ),
    );
  }
}

/// Drill-down: the exact ledger rows behind any chart figure.
class _DrillScreen extends StatelessWidget {
  final String title;
  final List<Transaction> txns;
  const _DrillScreen({required this.title, required this.txns});

  @override
  Widget build(BuildContext context) {
    final rows = [...txns]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    var total = 0.0;
    for (final t in rows) {
      total += t.budgetImpact;
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: rows.isEmpty
          ? const Center(child: Text('No entries behind this figure.'))
          : ListView.builder(
              itemCount: rows.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${rows.length} entries · net ₹${total.toStringAsFixed(0)} (budget truth)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  );
                }
                final t = rows[i - 1];
                final isOut = t.actual < 0;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isOut ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isOut ? Colors.red : Colors.green,
                    size: 18,
                  ),
                  title: Text(t.categoryRaw),
                  subtitle: Text(_dayFmt.format(t.occurredAt)),
                  trailing: Text(
                    '₹${t.budgetImpact.toStringAsFixed(0)}',
                    style: TextStyle(color: t.budgetImpact < 0 ? Colors.red : Colors.green),
                  ),
                );
              },
            ),
    );
  }
}
