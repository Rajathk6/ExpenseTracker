/// Item search + detail: type `gobi-65`, see count / total / average /
/// monthly breakdown and every matching entry. Read-only.
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
    return Scaffold(
      appBar: AppBar(title: const Text('Search items')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _q,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Item (e.g. gobi-65)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: items.when(
              data: (all) {
                final q = _q.text.trim().toLowerCase();
                final hits = all.where((i) => q.isEmpty || i.toLowerCase().contains(q)).toList();
                if (hits.isEmpty) return const Center(child: Text('No matches yet.'));
                return ListView.builder(
                  itemCount: hits.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.fastfood),
                    title: Text(hits[i]),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ItemDetailScreen(item: hits[i])),
                    ),
                  ),
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
