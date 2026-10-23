/// Shared money — one place for everything that is not a plain expense
/// (#12: lending and splits were separate screens and nobody looked at both).
///
/// Four tabs:
/// - **Lent** and **Borrowed** — each with its own open list and its own
///   settled list (#11: no more third "Settlements" tab, a settled contract
///   belongs under the direction it was in);
/// - **Splits** — group expenses the owner fronted, with a share code;
/// - **Groups** — Splitwise-style groups (#9): name, month, people, code,
///   expenses and pay-ups, with settle-up in whole rupees.
library;

import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/months.dart';
import '../../core/providers.dart';
import '../splits/split_detail_screen.dart';
import '../groups/group_parts.dart';
import '../groups/group_sync.dart';
import 'shared_logic.dart';
import 'shared_parts.dart';

class SharedScreen extends ConsumerStatefulWidget {
  const SharedScreen({super.key});

  @override
  ConsumerState<SharedScreen> createState() => _SharedScreenState();
}

class _SharedScreenState extends ConsumerState<SharedScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refresh(WidgetRef ref) {
    ref
      ..invalidate(allDebtsProvider)
      ..invalidate(openDebtsProvider)
      ..invalidate(openSplitsProvider)
      ..invalidate(allSplitsProvider)
      ..invalidate(groupsProvider)
      ..invalidate(groupBalancesProvider)
      ..invalidate(budgetStatusProvider(monthKey(DateTime.now())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared money'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Lent'),
            Tab(text: 'Borrowed'),
            Tab(text: 'Splits'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _DebtList(direction: 'lent', onChanged: () => _refresh(ref)),
          _DebtList(direction: 'borrowed', onChanged: () => _refresh(ref)),
          _SplitsTab(onChanged: () => _refresh(ref)),
          const _GroupsTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (context, _) {
          if (_tabs.index == 3) {
            return FloatingActionButton.extended(
              onPressed: () async {
                final created = await showDialog<bool>(context: context, builder: (_) => const GroupDialog());
                if (created ?? false) _refresh(ref);
              },
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('New group'),
            );
          }
          if (_tabs.index == 2) {
            return FloatingActionButton.extended(
              onPressed: () async {
                final created = await showDialog<bool>(context: context, builder: (_) => const SplitDialog());
                if (created ?? false) _refresh(ref);
              },
              icon: const Icon(Icons.add),
              label: const Text('New split'),
            );
          }
          return FloatingActionButton.extended(
            onPressed: () async {
              final created = await showDialog<bool>(
                context: context,
                builder: (_) => DebtDialog(direction: _tabs.index == 0 ? 'lent' : 'borrowed'),
              );
              if (created ?? false) _refresh(ref);
            },
            icon: const Icon(Icons.add),
            label: Text(_tabs.index == 0 ? 'Lend' : 'Borrow'),
          );
        },
      ),
    );
  }
}

/// Lent or Borrowed, each with Open and Settled sections. Settlements are not
/// a separate tab: a payoff belongs to the contract it closes.
class _DebtList extends ConsumerWidget {
  final String direction;
  final VoidCallback onChanged;
  const _DebtList({required this.direction, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allDebtsProvider);
    return all.when(
      data: (debts) {
        final mine = [for (final d in debts) if (d.direction == direction) d];
        final open = [for (final d in mine) if (d.status == 'open') d]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final settled = [for (final d in mine) if (d.status != 'open') d]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final owed = sharedDebtTotals(mine);
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat('Open', '${open.length}'),
                    _Stat(direction == 'lent' ? 'Still with them' : 'Still yours', '₹${owed.round()}'),
                    _Stat('Settled', '${settled.length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Open', style: Theme.of(context).textTheme.titleSmall),
            if (open.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  direction == 'lent'
                      ? 'Nothing lent out. Tap "Lend" when you hand over cash.'
                      : 'Nothing borrowed. Tap "Borrow" when you take cash from someone.',
                ),
              ),
            for (final d in open)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DebtCard(debt: d, onChanged: onChanged),
              ),
            const SizedBox(height: 12),
            Text('Settled', style: Theme.of(context).textTheme.titleSmall),
            if (settled.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Nothing settled yet.')),
            for (final d in settled)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text(d.counterparty),
                subtitle: Text(
                  '${direction == 'lent' ? 'Lent' : 'Borrowed'} ₹${d.principal.round()} · back ₹${d.paid.round()}'
                  '${d.note != null && d.note!.isNotEmpty ? ' · ${d.note}' : ''}',
                ),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => Padding(
                    padding: EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 12,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                    ),
                    child: SingleChildScrollView(child: DebtCard(debt: d, onChanged: onChanged)),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load: $e')),
    );
  }
}

