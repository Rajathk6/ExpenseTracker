/// Splits home: group expenses I fronted, with recovery progress.
/// Only my share ever hits the budget; defaults are absorbed honestly.
library;

import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../core/providers.dart';
import '../splits/split_logic.dart';

final _dayFmt = DateFormat('d MMM yyyy');

class SplitsScreen extends ConsumerWidget {
  const SplitsScreen({super.key});

  void _refresh(WidgetRef ref) {
    ref
      ..invalidate(openSplitsProvider)
      ..invalidate(allSplitsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openSplitsProvider);
    final all = ref.watch(allSplitsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Splits')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final done = await showDialog<bool>(
            context: context,
            builder: (_) => const _SplitDialog(),
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
              return Column(children: [for (final s in list) _SplitCard(split: s, onChanged: () => _refresh(ref))]);
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Could not load: $e'),
          ),
          const SizedBox(height: 8),
          Text('Closed', style: Theme.of(context).textTheme.titleSmall),
          all.when(
            data: (list) {
              final done = list.where((s) => s.status != 'open').toList();
              if (done.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text('No closed splits.'));
              return Column(
                children: [
                  for (final s in done)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                      title: Text(s.title),
                      subtitle: Text(
                        s.absorbed > 0
                            ? 'absorbed ₹${s.absorbed.toStringAsFixed(0)}'
                            : 'fully recovered',
                      ),
                      trailing: Text('₹${s.totalPaid.toStringAsFixed(0)}'),
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

class _SplitCard extends ConsumerWidget {
  final Split split;
  final VoidCallback onChanged;
  const _SplitCard({required this.split, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final left = splitRemaining(split.totalPaid, split.myShare, split.received, split.absorbed);
    final ratio = split.totalPaid <= 0
        ? 1.0
        : ((split.received + split.absorbed) / (split.totalPaid - split.myShare).clamp(1, double.infinity))
            .clamp(0.0, 1.0);
    final history = ref.watch(splitHistoryProvider(split.id));
    return Card(
      child: ExpansionTile(
        title: Text(split.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(value: ratio),
            const SizedBox(height: 4),
            Text(
              'Paid ₹${split.totalPaid.toStringAsFixed(0)} · mine ₹${split.myShare.toStringAsFixed(0)} · '
              'back ₹${split.received.toStringAsFixed(0)} · ₹${left.toStringAsFixed(0)} left',
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.tonal(
              onPressed: () async {
                final done = await showDialog<bool>(
                  context: context,
                  builder: (_) => _MoneyDialog(title: 'Record settlement', split: split, absorb: false),
                );
                if (done ?? false) onChanged();
              },
              child: const Text('Settle'),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () async {
                final done = await showDialog<bool>(
                  context: context,
                  builder: (_) => _MoneyDialog(title: 'Absorb default', split: split, absorb: true),
                );
                if (done ?? false) onChanged();
              },
              child: const Text('Absorb'),
            ),
          ],
        ),
        children: [
          history.when(
            data: (rows) => Column(
              children: [
                for (final t in rows)
                  ListTile(
                    dense: true,
                    title: Text(
                      switch (t.kind) {
                        'split' => 'I paid',
                        'settle' => 'Settled${t.note != null ? ' (${t.note})' : ''}',
                        'absorb' => 'Absorbed default',
                        _ => t.kind,
                      },
                    ),
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

class _SplitDialog extends ConsumerStatefulWidget {
  const _SplitDialog();

  @override
  ConsumerState<_SplitDialog> createState() => _SplitDialogState();
}

class _SplitDialogState extends ConsumerState<_SplitDialog> {
  final _title = TextEditingController();
  final _total = TextEditingController();
  final _mine = TextEditingController();
  final _members = TextEditingController();
  String? _accountId;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _total.dispose();
    _mine.dispose();
    _members.dispose();
    super.dispose();
  }

  void _splitEqually(int n) {
    final total = double.tryParse(_total.text.trim());
    if (total == null || total <= 0 || n < 1) return;
    setState(() => _mine.text = (total / n).toStringAsFixed(2));
  }

  Future<void> _save(List<Account> accounts) async {
    final total = double.tryParse(_total.text.trim());
    final mine = double.tryParse(_mine.text.trim());
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Enter a title');
      return;
    }
    if (total == null || mine == null) {
      setState(() => _error = 'Enter total paid and my share');
      return;
    }
    final err = validateSplit(total: total, myShare: mine);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref.read(splitRepositoryProvider).create(
            title: _title.text,
            total: total,
            myShare: mine,
            members: _members.text.split(RegExp(r'[,，]')),
            accountId: _accountId,
          );
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
      title: const Text('New split'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title (e.g. Dinner)')),
            TextField(
              controller: _total,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Total I paid', prefixText: '₹ '),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _mine,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'My share', prefixText: '₹ '),
              onChanged: (_) => setState(() {}),
            ),
            Row(
              children: [
                const Text('Split equally: '),
                for (final n in [2, 3, 4, 5, 10])
                  TextButton(onPressed: () => _splitEqually(n), child: Text('/$n')),
              ],
            ),
            TextField(
              controller: _members,
              decoration: const InputDecoration(
                labelText: 'Others (optional, comma separated)',
                hintText: 'Ravi, Asha',
              ),
            ),
            accounts.maybeWhen(
              data: (list) => list.isEmpty
                  ? const SizedBox.shrink()
                  : DropdownButtonFormField<String>(
                      initialValue: _accountId ??= list.first.id,
                      decoration: const InputDecoration(labelText: 'Paid from'),
                      items: [for (final a in list) DropdownMenuItem(value: a.id, child: Text(a.name))],
                      onChanged: (v) => setState(() => _accountId = v),
                    ),
              orElse: () => const SizedBox.shrink(),
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

class _MoneyDialog extends ConsumerStatefulWidget {
  final String title;
  final Split split;
  final bool absorb;
  const _MoneyDialog({required this.title, required this.split, required this.absorb});

  @override
  ConsumerState<_MoneyDialog> createState() => _MoneyDialogState();
}

class _MoneyDialogState extends ConsumerState<_MoneyDialog> {
  final _amount = TextEditingController();
  final _who = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _who.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = splitRemaining(
      widget.split.totalPaid,
      widget.split.myShare,
      widget.split.received,
      widget.split.absorbed,
    );
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('₹${left.toStringAsFixed(0)} outstanding on “${widget.split.title}”'),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
          ),
          if (!widget.absorb)
            TextField(controller: _who, decoration: const InputDecoration(labelText: 'From whom (optional)')),
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
              final repo = ref.read(splitRepositoryProvider);
              if (widget.absorb) {
                await repo.absorb(splitId: widget.split.id, amount: amount);
              } else {
                await repo.settle(splitId: widget.split.id, amount: amount, who: _who.text);
              }
              if (context.mounted) Navigator.of(context).pop(true);
            } on Object catch (e) {
              setState(
                () => _error = e
                    .toString()
                    .replaceFirst('Invalid argument(s): ', '')
                    .replaceFirst('Bad state: ', ''),
              );
            }
          },
          child: const Text('Record'),
        ),
      ],
    );
  }
}
