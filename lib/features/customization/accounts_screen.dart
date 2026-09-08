/// Accounts manager: every money source/dest lives here.
/// Names are unique; kinds are freeform (suggestions only) per the
/// flexibility rule. Entry forms read this list — no hardcoded sources.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../core/providers.dart';
import '../customization/account_repository.dart' show suggestedAccountKinds;

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  Future<void> _showEditor(BuildContext context, WidgetRef ref, {Account? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final kind = TextEditingController(text: existing?.kind ?? 'cash');
    final opening = TextEditingController(
      text: existing == null ? '' : existing.openingBalance.toStringAsFixed(0),
    );
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(existing == null ? 'Add account' : 'Rename account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name (e.g. SBI-1234, Cash, HDFC-CC)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: kind,
                decoration: const InputDecoration(
                  labelText: 'Kind (freeform)',
                  helperText: 'bank · cash · card · wallet · upi · …',
                ),
              ),
              if (existing == null) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: opening,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Opening balance (optional)'),
                ),
              ],
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: [
                  for (final k in suggestedAccountKinds)
                    ActionChip(label: Text(k), onPressed: () => setDialog(() => kind.text = k)),
                ],
              ),
              if (error != null) Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  final repo = ref.read(accountRepositoryProvider);
                  if (existing == null) {
                    await repo.create(
                      name: name.text,
                      kind: kind.text,
                      openingBalance: double.tryParse(opening.text.trim()) ?? 0,
                    );
                  } else {
                    await repo.rename(existing.id, name.text);
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                } on Object catch (e) {
                  final msg = e
                      .toString()
                      .replaceFirst('Invalid argument(s): ', '')
                      .replaceFirst('Bad state: ', '');
                  setDialog(() => error = msg);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved ?? false) ref.invalidate(accountsProvider);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Account account) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${account.name}?'),
        content: const Text(
          'Past entries keep their history but lose the account link. '
          'Only delete accounts you no longer need.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep')),
          FilledButton.tonal(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes ?? false) {
      await ref.read(accountRepositoryProvider).remove(account.id);
      ref.invalidate(accountsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: accounts.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No accounts yet — tap Add to create your first.'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: Text(list[i].name),
              subtitle: Text('${list[i].kind} · opening ₹${list[i].openingBalance.toStringAsFixed(0)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Rename',
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditor(context, ref, existing: list[i]),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, ref, list[i]),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
      ),
    );
  }
}
