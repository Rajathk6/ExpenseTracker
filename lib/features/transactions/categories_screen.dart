/// Category shortcuts: the buttons that appear under the category field.
///
/// They are only shortcuts. Renaming or removing one never rewrites a
/// transaction — the category text on each entry is the owner's record.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../core/providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<void> _editor(
    BuildContext context,
    WidgetRef ref, {
    Category? existing,
  }) async {
    final name = TextEditingController(text: existing?.name ?? '');
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(existing == null ? 'New category' : 'Rename category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Category name',
                  hintText: 'food junk gobi-65',
                  border: OutlineInputBorder(),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  final repo = ref.read(categoryRepositoryProvider);
                  if (existing == null) {
                    await repo.create(name.text);
                  } else {
                    await repo.rename(existing.id, name.text);
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                } on Object catch (e) {
                  setDialog(
                    () => error = e
                        .toString()
                        .replaceFirst('Bad state: ', '')
                        .replaceFirst('Invalid argument(s): ', ''),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    if (saved ?? false) ref.invalidate(categoriesProvider);
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove "${category.name}"?'),
        content: const Text(
          'This removes the button only. Entries that already use this category keep it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (yes ?? false) {
      await ref.read(categoryRepositoryProvider).remove(category.id);
      ref.invalidate(categoriesProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New category'),
      ),
      body: categories.when(
        data: (list) {
          if (list.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No categories yet. Create the ones you use often — they become '
                'small buttons under the category field in Add.',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Tap a button in Add to fill the category. These never change past entries.',
                ),
              ),
              for (final c in list)
                Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: const Icon(Icons.label_outline),
                    title: Text(c.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Rename',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editor(context, ref, existing: c),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _remove(context, ref, c),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load categories: $e')),
      ),
    );
  }
}
