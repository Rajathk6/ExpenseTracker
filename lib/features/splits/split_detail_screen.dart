/// One split in full: the share code, who is in it, the money trail and the
/// settle / absorb actions. Reached from the Shared-money screen's Splits tab.
library;

import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../core/providers.dart';
import '../shared/shared_parts.dart';
import '../splits/split_logic.dart';

final _dayFmt = DateFormat('d MMM yyyy');

class SplitDetailScreen extends ConsumerWidget {
  final String splitId;
  final VoidCallback onChanged;
  const SplitDetailScreen({super.key, required this.splitId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(splitHistoryProvider(splitId));
    final split = ref.watch(splitByIdProvider(splitId));
    return Scaffold(
      appBar: AppBar(title: Text(split.maybeWhen(data: (s) => s?.title ?? 'Split', orElse: () => 'Split'))),
      body: split.when(
        data: (s) => s == null
            ? const Center(child: Text('This split is gone.'))
            : _body(context, ref, s, history),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, Split s, AsyncValue<List<Transaction>> history) {
    final repo = ref.read(splitRepositoryProvider);
    final left = splitRemaining(s.totalPaid, s.myShare, s.received, s.absorbed);
    final people = repo.membersOf(s);
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.title, style: theme.textTheme.titleMedium),
                    Chip(
                      avatar: const Icon(Icons.tag, size: 18),
                      label: Text(s.code ?? 'no code'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Figure('You paid', '₹${s.totalPaid.round()}'),
                    _Figure('Your share', '₹${s.myShare.round()}'),
                    _Figure('Back', '₹${s.received.round()}'),
                    _Figure('Left', '₹${left.round()}'),
                  ],
                ),
                const SizedBox(height: 10),
                if (s.absorbed > 0)
                  Text('₹${s.absorbed.round()} absorbed as your own expense', style: theme.textTheme.bodySmall),
                if (s.status == 'open') ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          final done = await showDialog<bool>(
                            context: context,
                            builder: (_) => MoneyDialog(title: 'Record settlement', split: s, absorb: false),
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
                            builder: (_) => MoneyDialog(title: 'Absorb default', split: s, absorb: true),
                          );
                          if (done ?? false) onChanged();
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Absorb'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Who is in it ({people.length})', style: theme.textTheme.titleSmall),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [for (final p in people) Chip(avatar: const Icon(Icons.person_outline, size: 18), label: Text(p))],
        ),
        if (people.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('No names recorded on this older split.', style: theme.textTheme.bodySmall),
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
                    'split' => Icons.receipt_long_outlined,
                    'settle' => Icons.south_west,
                    'absorb' => Icons.check_circle_outline,
                    _ => Icons.circle_outlined,
                  },),
                  title: Text(switch (t.kind) {
                    'split' => 'You paid the whole bill',
                    'settle' => 'Settled back',
                    'absorb' => 'Absorbed as your expense',
                    _ => t.kind,
                  },),
                  subtitle: Text(
                    '${_dayFmt.format(t.occurredAt)}${t.note != null && t.note!.isNotEmpty ? ' · ${t.note}' : ''}',
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
