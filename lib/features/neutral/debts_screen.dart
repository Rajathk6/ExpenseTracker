/// Debts home: open contracts with payoff progress + aging badges,
/// settled history, add/pay flows. Money moves with budgetImpact 0 always.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../core/providers.dart';
import '../neutral/debt_logic.dart';

final _dayFmt = DateFormat('d MMM yyyy');

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  void _refresh(WidgetRef ref) {
    ref
      ..invalidate(openDebtsProvider)
      ..invalidate(allDebtsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openDebtsProvider);
    final all = ref.watch(allDebtsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Lending & loans')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final done = await showDialog<bool>(
            context: context,
            builder: (_) => const _DebtDialog(),
          );
          if (done ?? false) _refresh(ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Open', style: Theme.of(context).textTheme.titleSmall),
          open.when(
            data: (list) {
              if (list.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text('Nothing open.'));
              return Column(children: [for (final d in list) _DebtCard(debt: d, onChanged: () => _refresh(ref))]);
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Could not load: $e'),
          ),
          const SizedBox(height: 8),
          Text('Settled', style: Theme.of(context).textTheme.titleSmall),
          all.when(
            data: (list) {
              final done = list.where((d) => d.status != 'open').toList();
              if (done.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text('No settled contracts.'));
              return Column(
                children: [
                  for (final d in done)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                      title: Text('${d.direction == 'lent' ? 'Lent to' : 'Borrowed from'} ${d.counterparty}'),
                      trailing: Text('₹${d.principal.toStringAsFixed(0)}'),
                    ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Could not load: $e'),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends ConsumerWidget {
  final Debt debt;
  final VoidCallback onChanged;
  const _DebtCard({required this.debt, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final left = remaining(debt.principal, debt.paid);
    final ratio = debt.principal <= 0 ? 1.0 : (debt.paid / debt.principal).clamp(0.0, 1.0);
    final age = agingDays(debt.createdAt, now);
    final overdue = isOverdue(dueDate: debt.dueDate, status: debt.status, now: now);
    final nudge = nudgeDue(nudgeDate: debt.nudgeDate, status: debt.status, now: now);
    final history = ref.watch(debtHistoryProvider(debt.id));
    return Card(
      child: ExpansionTile(
        title: Text('${debt.direction == 'lent' ? 'Lent to' : 'Borrowed from'} ${debt.counterparty}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(value: ratio),
            const SizedBox(height: 4),
            Text('₹${debt.paid.toStringAsFixed(0)} of ₹${debt.principal.toStringAsFixed(0)} · ₹${left.toStringAsFixed(0)} left · $age day${age == 1 ? '' : 's'}'),
            if (overdue)
              Text('Overdue since ${_dayFmt.format(debt.dueDate!)}', style: const TextStyle(color: Colors.red)),
            if (nudge && !overdue) const Text('Nudge due — time for a reminder', style: TextStyle(color: Colors.orange)),
          ],
        ),
        trailing: FilledButton.tonal(
          onPressed: () async {
            final done = await showDialog<bool>(
              context: context,
              builder: (_) => _PayDialog(debt: debt),
            );
            if (done ?? false) onChanged();
          },
          child: const Text('Pay'),
        ),
        children: [
          history.when(
            data: (rows) => Column(
              children: [
                for (final t in rows)
                  ListTile(
                    dense: true,
                    title: Text(t.kind == 'lend' || t.kind == 'borrow' ? 'Principal' : 'Payoff'),
                    subtitle: Text(_dayFmt.format(t.occurredAt)),
                    trailing: Text('₹${t.actual.toStringAsFixed(0)}'),
                  ),
              ],
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Could not load: $e'),
          ),
        ],
      ),
    );
  }
}

class _DebtDialog extends ConsumerStatefulWidget {
  const _DebtDialog();

  @override
  ConsumerState<_DebtDialog> createState() => _DebtDialogState();
}

class _DebtDialogState extends ConsumerState<_DebtDialog> {
  String _direction = 'lent';
  final _who = TextEditingController();
  final _principal = TextEditingController();
  final _note = TextEditingController();
  String? _accountId;
  DateTime? _due;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _who.dispose();
    _principal.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(List<Account> accounts) async {
    final principal = double.tryParse(_principal.text.trim());
    if (_who.text.trim().isEmpty) {
      setState(() => _error = 'Enter who this is with');
      return;
    }
    if (principal == null || principal <= 0) {
      setState(() => _error = 'Enter a valid principal');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final repo = ref.read(debtRepositoryProvider);
      if (_direction == 'lent') {
        await repo.lend(
          counterparty: _who.text,
          principal: principal,
          accountId: _accountId,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          dueDate: _due,
        );
      } else {
        await repo.borrow(
          counterparty: _who.text,
          principal: principal,
          accountId: _accountId,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          dueDate: _due,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
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
    return AlertDialog(
      title: const Text('New lending / loan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'lent', label: Text('I lent')),
                ButtonSegment(value: 'borrowed', label: Text('I borrowed')),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() => _direction = s.first),
            ),
            const SizedBox(height: 8),
            TextField(controller: _who, decoration: const InputDecoration(labelText: 'Counterparty (e.g. Ravi)')),
            TextField(
              controller: _principal,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Full amount', prefixText: '₹ '),
            ),
            accounts.maybeWhen(
              data: (list) => list.isEmpty
                  ? const SizedBox.shrink()
                  : DropdownButtonFormField<String>(
                      initialValue: _accountId ??= list.first.id,
                      decoration: const InputDecoration(labelText: 'Account'),
                      items: [for (final a in list) DropdownMenuItem(value: a.id, child: Text(a.name))],
                      onChanged: (v) => setState(() => _accountId = v),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
            TextField(controller: _note, decoration: const InputDecoration(labelText: 'Note (optional)')),
            Row(
              children: [
                Expanded(child: Text(_due == null ? 'No due date' : 'Due ${_dayFmt.format(_due!)}')),
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (d != null) setState(() => _due = d);
                  },
                  child: const Text('Set due'),
                ),
              ],
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving
              ? null
              : () => _save(accounts.maybeWhen(data: (l) => l, orElse: () => const <Account>[])),
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}

class _PayDialog extends ConsumerStatefulWidget {
  final Debt debt;
  const _PayDialog({required this.debt});

  @override
  ConsumerState<_PayDialog> createState() => _PayDialogState();
}

class _PayDialogState extends ConsumerState<_PayDialog> {
  final _amount = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = remaining(widget.debt.principal, widget.debt.paid);
    return AlertDialog(
      title: Text('Record payoff — ${widget.debt.counterparty}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('₹${left.toStringAsFixed(0)} left of ₹${widget.debt.principal.toStringAsFixed(0)}'),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount now', prefixText: '₹ '),
          ),
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final amount = double.tryParse(_amount.text.trim());
            if (amount == null || amount <= 0) {
              setState(() => _error = 'Enter a valid amount');
              return;
            }
            try {
              await ref.read(debtRepositoryProvider).pay(debtId: widget.debt.id, amount: amount);
              if (context.mounted) Navigator.of(context).pop(true);
            } on Object catch (e) {
              setState(() => _error = e.toString().replaceFirst('Invalid argument(s): ', '').replaceFirst('Bad state: ', ''));
            }
          },
          child: const Text('Record'),
        ),
      ],
    );
  }
}
