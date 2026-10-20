/// Cards and dialogs shared by the merged Shared-money screen, moved out of the
/// old Debts and Splits screens so neither feature loses its behaviour (aging,
/// nudges, partial payoffs, absorbs) while living in one place.
library;

import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../core/owner_profile.dart';
import '../../core/share_out.dart';
import '../../core/providers.dart';
import '../splits/split_detail_screen.dart';
import '../neutral/debt_logic.dart';
import '../splits/split_logic.dart';

final _dayFmt = DateFormat('d MMM yyyy');

/// One lend/borrow contract, everything on the card: the amount, what has
/// come back, how old it is, the money trail and the payoff button. There is
/// no separate screen to open — the card *is* the contract (#9).
class DebtCard extends ConsumerWidget {
  final Debt debt;
  final VoidCallback onChanged;
  const DebtCard({super.key, required this.debt, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final left = remaining(debt.principal, debt.paid);
    final ratio = debt.principal <= 0 ? 1.0 : (debt.paid / debt.principal).clamp(0.0, 1.0);
    final age = agingDays(debt.createdAt, now);
    final overdue = isOverdue(dueDate: debt.dueDate, status: debt.status, now: now);
    final nudge = nudgeDue(nudgeDate: debt.nudgeDate, status: debt.status, now: now);
    final history = ref.watch(debtHistoryProvider(debt.id));
    final theme = Theme.of(context);
    final lent = debt.direction == 'lent';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${lent ? 'Lent to' : 'Borrowed from'} ${debt.counterparty}',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${debt.principal.round()} · back ₹${debt.paid.round()} · ₹${left.round()} left'
                        ' · $age day${age == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (debt.status == 'open')
                  FilledButton.icon(
                    onPressed: () async {
                      final done = await showDialog<bool>(
                        context: context,
                        builder: (_) => PayoffDialog(debt: debt),
                      );
                      if (done ?? false) onChanged();
                    },
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Pay back'),
                  )
                else
                  const Chip(
                    avatar: Icon(Icons.check_circle_outline, size: 18),
                    label: Text('Settled'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                color: lent ? Colors.teal : Colors.orange,
              ),
            ),
            if (overdue)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Overdue since ${_dayFmt.format(debt.dueDate!)}', style: const TextStyle(color: Colors.red)),
              ),
            if (nudge && !overdue)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Nudge due — time for a reminder', style: TextStyle(color: Colors.orange)),
              ),
            if (debt.note != null && debt.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(debt.note!, style: theme.textTheme.bodySmall),
              ),
            // --- The money trail, right here (#8) ---
            const SizedBox(height: 10),
            Text('Money trail', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
            history.when(
              data: (rows) => Column(
                children: [
                  for (final t in rows)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        switch (t.kind) {
                          'lend' || 'borrow' => Icons.arrow_outward,
                          'settle' => Icons.south_west,
                          _ => Icons.circle_outlined,
                        },
                        size: 18,
                        color: t.kind == 'settle' ? Colors.green : null,
                      ),
                      title: Text(switch (t.kind) {
                        'lend' => 'Handed over',
                        'borrow' => 'Taken',
                        'settle' => lent ? 'Came back' : 'Paid back',
                        _ => t.kind,
                      },),
                      subtitle: Text(
                        '${_dayFmt.format(t.occurredAt)}'
                        '${t.note != null && t.note!.isNotEmpty ? ' · ${t.note}' : ''}',
                      ),
                      trailing: Text('₹${t.actual.abs().round()}'),
                    ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Could not load: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class DebtDialog extends ConsumerStatefulWidget {
  /// 'lent' or 'borrowed' — the merged screen's FAB passes the active tab so
  /// the dialog can title itself without a second question.
  final String direction;
  const DebtDialog({super.key, this.direction = 'lent'});

  @override
  ConsumerState<DebtDialog> createState() => DebtDialogState();
}

class DebtDialogState extends ConsumerState<DebtDialog> {
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

class PayoffDialog extends ConsumerStatefulWidget {
  final Debt debt;
  const PayoffDialog({super.key, required this.debt});

  @override
  ConsumerState<PayoffDialog> createState() => PayoffDialogState();
}

class PayoffDialogState extends ConsumerState<PayoffDialog> {
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

/// One split, with room to breathe (#14): the share code, how many people it is
/// divided between, progress on what has come back, and the two honest exits
/// (settle / absorb) rather than a crowded trailing row.
class SplitCard extends ConsumerWidget {
  final Split split;
  final VoidCallback onChanged;
  const SplitCard({super.key, required this.split, required this.onChanged});

  /// The share message: what it was for, who is in it, the code, and what is
  /// still to come back. One tap to WhatsApp.
  Future<void> _share(BuildContext context, WidgetRef ref, Split s) async {
    final people = ref.read(splitRepositoryProvider).membersOf(s);
    final left = splitRemaining(s.totalPaid, s.myShare, s.received, s.absorbed);
    final message = [
      'Split: ${s.title}',
      'Code: ${s.code ?? '—'}',
      'I paid ₹${s.totalPaid.round()}, my share ₹${s.myShare.round()}',
      if (people.isNotEmpty) 'In it: ${people.join(', ')}',
      if (left > 0) 'Still to come back: ₹${left.round()}',
    ].join('\n');
    final sent = await shareText(text: message, subject: 'Split · ${s.title}');
    if (!sent && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app to share with on this device')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final left = splitRemaining(split.totalPaid, split.myShare, split.received, split.absorbed);
    final theirs = (split.totalPaid - split.myShare).clamp(0, double.infinity);
    final ratio = theirs <= 0 ? 1.0 : ((split.received + split.absorbed) / theirs).clamp(0.0, 1.0);
    final people = ref.read(splitRepositoryProvider).peopleOf(split);
    final theme = Theme.of(context);
    final history = ref.watch(splitHistoryProvider(split.id));
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(split.title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'You paid ₹${split.totalPaid.round()} · your share ₹${split.myShare.round()} · '
                        '₹${left.round()} still to come back',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Open split',
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SplitDetailScreen(splitId: split.id, onChanged: onChanged)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: ratio, minHeight: 8),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.tag, size: 18),
                  label: Text(split.code ?? 'no code'),
                  tooltip: 'Tap to share this split',
                  onPressed: () => _share(context, ref, split),
                ),
                Chip(
                  avatar: const Icon(Icons.group_outlined, size: 18),
                  label: Text('$people ${people == 1 ? 'person' : 'people'}'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final done = await showDialog<bool>(
                      context: context,
                      builder: (_) => MoneyDialog(title: 'Record settlement', split: split, absorb: false),
                    );
                    if (done ?? false) onChanged();
                  },
                  icon: const Icon(Icons.south_west),
                  label: const Text('Settle'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final done = await showDialog<bool>(
                      context: context,
                      builder: (_) => MoneyDialog(title: 'Absorb default', split: split, absorb: true),
                    );
                    if (done ?? false) onChanged();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Absorb'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            history.when(
              data: (rows) => Column(
                children: [
                  for (final t in rows.take(4))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(switch (t.kind) {
                        'split' => 'You paid',
                        'settle' => 'Settled${t.note != null ? ' (${t.note})' : ''}',
                        'absorb' => 'Absorbed default',
                        _ => t.kind,
                      },),
                      subtitle: Text(_dayFmt.format(t.occurredAt)),
                      trailing: Text('₹${t.actual.abs().round()}'),
                    ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text('Could not load: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class SplitDialog extends ConsumerStatefulWidget {
  const SplitDialog({super.key});

  @override
  ConsumerState<SplitDialog> createState() => SplitDialogState();
}

class SplitDialogState extends ConsumerState<SplitDialog> {
  final _title = TextEditingController();
  final _total = TextEditingController();
  final _people = TextEditingController(text: '2');
  final _members = TextEditingController();
  String? _accountId;
  String? _error;
  bool _saving = false;
  /// Whether the owner name has been filled into the people field yet.
  bool _named = false;

  @override
  void dispose() {
    _title.dispose();
    _total.dispose();
    _people.dispose();
    _members.dispose();
    super.dispose();
  }

  int? get _count => int.tryParse(_people.text.trim());

  /// Live read-out of the division, so nobody has to do it in their head.
  double? get _share {
    final total = double.tryParse(_total.text.trim());
    final count = _count;
    if (total == null || count == null || total <= 0 || count < 1) return null;
    return total / count;
  }

  Future<void> _save() async {
    final total = double.tryParse(_total.text.trim());
    final count = _count;
    final names = _members.text.split(RegExp(r'[,，]'));
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'What was this for?');
      return;
    }
    if (total == null || total <= 0) {
      setState(() => _error = 'Enter what you paid in total');
      return;
    }
    if (count == null || count < 1) {
      setState(() => _error = 'How many people is this split between?');
      return;
    }
    final memberError = validateMembers(names);
    if (memberError != null) {
      setState(() => _error = memberError);
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
            people: count,
            members: names,
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
    final theme = Theme.of(context);
    final share = _share;
    // Put the owner's own name in for them: "Me" is what a split means.
    final owner = ref.watch(ownerDisplayNameProvider).valueOrNull ?? 'Me';
    if (!_named && _members.text.trim().isEmpty) {
      _named = true;
      _members.text = owner;
    }
    return AlertDialog(
      title: const Text('New split'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'What was it for?', hintText: 'Dinner at Zaffran', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _total,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'You paid ₹ (the whole bill)', prefixText: '₹ ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _people,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Split between how many people?',
                helperText: 'Include yourself — the rest is owed to you',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _members,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Who is in it (names, comma separated)',
                hintText: '$owner, Ravi, Asha',
                helperText: 'Names are required — a split nobody can name cannot be settled',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    share == null
                        ? 'Your share appears here'
                        : 'Your share ₹${share.toStringAsFixed(2)} · each pays the same',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                for (final n in const [2, 3, 4, 5, 6])
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _people.text = '$n'),
                      child: Text('$n'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Consumer(
              builder: (context, ref, _) => ref.watch(accountsProvider).maybeWhen(
                    data: (list) => list.isEmpty
                        ? const Text('No accounts yet — add one from Transactions → Accounts.', style: TextStyle(fontSize: 12))
                        : DropdownButtonFormField<String>(
                            initialValue: _accountId ?? list.first.id,
                            decoration: const InputDecoration(labelText: 'Paid from', border: OutlineInputBorder()),
                            items: [for (final a in list) DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.kind})'))],
                            onChanged: (v) => setState(() => _accountId = v),
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save')),
      ],
    );
  }
}

class MoneyDialog extends ConsumerStatefulWidget {
  final String title;
  final Split split;
  final bool absorb;
  const MoneyDialog({super.key, required this.title, required this.split, required this.absorb});

  @override
  ConsumerState<MoneyDialog> createState() => MoneyDialogState();
}

class MoneyDialogState extends ConsumerState<MoneyDialog> {
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
