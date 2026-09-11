/// Price memory screen: pick any item ever typed, see avg/min/max plus an
/// overpay flag when the latest sighting costs more than the average.
/// Reads past transactions, writes nothing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import 'price_logic.dart';

final _dayFmt = DateFormat('d MMM yyyy');

class PriceScreen extends ConsumerStatefulWidget {
  const PriceScreen({super.key});

  @override
  ConsumerState<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends ConsumerState<PriceScreen> {
  String? _item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(allItemsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Price memory')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          items.when(
            data: (list) {
              if (list.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No priced items yet — entries with hyphenated items (e.g. gobi-65) appear here.'),
                  ),
                );
              }
              final sel = _item != null && list.contains(_item) ? _item : null;
              return DropdownButtonFormField<String>(
                value: sel,
                hint: const Text('Pick an item'),
                items: [for (final i in list) DropdownMenuItem(value: i, child: Text(i))],
                onChanged: (v) => setState(() => _item = v),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Items unavailable: $e'),
          ),
          const SizedBox(height: 8),
          if (_item != null)
            ref.watch(itemRowsProvider(_item!)).when(
                  data: (rows) {
                    final spends = rows.where((t) => t.actual < 0).toList();
                    final stats = priceStats(pricesOf([for (final t in spends) t.actual]));
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_item!, style: Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                if (stats.count < 2)
                                  const Text('Only one sighting — buy once more to unlock average + overpay alerts.')
                                else ...[
                                  Text(
                                    'Avg ₹${stats.avg.toStringAsFixed(0)} · min ₹${stats.min.toStringAsFixed(0)} · max ₹${stats.max.toStringAsFixed(0)} · latest ₹${stats.latest.toStringAsFixed(0)} (${stats.count}×)',
                                  ),
                                  if (stats.overpay)
                                    const Text(
                                      'Overpay alert: latest costs more than your average.',
                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                    )
                                  else
                                    const Text(
                                      'Latest is at or below average — fair price.',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final t in spends)
                          ListTile(
                            dense: true,
                            title: Text(t.categoryRaw),
                            subtitle: Text(_dayFmt.format(t.occurredAt)),
                            trailing: Text('₹${(-t.actual).toStringAsFixed(0)}'),
                          ),
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('History unavailable: $e'),
                ),
        ],
      ),
    );
  }
}
