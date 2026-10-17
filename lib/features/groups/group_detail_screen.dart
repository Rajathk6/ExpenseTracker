/// Group detail: the Splitwise-style screen the owner asked for (#9) —
/// people, code, expenses, pay-ups, and the settle-up in whole rupees.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../core/months.dart';
import '../../core/providers.dart';
import 'group_repository.dart';

final _dayFmt = DateFormat('d MMM yyyy');

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(groupBalancesProvider(groupId));
    return Scaffold(
      appBar: AppBar(title: Text(balances.maybeWhen(
        data: (b) => b?.name ?? 'Group',
        orElse: () => 'Group',
      ),),),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _GroupActionSheet(groupId: groupId),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: balances.when(
        data: (b) => b == null ? const Center(child: Text('This group is gone.')) : _body(context, ref, b),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, GroupBalances b) {
    final theme = Theme.of(context);
    final repo = ref.read(groupRepositoryProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(b.name, style: theme.textTheme.titleMedium),
                    Chip(
                      avatar: const Icon(Icons.tag, size: 18),
                      label: Text(b.code),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${monthLabel(b.monthKey)} · spent ₹${b.totalSpent.round()} so far',
                    style: theme.textTheme.bodySmall,),
                const SizedBox(height: 12),
                for (final balance in b.balances)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          balance.isOwed ? Icons.south_west : (balance.owes ? Icons.north_east : Icons.remove),
                          size: 18,
                          color: balance.isOwed
                              ? Colors.green
                              : (balance.owes ? Colors.red : theme.colorScheme.outline),
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text(balance.name)),
                        Text(
                          balance.isOwed
                              ? 'gets ₹${balance.net.round()}'
                              : (balance.owes ? 'owes ₹${(-balance.net).round()}' : 'settled up'),
                          style: TextStyle(
                            color: balance.isOwed
                                ? Colors.green
                                : (balance.owes ? Colors.red : theme.colorScheme.outline),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (b.settleUp.isNotEmpty) ...[
                  const Divider(),
                  Text('To settle up', style: theme.textTheme.titleSmall),
                  for (final move in b.settleUp)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${move.from} pays ${move.to} ₹${move.amount.round()}'),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Expenses',
          child: FutureBuilder<List<GroupExpense>>(
            future: repo.expenses(b.groupId),
            builder: (context, snap) {
              final rows = snap.data ?? const <GroupExpense>[];
              if (rows.isEmpty) return const Text('Nothing spent in this group yet.');
              return Column(
                children: [
                  for (final e in rows)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(e.title),
                      subtitle: Text(
                        '${_dayFmt.format(e.occurredAt)} · ${e.paidBy.isEmpty ? 'split evenly' : 'paid by ${e.paidBy}'}',
                      ),
                      trailing: Text('₹${e.amount.round()}'),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Pay-ups',
          child: FutureBuilder<List<GroupPayment>>(
            future: repo.payments(b.groupId),
            builder: (context, snap) {
              final rows = snap.data ?? const <GroupPayment>[];
              if (rows.isEmpty) return const Text('No pay-ups recorded yet.');
              return Column(
                children: [
                  for (final p in rows)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.handshake_outlined),
                      title: Text('${p.paidBy} → ${p.paidTo}'),
                      subtitle: Text(_dayFmt.format(p.occurredAt)),
                      trailing: Text('₹${p.amount.round()}'),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}

/// Add an expense or record a pay-up.
class _GroupActionSheet extends ConsumerStatefulWidget {
  final String groupId;
  const _GroupActionSheet({required this.groupId});

  @override
  ConsumerState<_GroupActionSheet> createState() => _GroupActionSheetState();
}

class _GroupActionSheetState extends ConsumerState<_GroupActionSheet> {
  final _amount = TextEditingController();
  final _title = TextEditingController();
  String _mode = 'expense';
  String? _who;
  String? _paidTo;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _save(List<String> people) async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    try {
      final repo = ref.read(groupRepositoryProvider);
      if (_mode == 'expense') {
        await repo.addExpense(
          groupId: widget.groupId,
          title: _title.text,
          amount: amount,
          paidBy: _who,
        );
      } else {
        if (_who == null || _paidTo == null) {
          setState(() => _error = 'Who paid, and who paid them?');
          return;
        }
        await repo.addPayment(
          groupId: widget.groupId,
          paidBy: _who!,
          paidTo: _paidTo!,
          amount: amount,
        );
      }
      ref.invalidate(groupBalancesProvider(widget.groupId));
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      setState(() => _error = e.toString().replaceFirst('Invalid argument(s): ', '') );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(groupRepositoryProvider);
    return FutureBuilder<List<GroupMember>>(
      future: repo.people(widget.groupId),
      builder: (context, snap) {
        final people = [for (final m in snap.data ?? const <GroupMember>[]) m.name];
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.receipt_long_outlined)),
                    ButtonSegment(value: 'payup', label: Text('Pay-up'), icon: Icon(Icons.handshake_outlined)),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() {
                    _mode = s.first;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 12),
                if (_mode == 'expense') ...[
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'What was it for?', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount ₹', prefixText: '₹ ', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _who,
                    decoration: const InputDecoration(
                      labelText: 'Who paid? (leave empty to split evenly)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Nobody — split evenly')),
                      for (final p in people) DropdownMenuItem(value: p, child: Text(p)),
                    ],
                    onChanged: (v) => setState(() => _who = v),
                  ),
                ] else ...[
                  TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount ₹', prefixText: '₹ ', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _who,
                    decoration: const InputDecoration(labelText: 'Who paid back?', border: OutlineInputBorder()),
                    items: [for (final p in people) DropdownMenuItem(value: p, child: Text(p))],
                    onChanged: (v) => setState(() => _who = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _paidTo,
                    decoration: const InputDecoration(labelText: 'Paid to whom?', border: OutlineInputBorder()),
                    items: [for (final p in people) DropdownMenuItem(value: p, child: Text(p))],
                    onChanged: (v) => setState(() => _paidTo = v),
                  ),
                  const SizedBox(height: 8),
                  const Text('Recorded once for the group, so everyone sees the same pay-up.',
                      style: TextStyle(fontSize: 12),),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: people.isEmpty ? null : () => _save(people),
                  child: Text(_mode == 'expense' ? 'Add expense' : 'Record pay-up'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}