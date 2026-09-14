/// Monthly budget screen: total + N fully-custom buckets, planned
/// allocation, actual-spend progress per bucket. A saved split carries
/// forward to future months until changed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import 'bucket_math.dart';

final _monthFmt = DateFormat('MMMM yyyy');

String _monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final key = _monthKey(_month);
    final saved = ref.watch(effectiveBudgetProvider(key));
    final summary = ref.watch(monthSummaryProvider(key));
    final spent = ref.watch(bucketSpendProvider(key));
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(_monthFmt.format(_month), style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          summary.when(
            data: (s) => _SpendProgress(spent: s.outBudget.abs(), monthKey: key),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Summary unavailable: $e'),
          ),
          const SizedBox(height: 8),
          saved.when(
            data: (b) => _BudgetForm(
              key: ValueKey('$key-${b?.total}-${b?.buckets.length}'),
              monthKey: key,
              initialTotal: b?.total,
              initialBuckets: b?.buckets,
              carriedFrom: (b != null && b.sourceMonth != key) ? b.sourceMonth : null,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Could not load budget: $e'),
          ),
          const SizedBox(height: 8),
          Text('Spent per bucket', style: Theme.of(context).textTheme.titleSmall),
          spent.when(
            data: (m) {
              final rows = m.entries.where((e) => e.key.isNotEmpty).toList()
                ..sort((a, b) => a.value.abs().compareTo(b.value.abs()));
              final unassigned = m[''] ?? 0;
              if (rows.isEmpty && unassigned == 0) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Nothing tagged yet — pick a bucket when you add entries.'),
                );
              }
              return Card(
                child: Column(
                  children: [
                    for (final e in rows.reversed)
                      ListTile(
                        dense: true,
                        title: Text(e.key),
                        trailing: Text('₹${e.value.abs().toStringAsFixed(0)}'),
                      ),
                    if (unassigned != 0)
                      ListTile(
                        dense: true,
                        title: const Text('Untagged'),
                        trailing: Text('₹${unassigned.abs().toStringAsFixed(0)}'),
                      ),
                  ],
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Breakdown unavailable: $e'),
          ),
        ],
      ),
    );
  }
}

/// Thin wrapper so the progress bar reads the saved budget itself.
class _SpendProgress extends ConsumerWidget {
  final double spent;
  final String monthKey;
  const _SpendProgress({required this.spent, required this.monthKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(effectiveBudgetProvider(monthKey)).maybeWhen(data: (b) => b, orElse: () => null);
    final plan = saved?.total ?? 0;
    final ratio = plan <= 0 ? 0.0 : (spent / plan).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spent ₹${spent.toStringAsFixed(0)}${plan > 0 ? ' of ₹${plan.toStringAsFixed(0)}' : ' (no budget set)'}'),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: plan > 0 ? ratio : null),
          ],
        ),
      ),
    );
  }
}

class _BucketRow {
  final TextEditingController name;
  final TextEditingController pct;
  _BucketRow({String name = '', double pct = 0})
      : name = TextEditingController(text: name),
        pct = TextEditingController(text: pct == 0 ? '' : pct.toStringAsFixed(pct.truncateToDouble() == pct ? 0 : 1));

  void dispose() {
    name.dispose();
    pct.dispose();
  }
}

class _BudgetForm extends ConsumerStatefulWidget {
  final String monthKey;
  final double? initialTotal;
  final List<Bucket>? initialBuckets;
  /// Set when the form was prefilled from an earlier month: the split holds
  /// until explicitly saved here.
  final String? carriedFrom;
  const _BudgetForm({super.key, required this.monthKey, required this.initialTotal, required this.initialBuckets, required this.carriedFrom});

  @override
  ConsumerState<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<_BudgetForm> {
  late final TextEditingController _total;
  late List<_BucketRow> _rows;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _total = TextEditingController(text: widget.initialTotal?.toStringAsFixed(0) ?? '');
    final init = widget.initialBuckets ?? bucketPresets['30/40/30']!;
    _rows = [for (final b in init) _BucketRow(name: b.name, pct: b.pct)];
  }

  @override
  void dispose() {
    _total.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  List<Bucket> _readBuckets() => [
        for (final r in _rows)
          Bucket(name: r.name.text.trim(), pct: double.tryParse(r.pct.text.trim()) ?? -1),
      ];

  Future<void> _save() async {
    final total = double.tryParse(_total.text.trim());
    if (total == null || total < 0) {
      setState(() => _error = 'Enter a valid budget total');
      return;
    }
    final buckets = _readBuckets();
    final err = validateBuckets(buckets);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref.read(budgetRepositoryProvider).save(month: widget.monthKey, total: total, buckets: buckets);
      ref
        ..invalidate(budgetProvider(widget.monthKey))
        ..invalidate(monthSummaryProvider(widget.monthKey));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Budget saved')));
    } on Object catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buckets = _readBuckets();
    final valid = validateBuckets(buckets) == null;
    final total = double.tryParse(_total.text.trim()) ?? 0;
    Map<String, double> alloc = const {};
    if (valid && total > 0) {
      try {
        alloc = allocate(total, buckets);
      } on ArgumentError {
        alloc = const {};
      }
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Plan for ${widget.monthKey}', style: Theme.of(context).textTheme.titleSmall),
            if (widget.carriedFrom != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Carried forward from ${widget.carriedFrom} — saving stores it explicitly for this month.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _total,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monthly total', prefixText: '₹ ', border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _rows.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _rows[i].name,
                        decoration: const InputDecoration(labelText: 'Bucket', border: OutlineInputBorder()),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _rows[i].pct,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: '%', border: OutlineInputBorder()),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _rows.length <= 1
                          ? null
                          : () => setState(() {
                                _rows.removeAt(i).dispose();
                              }),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _rows.add(_BucketRow())),
                  icon: const Icon(Icons.add),
                  label: const Text('Bucket'),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  hint: const Text('Preset'),
                  items: [
                    for (final k in bucketPresets.keys) DropdownMenuItem(value: k, child: Text(k)),
                  ],
                  onChanged: (k) {
                    if (k == null) return;
                    setState(() {
                      for (final r in _rows) {
                        r.dispose();
                      }
                      _rows = [for (final b in bucketPresets[k]!) _BucketRow(name: b.name, pct: b.pct)];
                    });
                  },
                ),
              ],
            ),
            if (alloc.isNotEmpty)
              Wrap(
                spacing: 8,
                children: [for (final e in alloc.entries) Chip(label: Text('${e.key}: ₹${e.value.toStringAsFixed(0)}'))],
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 8),
            FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save budget')),
          ],
        ),
      ),
    );
  }
}
