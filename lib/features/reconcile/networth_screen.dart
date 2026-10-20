/// Net worth, the honest way.
///
/// **What you hold − what you owe**:
///
/// ```text
/// assets      = cash in your accounts
///             + investments (FD, MF, stocks… at their marked value)
///             + money others owe you (lends not returned, split shares unpaid)
/// liabilities = money you owe others (borrowings not repaid)
/// net worth   = assets − liabilities
/// ```
///
/// The old version summed the ledger's movements and added investments, which
/// counted a lend's cash twice and ignored what the owner owed. This version
/// balances: a rupee is either held, owed to you, or owed by you.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class NetWorthScreen extends ConsumerWidget {
  const NetWorthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(netWorthProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Net worth')),
      body: data.when(
        data: (n) {
          if (n.points.isEmpty) return const Center(child: Text('No data yet.'));
          final spots = [
            for (var i = 0; i < n.points.length; i++)
              FlSpot(i.toDouble(), n.points[i].net),
          ];
          final first = n.points.first, last = n.points.last;
          final gain = last.net >= first.net;
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${last.net.toStringAsFixed(0)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: gain ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'what you hold minus what you owe · ${first.monthKey} → ${last.monthKey} · '
                        '${gain ? '+' : ''}₹${(last.net - first.net).toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => const FlLine(color: Colors.black12),
                            ),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                barWidth: 2,
                                color: Colors.teal,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(show: true, color: Colors.teal.withValues(alpha: 0.12)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        '${first.monthKey} · · · ${last.monthKey}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What you hold', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 6),
                      _Line('Cash in your accounts', n.cash),
                      _Line('Investments', n.investNow),
                      _Line('Owed to you (lends + splits)', n.owedToYou),
                      const Divider(),
                      _Line('What you owe (borrowings)', n.youOwe, negative: true),
                      const Divider(),
                      _Line('Net worth', n.net, bold: true),
                      const SizedBox(height: 8),
                      Text(
                        'Lends and borrows are not counted as spending: the cash that left for a lend '
                        'is balanced by what the other person owes you, and borrowed cash is balanced '
                        'by what you owe.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final double value;
  final bool negative;
  final bool bold;
  const _Line(this.label, this.value, {this.negative = false, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = negative
        ? theme.colorScheme.error
        : (value < 0 ? theme.colorScheme.error : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: bold ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            '${value < 0 ? '-' : ''}₹${value.abs().toStringAsFixed(0)}',
            style: (bold ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)?.copyWith(color: colour),
          ),
        ],
      ),
    );
  }
}
