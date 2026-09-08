/// Search + detail: matches raw category, any level, or item
/// (`food`, `junk`, `gobi-65` all find `food junk gobi-65`).
/// Exact hyphenated items additionally offer a stats drill-down. Read-only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../core/providers.dart';

final _dayFmt = DateFormat('d MMM yyyy');
final _monthFmt = DateFormat('MMM yyyy');

class ItemSearchScreen extends ConsumerStatefulWidget {
  const ItemSearchScreen({super.key});

  @override
  ConsumerState<ItemSearchScreen> createState() => _ItemSearchScreenState();
}

class _ItemSearchScreenState extends ConsumerState<ItemSearchScreen> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(allItemsProvider);
    final q = _q.text.trim();
    final results = ref.watch(searchProvider(q));
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _q,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Category, level or item (e.g. food, junk, gobi-65)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (q.isEmpty)
            Expanded(
              child: items.when(
                data: (all) {
                  if (all.isEmpty) {
                    return const Center(child: Text('No entries yet — tap Add on the home screen.'));
                  }
                  return ListView(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Text('Browse items — tap for stats'),
                      ),
                      for (final item in all)
                        ListTile(
                          leading: const Icon(Icons.fastfood),
                          title: Text(item),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Could not load: $e')),
              ),
            )
          else
            Expanded(
              child: results.when(
                data: (rows) {
                  if (rows.isEmpty) {
                    return Center(child: Text('No matches for "$q".'));
                  }
                  final spent = rows.where((r) => r.actual < 0).fold<double>(0, (s, r) => s + r.actual);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Text(
                          '${rows.length} entr${rows.length == 1 ? 'y' : 'ies'} · total ₹${spent.abs().toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (_, i) => ListTile(
                            leading: Icon(
                              rows[i].actual < 0 ? Icons.arrow_upward : Icons.arrow_downward,
                              color: rows[i].actual < 0 ? Colors.red : Colors.green,
                            ),
                            title: Text(rows[i].categoryRaw),
                            subtitle: Text(_dayFmt.format(rows[i].occurredAt)),
                            trailing: Text('₹${rows[i].actual.toStringAsFixed(0)}'),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Could not load: $e')),
              ),
            ),
        ],
      ),
    );
  }
}

class ItemDetailScreen extends ConsumerWidget {
  final String item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(itemRowsProvider(item));
    return Scaffold(
      appBar: AppBar(title: Text(item)),
      body: rows.when(
        data: (list) => _DetailBody(item: item, rows: list),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final String item;
  final List<Transaction> rows;
  const _DetailBody({required this.item, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Center(child: Text('Never bought.'));
    final spent = rows.where((r) => r.actual < 0).fold<double>(0, (s, r) => s + r.actual);
    final avg = spent / rows.length;
    final byMonth = <String, List<Transaction>>{};
    for (final r in rows) {
      byMonth.putIfAbsent(_monthFmt.format(r.occurredAt), () => []).add(r);
    }
    final months = byMonth.keys.toList()..sort();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat('Times', '${rows.length}'),
                _Stat('Total', '₹${spent.abs().toStringAsFixed(0)}'),
                _Stat('Avg', '₹${avg.abs().toStringAsFixed(0)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('By month', style: Theme.of(context).textTheme.titleSmall),
        for (final m in months)
          ListTile(
            dense: true,
            title: Text(m),
            trailing: Text(
              '×${byMonth[m]!.length} · ₹${byMonth[m]!.fold<double>(0, (s, r) => s + r.actual).abs().toStringAsFixed(0)}',
            ),
          ),
        const Divider(),
        for (final r in rows)
          ListTile(
            dense: true,
            title: Text(r.categoryRaw),
            subtitle: Text(_dayFmt.format(r.occurredAt)),
            trailing: Text('₹${r.actual.toStringAsFixed(0)}'),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
