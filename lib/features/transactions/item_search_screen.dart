/// Search + detail: matches raw category, any level, or item
/// (`food`, `junk`, `gobi-65` all find `food junk gobi-65`), scoped to a period
/// — **this month by default**, with one-tap filters for last month, any month,
/// any year, or all time (#4). Clearing the box lists the period itself.
/// Exact hyphenated items offer a stats drill-down rolled up by month and by
/// year. Read-only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../core/providers.dart';

final _dayFmt = DateFormat('d MMM yyyy');
final _monthFmt = DateFormat('MMM yyyy');
final _yearFmt = DateFormat('yyyy');

/// One period of an item's history: how many times, what it cost, the average
/// (the number the overpay flag compares against).
class PeriodRollUp {
  final int times;
  final double total;
  const PeriodRollUp(this.times, this.total);
  double get average => times == 0 ? 0 : total / times;
}

/// Count + total per period label (`Sep 2026`, `2026`) for one item's rows.
/// PLAN promise: item search answers with sum/count per month AND per year.
Map<String, PeriodRollUp> rollUpByPeriod(List<Transaction> rows, DateFormat fmt) {
  final counts = <String, int>{};
  final totals = <String, double>{};
  for (final r in rows) {
    final key = fmt.format(r.occurredAt);
    counts[key] = (counts[key] ?? 0) + 1;
    totals[key] = (totals[key] ?? 0) + r.actual;
  }
  return {
    for (final key in counts.keys) key: PeriodRollUp(counts[key]!, totals[key]!),
  };
}

class ItemSearchScreen extends ConsumerStatefulWidget {
  const ItemSearchScreen({super.key});

  @override
  ConsumerState<ItemSearchScreen> createState() => _ItemSearchScreenState();
}

/// What the search is looking at. The owner asked for "current month first,
/// filters for anything else", so [when] is the default and the only thing
/// that has to be touched to widen it.
enum SearchWhen {
  thisMonth('This month'),
  lastMonth('Last month'),
  aMonth('Pick a month'),
  aYear('Pick a year'),
  aRange('Pick a range'),
  allTime('All time');

  const SearchWhen(this.label);
  final String label;
}

class _ItemSearchScreenState extends ConsumerState<ItemSearchScreen> {
  final _q = TextEditingController();
  SearchWhen _when = SearchWhen.thisMonth;
  DateTime? _month;
  int? _year;
  /// A custom range: from 1st of [fromMonth] to the end of [toMonth].
  DateTime? _fromMonth;
  DateTime? _toMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _year = now.year;
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  ({DateTime? from, DateTime? to}) _window() {
    switch (_when) {
      case SearchWhen.thisMonth:
        final now = DateTime.now();
        return _monthWindow(DateTime(now.year, now.month));
      case SearchWhen.lastMonth:
        final now = DateTime.now();
        return _monthWindow(DateTime(now.year, now.month - 1));
      case SearchWhen.aMonth:
        return _month == null ? (from: null, to: null) : _monthWindow(_month!);
      case SearchWhen.aYear:
        return _year == null
            ? (from: null, to: null)
            : (from: DateTime(_year!), to: DateTime(_year! + 1, 1, 1).subtract(const Duration(milliseconds: 1)));
      case SearchWhen.aRange:
        if (_fromMonth == null) return (from: null, to: null);
        return (
          from: DateTime(_fromMonth!.year, _fromMonth!.month),
          to: DateTime(_toMonth?.year ?? _fromMonth!.year, (_toMonth?.month ?? _fromMonth!.month) + 1)
              .subtract(const Duration(milliseconds: 1)),
        );
      case SearchWhen.allTime:
        return (from: null, to: null);
    }
  }

  ({DateTime? from, DateTime? to}) _monthWindow(DateTime m) => (
        from: DateTime(m.year, m.month),
        to: DateTime(m.year, m.month + 1).subtract(const Duration(milliseconds: 1)),
      );

