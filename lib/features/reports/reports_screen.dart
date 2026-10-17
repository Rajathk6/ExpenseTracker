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
import '../../core/report/month_report.dart';
import '../../core/report/report_writer.dart';

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
  late final Set<String> _exportMonths = {monthKey(_month)};

  /// Writes the selected months as CSV / Excel / PDF into Downloads and says
  /// exactly where (#5 + #18). Reports are offline files, never uploads.
  Future<void> _export(ReportFormat format) async {
    final messenger = ScaffoldMessenger.of(context);
    final months = _exportMonths.toList()..sort();
    messenger.showSnackBar(const SnackBar(content: Text('Building the file…')));
    try {
      final path = await writeReport(
        months: await MonthReportBuilder(ref.read(databaseProvider)).build(months),
        format: format,
      );
      messenger.showSnackBar(SnackBar(content: Text('Saved to $path')));
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not write the file: $e')));
    }
  }

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
          _ExportCard(
            months: _exportMonths,
            currentMonth: key,
            onToggle: (m) => setState(() {
              if (!_exportMonths.remove(m) && _exportMonths.isNotEmpty) _exportMonths.add(m);
            }),
            onExport: _export,
          ),
          const SizedBox(height: 8),
          data.when(
            data: (d) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TrendCard(
                  trendKeys: [for (final t in d.trend) t.key],
                  trendOut: [for (final t in d.trend) t.outBudget],
                  trendIn: [for (final t in d.trend) t.inBudget],
                ),
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

/// Axis money labels: ₹1.2L instead of a wall of digits (#17).
String _compact(double value) {
  final v = value.abs();
  if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
  if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
  return '₹${v.round()}';
}

/// One coloured dot + label, the legend every chart carries.
class _Legend extends StatelessWidget {
  final List<({String label, Color colour, bool dashed})> items;
  const _Legend(this.items);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        for (final i in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: i.dashed ? null : i.colour,
                  border: i.dashed ? Border.all(color: i.colour, width: 2) : null,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 5),
              Text(i.label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}

/// Download this month's detail — or several months — as CSV, a real .xlsx or
/// a printable PDF. Files land in Downloads/ExpenseTracker and the path is
/// shown, so "where did it save?" never comes up again (#5, #18, #21).
class _ExportCard extends ConsumerWidget {
  final Set<String> months;
  final String currentMonth;
  final void Function(String month) onToggle;
  final void Function(ReportFormat format) onExport;

  const _ExportCard({
    required this.months,
    required this.currentMonth,
    required this.onToggle,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Download report', style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            const Text('Every entry, plus your lends, borrows, settlements and splits.'),
            const SizedBox(height: 8),
            FutureBuilder<List<String>>(
              future: ref.watch(monthsWithActivityProvider.future),
              builder: (context, snap) {
                final available = snap.data ?? const <String>[];
                return Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final m in [currentMonth, ...available.where((m) => m != currentMonth).take(11)])
                      FilterChip(
                        label: Text(m),
                        selected: months.contains(m),
                        onSelected: (_) => onToggle(m),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final f in ReportFormat.values)
                  OutlinedButton.icon(
                    onPressed: () => onExport(f),
                    icon: Icon(
                      switch (f) {
                        ReportFormat.csv => Icons.table_rows_outlined,
                        ReportFormat.xlsx => Icons.grid_on_outlined,
                        ReportFormat.pdf => Icons.picture_as_pdf_outlined,
                      },
                    ),
                    label: Text(f.label),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              months.length == 1
                  ? 'One month selected · saved into Downloads/ExpenseTracker'
                  : '${months.length} months selected · one page per month',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatefulWidget {
  final List<String> trendKeys;
  final List<double> trendOut;
  final List<double> trendIn;
  const _TrendCard({required this.trendKeys, required this.trendOut, required this.trendIn});

  @override
  State<_TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<_TrendCard> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final outSpots = [for (var i = 0; i < widget.trendOut.length; i++) FlSpot(i.toDouble(), widget.trendOut[i])];
    final inSpots = [for (var i = 0; i < widget.trendIn.length; i++) FlSpot(i.toDouble(), widget.trendIn[i])];
    final labels = [for (final k in widget.trendKeys) _shortMonth(k)];
    final touched = _touched;
    final maxValue = [
      ...widget.trendOut,
      ...widget.trendIn,
    ].fold<double>(0, (a, b) => a > b ? a : b);
    final interval = _niceInterval(maxValue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Money in vs out', style: Theme.of(context).textTheme.titleSmall),
                Text('last ${widget.trendKeys.length} months', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            _Legend([
              (label: 'In', colour: Colors.green.shade600, dashed: false),
              (label: 'Out', colour: Colors.red.shade400, dashed: false),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxValue <= 0 ? 100 : maxValue * 1.15,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) => const FlLine(color: Colors.black12, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: _chartTitles(context, bottomLabels: labels, interval: interval),
                  extraLinesData: touched == null
                      ? const ExtraLinesData()
                      : ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: widget.trendOut[touched],
                              color: Colors.orange.shade700,
                              strokeWidth: 1,
                              dashArray: const [4, 4],
                            ),
                          ],
                        ),
                  lineTouchData: LineTouchData(
                    touchCallback: (event, response) {
                      if (event is FlTapUpEvent || event is FlLongPressEnd) {
                        setState(() => _touched = response?.lineBarSpots?.first.spotIndex);
                      }
                    },
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: inSpots,
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.green.shade600,
                      dotData: FlDotData(
                        show: true,
                        checkToShowDot: (spot, bar) => spot.x == touched?.toDouble(),
                      ),
                      belowBarData: BarAreaData(show: true, color: Colors.green.withValues(alpha: 0.10)),
                    ),
                    LineChartBarData(
                      spots: outSpots,
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.red.shade400,
                      dotData: FlDotData(
                        show: true,
                        checkToShowDot: (spot, bar) => spot.x == touched?.toDouble(),
                      ),
                      belowBarData: BarAreaData(show: true, color: Colors.red.withValues(alpha: 0.10)),
                    ),
                  ],
                ),
              ),
            ),
            if (touched != null)
              Text(
                '${_monthName(widget.trendKeys[touched])} · in ₹${widget.trendIn[touched].toStringAsFixed(0)} · out ₹${widget.trendOut[touched].toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

/// Axis titles + gridlines, built with the chart's own context so the labels
/// use the app's text styles.
FlTitlesData _chartTitles(BuildContext context, {required List<String> bottomLabels, required double interval}) =>
    FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          interval: interval,
          getTitlesWidget: (value, meta) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(_compact(value), style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.round();
            if (index < 0 || index >= bottomLabels.length) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(bottomLabels[index], style: Theme.of(context).textTheme.bodySmall),
            );
          },
        ),
      ),
    );

/// A round interval for the axis, so gridlines land on readable numbers.
double _niceInterval(double maxValue) {
  if (maxValue <= 0) return 1;
  final magnitude = _pow10(maxValue);
  for (final step in [1.0, 2.0, 5.0, 10.0]) {
    if (maxValue / (magnitude * step) <= 6) return magnitude * step;
  }
  return magnitude * 10;
}

double _pow10(double value) {
  var m = 1.0;
  while (m * 10 <= value) {
    m *= 10;
  }
  return m;
}

String _monthName(String key) {
  final parts = key.split('-');
  return DateFormat('MMMM yyyy').format(DateTime(int.parse(parts[0]), int.parse(parts[1])));
}

class _CategoriesCard extends StatefulWidget {
  final String month;
  final List<({String label, double out})> slices;
  final List<Transaction> monthTxns;
  final void Function(String title, List<Transaction> txns) onDrill;
  const _CategoriesCard({required this.month, required this.slices, required this.monthTxns, required this.onDrill});

  @override
  State<_CategoriesCard> createState() => _CategoriesCardState();
}

class _CategoriesCardState extends State<_CategoriesCard> {
  int? _touched;

  List<Transaction> _forSlice(String label) {
    final monthTxns = widget.monthTxns;
    final slices = widget.slices;
    if (label == 'other') {
      final shown = {for (final s in slices) s.label};
      return monthTxns
          .where((t) => t.budgetImpact < 0 && !shown.contains((t.level0 ?? 'other').trim().toLowerCase()))
          .toList();
    }
    return monthTxns
        .where((t) => t.budgetImpact < 0 && (t.level0 ?? 'other').trim().toLowerCase() == label)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final slices = widget.slices;
    if (slices.isEmpty) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(12), child: Text('No spend this month — nothing to chart.')),
      );
    }
    final maxOut = slices.map((s) => s.out).reduce((a, b) => a > b ? a : b);
    const palette = _palette;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spend by category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              'tap a bar or a row to see the entries behind it',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 170,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxOut <= 0 ? 1 : maxOut * 1.15,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _niceInterval(maxOut),
                    getDrawingHorizontalLine: (_) => const FlLine(color: Colors.black12, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: _chartTitles(
                    context,
                    bottomLabels: [for (final s in slices) s.label],
                    interval: _niceInterval(maxOut),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchCallback: (event, response) {
                      if (event is FlTapUpEvent) {
                        final idx = response?.spot?.touchedBarGroupIndex;
                        if (idx != null && idx >= 0 && idx < slices.length) {
                          widget.onDrill('${slices[idx].label} · ${widget.month}', _forSlice(slices[idx].label));
                        }
                      } else if (event is FlLongPressEnd || event is FlPanEndEvent) {
                        setState(() => _touched = null);
                      } else if (event is FlTapDownEvent || event is FlLongPressStart) {
                        setState(() => _touched = response?.spot?.touchedBarGroupIndex);
                      }
                    },
                  ),
                  barGroups: [
                    for (var i = 0; i < slices.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: slices[i].out,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            color: palette[i % palette.length],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (_touched != null && _touched! < slices.length)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${slices[_touched!].label} · ₹${slices[_touched!].out.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            _Legend([
              for (var i = 0; i < slices.length; i++)
                (label: slices[i].label, colour: palette[i % palette.length], dashed: false),
            ]),
            const SizedBox(height: 4),
            for (final s in slices)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(s.label),
                trailing: Text('₹${s.out.toStringAsFixed(0)}'),
                onTap: () => widget.onDrill('${s.label} · ${widget.month}', _forSlice(s.label)),
              ),
          ],
        ),
      ),
    );
  }
}

/// One shared palette, so the same category is the same colour everywhere.
const _palette = [
  Colors.teal,
  Colors.indigo,
  Color(0xFFFFA000),
  Colors.deepOrange,
  Colors.purple,
  Colors.blueGrey,
  Colors.pink,
  Color(0xFF9CCC65),
];

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
            const SizedBox(height: 6),
            const _Legend([
              (label: 'Cash', colour: Colors.teal, dashed: false),
              (label: 'Digital', colour: Colors.indigo, dashed: false),
            ]),
            if (total > 0) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (cashOut / total).clamp(0.0, 1.0),
                  minHeight: 8,
                  color: Colors.teal,
                  backgroundColor: Colors.indigo.withValues(alpha: 0.35),
                ),
              ),
            ],
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
