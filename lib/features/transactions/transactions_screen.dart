/// Transactions home: month summary + recent list + entry FAB + item search.
/// Data via [recentTransactionsProvider] / [monthSummaryProvider]; writes in entry_sheet.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../core/providers.dart';
import '../budgets/budget_screen.dart';
import '../cash/quickadd_sheet.dart';
import '../cash/transfer_sheet.dart';
import '../customization/accounts_screen.dart';
import '../instruments/instruments_screen.dart';
import '../intake/intake_screen.dart';
import '../neutral/debts_screen.dart';
import '../reconcile/networth_screen.dart';
import '../reconcile/price_screen.dart';
import '../reconcile/reconcile_screen.dart';
import '../reports/reports_screen.dart';
import '../splits/splits_screen.dart';
import 'entry_sheet.dart';
import 'item_search_screen.dart';

final _dayFmt = DateFormat('d MMM, h:mm a');
final _monthFmt = DateFormat('MMMM yyyy');

String _monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  /// all | cash | digital spend filter.
  String _filter = 'all';

  Future<void> _openEntry() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const EntrySheet(),
    );
    if (saved ?? false) {
      ref
        ..invalidate(recentTransactionsProvider)
        ..invalidate(monthSummaryProvider(_monthKey(_month)));
    }
  }

  Future<void> _openTransfer() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const TransferSheet(),
    );
    if (saved ?? false) {
      ref
        ..invalidate(recentTransactionsProvider)
        ..invalidate(monthSummaryProvider(_monthKey(_month)));
    }
  }

  Future<void> _openQuickAdd() async {
    final saved = await openQuickAdd(context);
    if (saved) {
      ref
        ..invalidate(recentTransactionsProvider)
        ..invalidate(monthSummaryProvider(_monthKey(_month)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = _monthKey(_month);
    final summary = ref.watch(monthSummaryProvider(key));
    final recent = ref.watch(recentTransactionsProvider);
    final accounts = ref.watch(accountsProvider);
    final names = accounts.maybeWhen(data: (l) => {for (final a in l) a.id: a.name}, orElse: () => const <String, String>{});
    final kinds = accounts.maybeWhen(data: (l) => {for (final a in l) a.id: a.kind}, orElse: () => const <String, String>{});

    bool passesFilter(Transaction row) {
      if (_filter == 'all') return true;
      final isCash = (kinds[row.accountId] ?? 'digital').toLowerCase().contains('cash');
      return _filter == 'cash' ? isCash : !isCash;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            tooltip: 'Accounts',
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountsScreen())),
          ),
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ItemSearchScreen())),
          ),
          IconButton(
            tooltip: 'Budgets',
            icon: const Icon(Icons.pie_chart_outline),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetScreen())),
          ),
          IconButton(
            tooltip: 'Lending & loans',
            icon: const Icon(Icons.handshake_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DebtsScreen())),
          ),
          IconButton(
            tooltip: 'Splits',
            icon: const Icon(Icons.group_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SplitsScreen())),
          ),
          IconButton(
            tooltip: 'Instruments',
            icon: const Icon(Icons.show_chart),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InstrumentsScreen())),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'transfer') {
                _openTransfer();
                return;
              }
              if (v == 'quickadd') {
                _openQuickAdd();
                return;
              }
              final dest = switch (v) {
                'reconcile' => const ReconcileScreen(),
                'prices' => const PriceScreen(),
                'networth' => const NetWorthScreen(),
                'reports' => const ReportsScreen(),
                'intake' => const IntakeScreen(),
                _ => null,
              };
              if (dest != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => dest));
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reconcile', child: Text('Reconcile')),
              PopupMenuItem(value: 'prices', child: Text('Price memory')),
              PopupMenuItem(value: 'networth', child: Text('Net worth')),
              PopupMenuItem(value: 'reports', child: Text('Reports')),
              PopupMenuItem(value: 'intake', child: Text('Intake confirm')),
              PopupMenuItem(value: 'transfer', child: Text('Move between accounts')),
              PopupMenuItem(value: 'quickadd', child: Text('Quick cash spend')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEntry,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: Column(
        children: [
          _MonthBar(
            label: _monthFmt.format(_month),
            onPrev: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
            onNext: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
          ),
          summary.when(
            data: (s) => _SummaryCard(
              inflow: s.inActual,
              outflow: s.outActual,
              budgetOut: s.outBudget,
              count: s.count,
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Summary unavailable: $e'),
          ),
          accounts.maybeWhen(
            data: (l) => l.isEmpty
                ? _NoAccountBanner(
                    onCreate: () async {
                      await ref.read(accountRepositoryProvider).create(name: 'Cash', kind: 'cash');
                      ref.invalidate(accountsProvider);
                    },
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: recent.when(
              data: (rows) {
                final inMonth = rows
                    .where((t) => t.occurredAt.year == _month.year && t.occurredAt.month == _month.month)
                    .where(passesFilter)
                    .toList();
                if (inMonth.isEmpty) {
                  return Center(
                    child: Text(_filter == 'all' ? 'No entries this month — tap Add.' : 'No ${_filter} entries this month.'),
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final f in const ['all', 'cash', 'digital'])
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(f[0].toUpperCase() + f.substring(1)),
                                selected: _filter == f,
                                onSelected: (_) => setState(() => _filter = f),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: inMonth.length,
                        itemBuilder: (_, i) => _TxnTile(row: inMonth[i], accountName: names[inMonth[i].accountId]),
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

class _MonthBar extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthBar({required this.label, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double inflow;
  final double outflow;
  final double budgetOut;
  final int count;
  const _SummaryCard({required this.inflow, required this.outflow, required this.budgetOut, required this.count});

  @override
  Widget build(BuildContext context) {
    final net = inflow + outflow; // outflow is negative
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat('In', '₹${inflow.toStringAsFixed(0)}'),
            _Stat('Out (bank)', '₹${outflow.abs().toStringAsFixed(0)}'),
            _Stat('Out (budget)', '₹${budgetOut.abs().toStringAsFixed(0)}'),
            _Stat('Net', '₹${net.toStringAsFixed(0)}'),
            _Stat('Entries', '$count'),
          ],
        ),
      ),
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
        Text(value, style: Theme.of(context).textTheme.titleSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _NoAccountBanner extends StatelessWidget {
  final Future<void> Function() onCreate;
  const _NoAccountBanner({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: const Text('No accounts yet'),
        subtitle: const Text('Entries need a source. Create a Cash wallet to start.'),
        trailing: FilledButton.tonal(onPressed: () => onCreate(), child: const Text('Create Cash')),
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  final Transaction row;
  final String? accountName;
  const _TxnTile({required this.row, required this.accountName});

  @override
  Widget build(BuildContext context) {
    final isOut = row.actual < 0;
    return ListTile(
      leading: Icon(
        isOut ? Icons.arrow_upward : Icons.arrow_downward,
        color: isOut ? Colors.red : Colors.green,
      ),
      title: Text(row.categoryRaw),
      subtitle: Text('${_dayFmt.format(row.occurredAt)}${accountName != null ? ' · $accountName' : ''}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₹${row.actual.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: isOut ? Colors.red : Colors.green),
          ),
          if (row.budgetImpact != row.actual)
            Text('budget ₹${row.budgetImpact.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
