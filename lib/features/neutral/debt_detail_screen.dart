/// One lend/borrow contract, in full: every row of its money trail, the
/// aging/nudge badges, and the payoff action. Reached from the Shared-money
/// screen's Lent/Borrowed tabs (#12) and from tapping a settled one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../core/providers.dart';
import 'debt_logic.dart';

final _dayFmt = DateFormat('d MMM yyyy');

class DebtDetailScreen extends ConsumerWidget {
  final String debtId;
  final VoidCallback onChanged;
  const DebtDetailScreen({super.key, required this.debtId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debt = ref.watch(debtByIdProvider(debtId));
    final history = ref.watch(debtHistoryProvider(debtId));
    return Scaffold(
      appBar: AppBar(title: Text(debt.maybeWhen(
        data: (d) => d == null ? 'Contract' : d.counterparty,
        orElse: () => 'Contract',
      ),),),
      body: debt.when(
        data: (d) => d == null
            ? const Center(child: Text('This contract is gone.'))
            : _body(context, ref, d, history),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, Debt d, AsyncValue<List<Transaction>> history) {
    final now = DateTime.now();
    final left = remaining(d.principal, d.paid);
    final age = agingDays(d.createdAt, now);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.direction == 'lent' ? 'You lent to ${d.counterparty}' : 'You borrowed from ${d.counterparty}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Figure('Total', '₹${d.principal.round()}'),
                    _Figure('Back so far', '₹${d.paid.round()}'),
                    _Figure('Left', '₹${left.round()}'),
                    _Figure('Age', '$age d'),
                  ],
                ),
                const SizedBox(height: 10),
                if (d.status != 'open')
                  Text('Settled', style: theme.textTheme.titleSmall?.copyWith(color: Colors.green))
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final done = await showDialog<bool>(
                          context: context,
                          builder: (_) => PayoffDialog(debt: d),
                        );
                        if (done ?? false) onChanged();
                      },
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Record payoff'),
                    ),
                  ),
                if (d.note != null && d.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(d.note!),
                ],
                if (isOverdue(dueDate: d.dueDate, status: d.status, now: now))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Overdue since ${_dayFmt.format(d.dueDate!)}', style: const TextStyle(color: Colors.red)),
                  ),
                if (nudgeDue(nudgeDate: d.nudgeDate, status: d.status, now: now) &&
                    !isOverdue(dueDate: d.dueDate, status: d.status, now: now))
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Nudge due — time for a reminder', style: TextStyle(color: Colors.orange)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Money trail', style: theme.textTheme.titleSmall),
        history.when(
          data: (rows) => Column(
            children: [
              for (final t in rows)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(switch (t.kind) {
                    'lend' || 'borrow' => Icons.arrow_outward,
                    'settle' => Icons.arrow_downward,
                    _ => Icons.receipt_long_outlined,
                  },),
                  title: Text(switch (t.kind) {
                    'lend' => 'Handed over',
                    'borrow' => 'Taken',
                    'settle' => d.direction == 'lent' ? 'Came back' : 'Paid back',
                    _ => t.kind,
                  },),
                  subtitle: Text(
                    '${_dayFmt.format(t.occurredAt)}${t.note != null && t.note!.isNotEmpty ? ' · ${t.note}' : ''}'
                    '${t.absorbed == 1 ? ' · absorbed into that month' : ''}',
                  ),
                  trailing: Text('₹${t.actual.abs().round()}'),
                ),
            ],
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Could not load: $e'),
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;
  const _Figure(this.label, this.value);

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

class PayoffDialog extends ConsumerStatefulWidget {
  final Debt debt;
  const PayoffDialog({super.key, required this.debt});

  @override
  ConsumerState<PayoffDialog> createState() => _PayoffDialogState();
}

class _PayoffDialogState extends ConsumerState<PayoffDialog> {
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
      title: Text(widget.debt.direction == 'lent' ? 'Came back' : 'Paid back'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('₹${left.round()} outstanding with ${widget.debt.counterparty}'),
          const SizedBox(height: 8),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '₹ ',
              helperText: left > 0 ? 'Anything up to ₹${left.round()}' : null,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton.icon(
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
              setState(
                () => _error = e.toString().replaceFirst('Invalid argument(s): ', '').replaceFirst('Bad state: ', ''),
              );
            }
          },
          label: const Text('Record'),
          icon: const Icon(Icons.check),
        ),
      ],
    );
  }
}