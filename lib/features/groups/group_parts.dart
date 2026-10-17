/// Group card + "new group / join with a code" dialog for the Shared screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../core/months.dart';
import '../../core/providers.dart';
import 'group_detail_screen.dart';

class GroupCard extends ConsumerWidget {
  final Group group;
  const GroupCard({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(groupBalancesProvider(group.id));
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        title: Text(group.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${monthLabel(group.monthKey)} · code ${group.code}'
              '${group.status != 'open' ? ' · closed' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            balances.maybeWhen(
              data: (b) => b == null
                  ? const SizedBox.shrink()
                  : Text(
                      'spent ₹${b.totalSpent.round()} · ${b.balances.where((x) => x.owes).length} owe, '
                      '${b.balances.where((x) => x.isOwed).length} are owed',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id)),
        ),
      ),
    );
  }
}

/// New group, or join an existing one by its code.
class GroupDialog extends ConsumerStatefulWidget {
  const GroupDialog({super.key});

  @override
  ConsumerState<GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends ConsumerState<GroupDialog> {
  final _name = TextEditingController();
  final _people = TextEditingController();
  final _code = TextEditingController();
  final _note = TextEditingController();
  late final _month = TextEditingController(text: monthKey(DateTime.now()));
  String _mode = 'new';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _people.dispose();
    _code.dispose();
    _note.dispose();
    _month.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final people = _people.text.split(RegExp(r'[,،]'));
    try {
      final repo = ref.read(groupRepositoryProvider);
      if (_mode == 'new') {
        await repo.create(
          name: _name.text,
          monthKey: _month.text.trim(),
          people: people,
          note: _note.text,
        );
      } else {
        if (_code.text.trim().isEmpty) {
          setState(() => _error = 'Type the code someone shared with you');
          return;
        }
        await repo.join(code: _code.text, people: people, name: _name.text, monthKey: _month.text.trim());
      }
      ref.invalidate(groupsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      setState(() => _error = e.toString().replaceFirst('Invalid argument(s): ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Groups'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'new', label: Text('New group')),
                ButtonSegment(value: 'join', label: Text('Join with code')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() {
                _mode = s.first;
                _error = null;
              }),
            ),
            const SizedBox(height: 12),
            if (_mode == 'new') ...[
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Group name', hintText: 'Flat · October', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _month,
                decoration: const InputDecoration(labelText: 'Month (YYYY-MM)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _people,
                decoration: const InputDecoration(
                  labelText: 'People (names, comma separated)',
                  hintText: 'Me, Ravi, Asha',
                  helperText: 'Names are required — balances need names to mean anything',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _code,
                decoration: const InputDecoration(
                  labelText: 'Code (optional — one is generated)',
                  hintText: 'ET-4KQ2',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              TextField(
                controller: _code,
                decoration: const InputDecoration(labelText: 'The code they shared', hintText: 'ET-4KQ2', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _people,
                decoration: const InputDecoration(
                  labelText: 'Anyone to add on this phone',
                  hintText: 'Ravi, Asha',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Same code, same group. Entries live on this phone until a sync service exists.',
                style: TextStyle(fontSize: 12),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: Text(_mode == 'new' ? 'Create group' : 'Join group')),
      ],
    );
  }
}
