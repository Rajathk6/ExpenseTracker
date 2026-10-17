/// Transactions home: month summary + recent list + entry FAB + item search.
/// Data via [recentTransactionsProvider] / [monthSummaryProvider]; writes in entry_sheet.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../core/providers.dart';
import '../budgets/budget_status.dart';
import '../budgets/budget_screen.dart';
import '../cash/transfer_sheet.dart';
import '../customization/accounts_screen.dart';
import '../instruments/instruments_screen.dart';
import '../intake/intake_screen.dart';
import '../shared/shared_screen.dart';
import '../reconcile/networth_screen.dart';
import '../reconcile/reconcile_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
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
      ..invalidate(budgetStatusProvider(key))
      ..invalidate(unabsorbedNeutralProvider)
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
            tooltip: 'Lent, borrowed, splits & groups',
            icon: const Icon(Icons.handshake_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SharedScreen())),
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
              final dest = switch (v) {
                'reconcile' => const ReconcileScreen(),
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
              PopupMenuItem(value: 'networth', child: Text('Net worth')),
              PopupMenuItem(value: 'reports', child: Text('Reports & export')),
              PopupMenuItem(value: 'intake', child: Text('Intake confirm')),
              PopupMenuItem(value: 'transfer', child: Text('Move between accounts')),
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
          _BudgetPulseCard(monthKey: key),
          _NeutralHoldCard(monthKey: key),
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
          const _RecurringRulesCard(),
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

String _money(double v) => '₹${v.abs().round()}';

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

/// Repeating entries (#4): what the owner set up to fill in automatically, and
/// a button to fill the pending months now. Applying writes real entries, so
/// nothing appears in the ledger that the owner did not consciously add.
class _RecurringRulesCard extends ConsumerWidget {
  const _RecurringRulesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(recurringRulesProvider);
    return rules.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final service = ref.read(recurringServiceProvider);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Repeating entries', style: Theme.of(context).textTheme.titleSmall),
                for (final rule in list) ...[
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final pending = service.pending(rule);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('${rule.kind == 'in' ? '+' : '−'} ₹${rule.amount.round()} · ${rule.categoryRaw}'),
                        subtitle: Text(
                          'day ${rule.dayOfMonth} · ${rule.months} month(s) from ${rule.startMonth}'
                          '${pending.isEmpty ? ' · all filled' : ' · ${pending.length} to fill'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (pending.isNotEmpty)
                              TextButton(
                                onPressed: () async {
                                  final written = await service.applyAll(rule);
                                  ref
                                    ..invalidate(recurringRulesProvider)
                                    ..invalidate(recentTransactionsProvider)
                                    ..invalidate(budgetStatusProvider(_monthKey(DateTime.now())));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Added $written entr${written == 1 ? 'y' : 'ies'} — edit them like any entry',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Fill in'),
                              ),
                            IconButton(
                              tooltip: 'Stop repeating',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await service.delete(rule.id);
                                ref.invalidate(recurringRulesProvider);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Budget pulse (#7): income is the yardstick, the bucket split carries
/// forward, and anything worth knowing is a line of text — a chart the owner
/// cannot read is worse than a sentence.
class _BudgetPulseCard extends ConsumerWidget {
  final String monthKey;
  const _BudgetPulseCard({required this.monthKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(budgetStatusProvider(monthKey));
    return status.maybeWhen(
      data: (report) {
        if (report.budgetTotal <= 0 && report.spent <= 0) return const SizedBox.shrink();
        final theme = Theme.of(context);
        final colour = switch (report.level) {
          BudgetLevel.over => theme.colorScheme.error,
          BudgetLevel.low => Colors.orange.shade700,
          _ => Colors.teal.shade400,
        };
        final carried = report.sourceMonth != monthKey ? ' (split from ${report.sourceMonth})' : '';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Budget · ${_money(report.budgetTotal)} planned', style: theme.textTheme.titleSmall),
                    Text('${_money(report.income)} in', style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: report.budgetTotal <= 0 ? 0 : (report.spent / report.budgetTotal).clamp(0.0, 1.0),
                    minHeight: 8,
                    color: colour,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_money(report.spent)} spent · ${_money(report.left)} left$carried',
                  style: theme.textTheme.bodySmall,
                ),
                for (final b in report.buckets)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 96, child: Text(b.name, style: theme.textTheme.bodySmall)),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: b.usedFraction.clamp(0.0, 1.0),
                              minHeight: 6,
                              color: switch (b.level) {
                                BudgetLevel.over => theme.colorScheme.error,
                                BudgetLevel.low => Colors.orange.shade700,
                                _ => Colors.teal.shade400,
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 150,
                          child: Text(
                            b.planned > 0 ? '${_money(b.spent)} / ${_money(b.planned)}' : '${_money(b.spent)} · no budget',
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final line in report.alerts)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, size: 16, color: colour),
                        const SizedBox(width: 6),
                        Expanded(child: Text(line, style: theme.textTheme.bodySmall)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Neutral ledger held out of the month until the owner absorbs it (#10).
class _NeutralHoldCard extends ConsumerWidget {
  final String monthKey;
  const _NeutralHoldCard({required this.monthKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(unabsorbedNeutralProvider);
    return rows.maybeWhen(
      data: (all) {
        if (all.isEmpty) return const SizedBox.shrink();
        final inMonth = all
            .where((r) => '${r.occurredAt.year}-${r.occurredAt.month.toString().padLeft(2, '0')}' == monthKey)
            .toList();
        final shown = (inMonth.isEmpty ? all : inMonth).take(3).toList();
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lend / borrow held out of the month (${all.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'These do not touch any month total until you absorb them.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                for (final r in shown)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.categoryRaw),
                    subtitle: Text('${_dayFmt.format(r.occurredAt)} · ₹${r.actual.abs().round()}'),
                    trailing: TextButton(
                      onPressed: () async {
                        await ref.read(transactionRepositoryProvider).setAbsorbed(id: r.id, absorbed: true);
                        ref
                          ..invalidate(unabsorbedNeutralProvider)
                          ..invalidate(monthSummaryProvider(monthKey))
                          ..invalidate(budgetStatusProvider(monthKey));
                      },
                      child: const Text('Absorb'),
                    ),
                  ),
                if (inMonth.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'None in $monthKey — showing the latest.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
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

/// Month-start opener: the one place that sets a month up. Saving it now
/// actually writes the budget row (auto-split across your buckets), the
/// opening bank/cash balances and any repeating income — and says so, because
/// a form that silently discards what you typed is worse than no form.
class _MonthSetupCard extends ConsumerWidget {
  final String monthKey;
  const _MonthSetupCard({required this.monthKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(monthOpenProvider(monthKey));
    final budget = ref.watch(effectiveBudgetProvider(monthKey));
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
          final carried = budget.maybeWhen(
            data: (b) => b == null ? '' : b.sourceMonth == monthKey ? '' : ' (from ${b.sourceMonth})',
            orElse: () => '',
          );
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(_describe(saved, carried)),
              trailing: TextButton(
                onPressed: () => _edit(context, ref, saved),
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
            subtitle: const Text('Sets your budget split, opening balances and repeating salary.'),
            trailing: FilledButton.tonal(
              onPressed: () => _edit(context, ref, null),
              child: const Text('Set up'),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (o, s) => const SizedBox.shrink(),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, MonthOpenData? saved) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _MonthOpenDialog(monthKey: monthKey, existing: saved),
    );
    final key = _monthKey(DateTime.now());
    ref
      ..invalidate(monthOpenProvider(monthKey))
      ..invalidate(effectiveBudgetProvider(monthKey))
      ..invalidate(bucketSpendProvider(monthKey))
      ..invalidate(monthSummaryProvider(key));
  }

  static String _describe(MonthOpenData m, String carried) {
    final parts = <String>[];
    if (m.budgetOut != null) parts.add('budget ₹${m.budgetOut!.toStringAsFixed(0)}$carried');
    if (m.budgetIn != null) parts.add('expected in ₹${m.budgetIn!.toStringAsFixed(0)}');
    if (m.bankBalance != null) parts.add('bank ₹${m.bankBalance!.toStringAsFixed(0)}');
    if (m.cashBalance != null) parts.add('cash ₹${m.cashBalance!.toStringAsFixed(0)}');
    if (m.cardLimit != null) parts.add('card limit ₹${m.cardLimit!.toStringAsFixed(0)}');
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
  late final TextEditingController _out;
  late final TextEditingController _in;
  late final TextEditingController _bank;
  late final TextEditingController _cash;
  late final TextEditingController _limit;
  late final TextEditingController _salaryAmount;
  late final TextEditingController _salaryCategory;
  late final TextEditingController _salaryMonths;
  int _salaryDay = 1;
  String? _salaryAccountId;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    String fmt(double? v) => v == null ? '' : v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
    _out = TextEditingController(text: fmt(e?.budgetOut));
    _in = TextEditingController(text: fmt(e?.budgetIn));
    _bank = TextEditingController(text: fmt(e?.bankBalance));
    _cash = TextEditingController(text: fmt(e?.cashBalance));
    _limit = TextEditingController(text: fmt(e?.cardLimit));
    _salaryAmount = TextEditingController();
    _salaryCategory = TextEditingController(text: 'salary');
    _salaryMonths = TextEditingController();
  }

  @override
  void dispose() {
    _out.dispose();
    _in.dispose();
    _bank.dispose();
    _cash.dispose();
    _limit.dispose();
    _salaryAmount.dispose();
    _salaryCategory.dispose();
    _salaryMonths.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', ''));
  }

  bool _valid(List<TextEditingController> controllers) {
    for (final c in controllers) {
      if (c.text.trim().isEmpty) continue;
      if (double.tryParse(c.text.trim().replaceAll(',', '')) == null) return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_valid([_out, _in, _bank, _cash, _limit, _salaryAmount])) {
      setState(() => _error = 'Numbers only — or leave blank');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final result = await ref.read(monthStartServiceProvider).apply(
            month: widget.monthKey,
            budgetOut: _num(_out),
            budgetIn: _num(_in),
            bankBalance: _num(_bank),
            cashBalance: _num(_cash),
            cardLimit: _num(_limit),
            salaryAmount: _num(_salaryAmount),
            salaryCategory: _salaryCategory.text,
            salaryAccountId: _salaryAccountId,
            salaryMonths: _num(_salaryMonths)?.round() ?? 0,
            salaryDayOfMonth: _salaryDay,
          );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('Month set up · ${result.summary}')));
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Invalid argument(s): ', '');
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final carried = ref.watch(effectiveBudgetProvider(widget.monthKey));
    final buckets = carried.maybeWhen(
      data: (b) => b?.buckets ?? const [],
      orElse: () => const [],
    );
    return AlertDialog(
      title: Text('Month start — ${widget.monthKey}'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                buckets.isEmpty
                    ? 'Leave a field blank to skip it. Your budget split stays 50/30/20 until you change it on the Budgets screen.'
                    : 'Your budget is split ${buckets.map((b) => '${b.name} ${b.pct.round()}%').join(' · ')} — carried from ${carried.value?.sourceMonth ?? 'earlier'}. Change it there, and earlier months stay as they were.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _out,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Budget for the month ₹ (split across your buckets)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bank,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Bank balance right now ₹', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cash,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Cash in hand ₹', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _limit,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Credit card limit ₹ (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              Text('Repeating income (optional)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                'Type the salary once and it can fill this month and the next few — entries stay normal entries you can edit.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _salaryAmount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Salary ₹', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _salaryCategory,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _salaryMonths,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Months to fill (e.g. 4)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _salaryDay,
                    decoration: const InputDecoration(labelText: 'Day', border: OutlineInputBorder()),
                    items: [for (final d in const [1, 5, 10, 15, 20, 25, 28]) DropdownMenuItem(value: d, child: Text('$d'))],
                    onChanged: (v) => setState(() => _salaryDay = v ?? 1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              accounts.maybeWhen(
                data: (list) => list.isEmpty
                    ? const Text('No accounts yet — the salary needs a source account.', style: TextStyle(fontSize: 12))
                    : DropdownButtonFormField<String>(
                        initialValue: _salaryAccountId ?? list.first.id,
                        decoration: const InputDecoration(labelText: 'Salary lands in', border: OutlineInputBorder()),
                        items: [for (final a in list) DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.kind})'))],
                        onChanged: (v) => setState(() => _salaryAccountId = v),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Skip')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save')),
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
