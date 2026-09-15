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
import '../settings/settings_screen.dart';
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
      _refreshMonth();
    }
  }

  void _refreshMonth() {
    final key = _monthKey(_month);
    ref
      ..invalidate(recentTransactionsProvider)
      ..invalidate(monthSummaryProvider(key))
      ..invalidate(bucketSpendProvider(key))
      ..invalidate(monthOpenProvider(key));
  }

  /// Tap an entry → full edit, same form as Add. Linked rows (debts /
  /// splits / transfers) explain themselves and point at their own screen.
  Future<void> _openEdit(Transaction row) async {
    if (row.linkType != null) {
      final where = switch (row.linkType) {
        'debt' => 'Lending & loans',
        'split' => 'Splits',
        'transfer' => 'Move between accounts',
        _ => 'its own screen',
      };
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(row.categoryRaw),
          content: Text('This entry belongs to a $where record — edit it there so the books stay consistent.'),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
        ),
      );
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EntrySheet(existing: row),
    );
    if (saved ?? false) _refreshMonth();
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
                'settings' => const SettingsScreen(),
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
              PopupMenuItem(value: 'settings', child: Text('Settings & backup')),
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
              outflow: s.outBudget,
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
          _MonthSetupCard(monthKey: key),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            child: recent.when(
              data: (rows) {
                final inMonth = rows
                    .where((t) => t.occurredAt.year == _month.year && t.occurredAt.month == _month.month)
                    .where(passesFilter)
                    .toList();
                if (inMonth.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_filter == 'all'
                            ? 'No entries this month — tap Add.'
                            : 'No $_filter entries this month.',),
                        if (_filter != 'all')
                          TextButton(
                            onPressed: () => setState(() => _filter = 'all'),
                            child: const Text('Show all'),
                          ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: inMonth.length,
                  itemBuilder: (_, i) => _TxnTile(
                    row: inMonth[i],
                    accountName: names[inMonth[i].accountId],
                    onTap: () => _openEdit(inMonth[i]),
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
  const _SummaryCard({required this.inflow, required this.outflow});

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
            _Stat('Out', '₹${outflow.abs().toStringAsFixed(0)}'),
            _Stat('Net', '₹${net.toStringAsFixed(0)}'),
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

/// Month-start opener (#8): when the viewed month has no entries and no
/// saved opener, ask for the optional month-start details. Editable later
/// from the same card (compact form once saved).
class _MonthSetupCard extends ConsumerWidget {
  final String monthKey;
  const _MonthSetupCard({required this.monthKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(monthOpenProvider(monthKey));
    final recent = ref.watch(recentTransactionsProvider);
    return open.when(
      data: (saved) {
        final monthRows = recent.maybeWhen(
          data: (rows) => rows.where((t) {
            final k = '${t.occurredAt.year}-${t.occurredAt.month.toString().padLeft(2, '0')}';
            return k == monthKey;
          }).length,
          orElse: () => 1,
        );
        if (saved != null || monthRows > 0) {
          if (saved == null) return const SizedBox.shrink();
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(_describe(saved)),
              trailing: TextButton(
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (_) => _MonthOpenDialog(monthKey: monthKey, existing: saved),
                  );
                  ref.invalidate(monthOpenProvider(monthKey));
                },
                child: const Text('Edit'),
              ),
            ),
          );
        }
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('New month — set it up? (all optional)'),
            subtitle: const Text('Budget, bank + cash balances, card limit. Skippable, editable later.'),
            trailing: FilledButton.tonal(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (_) => _MonthOpenDialog(monthKey: monthKey, existing: null),
                );
                ref.invalidate(monthOpenProvider(monthKey));
              },
              child: const Text('Set up'),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (o, s) => const SizedBox.shrink(),
    );
  }

  static String _describe(MonthOpenData m) {
    final parts = <String>[];
    if (m.budgetOut != null) parts.add('budget ₹${m.budgetOut!.toStringAsFixed(0)}');
    if (m.bankBalance != null) parts.add('bank ₹${m.bankBalance!.toStringAsFixed(0)}');
    if (m.cashBalance != null) parts.add('cash ₹${m.cashBalance!.toStringAsFixed(0)}');
    if (m.cardLimit != null) parts.add('card limit ₹${m.cardLimit!.toStringAsFixed(0)}');
    if (m.budgetIn != null) parts.add('in ₹${m.budgetIn!.toStringAsFixed(0)}');
    return parts.isEmpty ? 'Month opener saved (all blank)' : 'Month start · ${parts.join(' · ')}';
  }
}

class _MonthOpenDialog extends ConsumerStatefulWidget {
  final String monthKey;
  final MonthOpenData? existing;
  const _MonthOpenDialog({required this.monthKey, required this.existing});

  @override
  ConsumerState<_MonthOpenDialog> createState() => _MonthOpenDialogState();
}

class _MonthOpenDialogState extends ConsumerState<_MonthOpenDialog> {
  late final TextEditingController _in;
  late final TextEditingController _out;
  late final TextEditingController _bank;
  late final TextEditingController _cash;
  late final TextEditingController _limit;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    String fmt(double? v) => v == null ? '' : v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
    _in = TextEditingController(text: fmt(e?.budgetIn));
    _out = TextEditingController(text: fmt(e?.budgetOut));
    _bank = TextEditingController(text: fmt(e?.bankBalance));
    _cash = TextEditingController(text: fmt(e?.cashBalance));
    _limit = TextEditingController(text: fmt(e?.cardLimit));
  }

  @override
  void dispose() {
    _in.dispose();
    _out.dispose();
    _bank.dispose();
    _cash.dispose();
    _limit.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Month start — ${widget.monthKey}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('All optional. Fill what you know; change anytime.'),
            const SizedBox(height: 8),
            TextField(controller: _out, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Out budget ₹ (optional)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _in, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'In budget ₹ (optional)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _bank, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Bank balance ₹ (optional)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _cash, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Cash in hand ₹ (optional)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _limit, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Credit card limit ₹ (optional)', border: OutlineInputBorder())),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Skip')),
        FilledButton(
          onPressed: () async {
            for (final c in [_in, _out, _bank, _cash, _limit]) {
              if (c.text.trim().isNotEmpty && double.tryParse(c.text.trim()) == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numbers only — or leave blank')));
                return;
              }
            }
            await ref.read(monthOpenRepositoryProvider).save(
                  month: widget.monthKey,
                  budgetIn: _num(_in),
                  budgetOut: _num(_out),
                  bankBalance: _num(_bank),
                  cashBalance: _num(_cash),
                  cardLimit: _num(_limit),
                );
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _TxnTile extends ConsumerWidget {
  final Transaction row;
  final String? accountName;
  final VoidCallback? onTap;
  const _TxnTile({required this.row, required this.accountName, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Split rows show the live outstanding (paid → shrinks → my share),
    // whole rupees, so the main list tells the truth as friends pay back.
    if (row.kind == 'split' && row.linkId != null) {
      final live = ref.watch(splitOutstandingProvider(row.linkId!));
      return live.when(
        data: (left) => ListTile(
          onTap: onTap,
          leading: const Icon(Icons.group_outlined, color: Colors.red),
          title: Text(row.categoryRaw),
          subtitle: Text(
            '${_dayFmt.format(row.occurredAt)}${accountName != null ? ' · $accountName' : ''} · ₹$left to come back',
          ),
          trailing: Text(
            '₹${row.actual.round()}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ),
        loading: () => _plainTile(context),
        error: (o, s) => _plainTile(context),
      );
    }
    return _plainTile(context);
  }

  Widget _plainTile(BuildContext context) {
    final isOut = row.actual < 0;
    return ListTile(
      onTap: onTap,
      leading: Icon(
        isOut ? Icons.arrow_upward : Icons.arrow_downward,
        color: isOut ? Colors.red : Colors.green,
      ),
      title: Text(row.categoryRaw),
      subtitle: Text(
        '${_dayFmt.format(row.occurredAt)}${accountName != null ? ' · $accountName' : ''}'
        '${row.bucket != null && row.bucket!.isNotEmpty ? ' · ${row.bucket}' : ''}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₹${row.actual.round()}',
            style: TextStyle(fontWeight: FontWeight.bold, color: isOut ? Colors.red : Colors.green),
          ),
          if (row.budgetImpact != row.actual)
            Text('budget ₹${row.budgetImpact.round()}', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
