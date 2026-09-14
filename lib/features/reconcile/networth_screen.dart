/// Net-worth timeline screen: month-end (banks + cash + investments,
/// gains included in current values) graph plus the current breakdown.
/// Borrowings, future settlements and lent receivables are NOT wealth and
/// stay out. Reads everything, writes nothing.
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
              FlSpot(i.toDouble(), n.points[i].value),
          ];
          final first = n.points.first, last = n.points.last;
          final gain = last.value >= first.value;
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
                        '₹${last.value.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: gain ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${first.key} → ${last.key} · ${gain ? '+' : ''}₹${(last.value - first.value).toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180,
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
                        '${first.key} · · · ${last.key}',
                        style: Theme.of(context).textTheme.bodySmall,
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
                      Text('Breakdown (current)', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text('Banks + cash ₹${n.bankNow.toStringAsFixed(0)}'),
                      Text('Investments ₹${n.investNow.toStringAsFixed(0)}'),
                      Text(
                        'Gains ${n.investGains >= 0 ? '+' : ''}₹${n.investGains.toStringAsFixed(0)} (inside investments)',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Borrowings, settlements due and money lent out are not counted — only what is actually yours.',
                        style: Theme.of(context).textTheme.bodySmall,
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