  String _scopeLabel() {
    switch (_when) {
      case SearchWhen.thisMonth:
        return _monthFmt.format(DateTime.now());
      case SearchWhen.lastMonth:
        final now = DateTime.now();
        return _monthFmt.format(DateTime(now.year, now.month - 1));
      case SearchWhen.aMonth:
        return _month == null ? 'Pick a month' : _monthFmt.format(_month!);
      case SearchWhen.aYear:
        return _year == null ? 'Pick a year' : '$_year';
      case SearchWhen.aRange:
        if (_fromMonth == null) return 'Pick a range';
        return '${_monthFmt.format(_fromMonth!)} → ${_monthFmt.format(_toMonth ?? _fromMonth!)}';
      case SearchWhen.allTime:
        return 'all time';
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _month ?? DateTime(now.year, now.month),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _month = DateTime(picked.year, picked.month);
      _when = SearchWhen.aMonth;
    });
  }

  /// Two month pickers, in order: the range starts, then the range ends.
  Future<void> _pickRange() async {
    final now = DateTime.now();
    final from = await showDatePicker(
      context: context,
      initialDate: _fromMonth ?? DateTime(now.year, now.month),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Range starts',
    );
    if (from == null || !mounted) return;
    final to = await showDatePicker(
      context: context,
      initialDate: _toMonth ?? DateTime(from.year, from.month),
      firstDate: DateTime(from.year, from.month),
      lastDate: DateTime(now.year + 1, 12),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Range ends',
    );
    if (to == null || !mounted) return;
    setState(() {
      _fromMonth = DateTime(from.year, from.month);
      _toMonth = DateTime(to.year, to.month);
      _when = SearchWhen.aRange;
    });
  }

  Future<void> _pickYear() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year ?? now.year),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _year = picked.year;
      _when = SearchWhen.aYear;
    });
  }

  @override
  Widget build(BuildContext context) {
    final window = _window();
    final query = _q.text.trim();
    final results = ref.watch(scopedSearchProvider((query: query, from: window.from, to: window.to)));
    final items = ref.watch(allItemsProvider);
    final months = ref.watch(monthsWithActivityProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
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
          // Scope chips: current month by default, anything else one tap away.
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final w in SearchWhen.values)
                  if (w == SearchWhen.aMonth || w == SearchWhen.aYear || w == SearchWhen.aRange)
                    ActionChip(
                      avatar: Icon(
                        switch (w) {
                          SearchWhen.aMonth => Icons.calendar_month,
                          SearchWhen.aYear => Icons.calendar_today,
                          _ => Icons.date_range_outlined,
                        },
                        size: 18,
                      ),
                      label: Text(_scopeLabelFor(w)),
                      onPressed: () => switch (w) {
                        SearchWhen.aMonth => _pickMonth(),
                        SearchWhen.aYear => _pickYear(),
                        _ => _pickRange(),
                      },
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(w.label),
                        selected: _when == w,
                        onSelected: (_) => setState(() => _when = w),
                      ),
                    ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Searching ${_scopeLabel()} · clear the box to list that period',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: results.when(
              data: (rows) {
                if (rows.isEmpty) {
                  if (query.isEmpty) {
                    return _browseAll(context, items, months);
                  }
                  return Center(child: Text('No matches for "$query" in ${_scopeLabel()}.'));
                }
                final spent = rows.where((r) => r.actual < 0).fold<double>(0, (s, r) => s + r.actual);
                final income = rows.where((r) => r.actual > 0).fold<double>(0, (s, r) => s + r.actual);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text(
                        '${rows.length} entr${rows.length == 1 ? 'y' : 'ies'} · in ₹${income.toStringAsFixed(0)} · out ₹${spent.abs().toStringAsFixed(0)}',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (_, i) {
                          final row = rows[i];
                          final isNeutral = row.linkType == 'debt' || row.kind == 'lend' || row.kind == 'borrow';
                          return ListTile(
                            leading: Icon(
                              isNeutral
                                  ? Icons.handshake_outlined
                                  : (row.actual < 0 ? Icons.arrow_upward : Icons.arrow_downward),
                              color: isNeutral ? Colors.blue : (row.actual < 0 ? Colors.red : Colors.green),
                            ),
                            title: Text(row.categoryRaw),
                            subtitle: Text(
                              '${_dayFmt.format(row.occurredAt)}'
                              '${isNeutral ? (row.absorbed == 1 ? ' · absorbed into the month' : ' · held out of the month') : ''}',
                            ),
                            trailing: Text('₹${row.actual.toStringAsFixed(0)}'),
                          );
                        },
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

  String _scopeLabelFor(SearchWhen w) => switch (w) {
        SearchWhen.aMonth => _month == null ? 'Month…' : _monthFmt.format(_month!),
        SearchWhen.aYear => _year == null ? 'Year…' : '$_year',
        SearchWhen.aRange => _fromMonth == null
            ? 'Range…'
            : '${_monthFmt.format(_fromMonth!)} → ${_monthFmt.format(_toMonth ?? _fromMonth!)}',
        SearchWhen.thisMonth => _monthFmt.format(DateTime.now()),
        SearchWhen.lastMonth => _monthFmt.format(DateTime(DateTime.now().year, DateTime.now().month - 1)),
        SearchWhen.allTime => 'All time',
      };

  /// Empty query + an empty window (All time) → let the owner browse items
  /// and pick a month from the ones that actually have data.
  Widget _browseAll(BuildContext context, AsyncValue<List<String>> items, AsyncValue<List<String>> months) {
    final theme = Theme.of(context);
    return items.maybeWhen(
      data: (all) => ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Text('Tap an item for its full history, or pick a period with data:'),
          ),
          months.maybeWhen(
            data: (list) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final m in list.take(12))
                    ActionChip(
                      label: Text(m),
                      onPressed: () {
                        final parts = m.split('-');
                        setState(() {
                          _month = DateTime(int.parse(parts[0]), int.parse(parts[1]));
                          _when = SearchWhen.aMonth;
                        });
                      },
                    ),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const Divider(),
          for (final item in all)
            ListTile(
              dense: true,
              leading: const Icon(Icons.fastfood),
              title: Text(item),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
              ),
            ),
          if (all.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Nothing recorded yet in ${_scopeLabel()}.', style: theme.textTheme.bodySmall),
            ),
        ],
      ),
      orElse: () => const Center(child: CircularProgressIndicator()),
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
    final byMonth = rollUpByPeriod(rows, _monthFmt);
    final byYear = rollUpByPeriod(rows, _yearFmt);
    final years = byYear.keys.toList()..sort();
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
                _Stat('Years', '${years.length}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('By month', style: Theme.of(context).textTheme.titleSmall),
        for (final m in byMonth.keys.toList()..sort())
          ListTile(
            dense: true,
            title: Text(m),
            trailing: Text('×${byMonth[m]!.times} · ₹${byMonth[m]!.total.abs().toStringAsFixed(0)}'),
          ),
        const Divider(),
        Text('By year', style: Theme.of(context).textTheme.titleSmall),
        for (final y in years)
          ListTile(
            dense: true,
            title: Text(y),
            subtitle: Text('avg ₹${byYear[y]!.average.abs().toStringAsFixed(0)}'),
            trailing: Text('×${byYear[y]!.times} · ₹${byYear[y]!.total.abs().toStringAsFixed(0)}'),
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