class _SplitsTab extends ConsumerWidget {
  final VoidCallback onChanged;
  const _SplitsTab({required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allSplitsProvider);
    return all.when(
      data: (splits) {
        final open = [for (final s in splits) if (s.status == 'open') s]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final closed = [for (final s in splits) if (s.status != 'open') s]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final outstanding = splitOutstandingTotal(open);
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat('Open', '${open.length}'),
                    _Stat('Coming back', '₹${outstanding.round()}'),
                    _Stat('Closed', '${closed.length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Open', style: Theme.of(context).textTheme.titleSmall),
            if (open.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No open splits.')),
            for (final s in open)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SplitCard(split: s, onChanged: onChanged),
              ),
            const SizedBox(height: 12),
            Text('Closed', style: Theme.of(context).textTheme.titleSmall),
            for (final s in closed)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text(s.title),
                subtitle: Text(
                  '${s.code ?? 'no code'} · paid ₹${s.totalPaid.round()}'
                  '${s.absorbed > 0 ? ' · absorbed ₹${s.absorbed.round()}' : ''}',
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SplitDetailScreen(splitId: s.id, onChanged: onChanged)),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load: $e')),
    );
  }
}

class _GroupsTab extends ConsumerWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(groupSyncWatcherProvider);
    final groups = ref.watch(groupsProvider);
    return groups.when(
      data: (list) {
        if (list.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            children: const [
              _GroupsSyncBar(),
              SizedBox(height: 8),
              Text(
                'Groups are for a set of people and a period — a flat, a trip, a monthly '
                'shopping run. Give the group a name, add everyone (names are required), '
                'and share the code so the others can join the same group. If another '
                'phone already synced a group, tap Sync now to pull it in. Group sync '
                'uses Firebase anonymously — no email or Google account.',
              ),
            ],
          );
        }
        final open = [for (final g in list) if (g.status == 'open') g];
        final closed = [for (final g in list) if (g.status != 'open') g];
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          children: [
            const _GroupsSyncBar(),
            const SizedBox(height: 8),
            if (open.isNotEmpty) ...[
              Text('Open', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final g in open) GroupCard(group: g),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No open groups. Tap "New group" to start one.'),
              ),
            // Closed groups live in their own section — and the section only
            // appears once there is one.
            if (closed.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Closed', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final g in closed) GroupCard(group: g),
            ],
            const SizedBox(height: 8),
            const Text(
              'Joining by code pulls the creator\'s synced group from Firebase. Anonymous '
              'sync needs no email; anyone you give the code to can join.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load: $e')),
    );
  }
}

class _GroupsSyncBar extends ConsumerStatefulWidget {
  const _GroupsSyncBar();

  @override
  ConsumerState<_GroupsSyncBar> createState() => _GroupsSyncBarState();
}

class _GroupsSyncBarState extends ConsumerState<_GroupsSyncBar> {
  bool _busy = false;
  String? _status;

  Future<void> _sync() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref.read(groupSyncServiceProvider).sync();
      ref
        ..invalidate(groupsProvider)
        ..invalidate(groupBalancesProvider)
        ..invalidate(groupSyncUidProvider);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = result.errors.isEmpty
            ? 'Synced ${result.localGroups} groups — pulled ${result.pulled}, pushed ${result.pushed}.'
            : 'Pulled ${result.pulled}, pushed ${result.pushed}; ${result.errors.length} group(s) failed: '
                '${result.errors.take(2).join(' | ')}';
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = groupSyncErrorMessage(e);
      });
      messenger.showSnackBar(SnackBar(content: Text('Group sync failed: ${groupSyncErrorMessage(e)}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(groupSyncServiceProvider);
    final uid = ref.watch(groupSyncUidProvider).valueOrNull;
    final theme = Theme.of(context);
    final shortUid = uid == null || uid.length < 8 ? null : uid.substring(0, 8);
    final error = service.lastError;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Group sync', style: theme.textTheme.titleSmall),
                      Text(
                        !service.enabled
                            ? 'Off in the demo vault.'
                            : error != null
                                ? 'Sync paused: $error'
                                : shortUid == null
                                    ? 'Connecting anonymously — no email or Google account.'
                                    : 'On · anonymous id $shortUid…',
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _busy || !service.enabled ? null : _sync,
                  icon: _busy
                      ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync),
                  label: const Text('Sync now'),
                ),
              ],
            ),
            if (_status != null) ...[
              const SizedBox(height: 6),
              Text(_status!, style: theme.textTheme.bodySmall),
            ],
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
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}