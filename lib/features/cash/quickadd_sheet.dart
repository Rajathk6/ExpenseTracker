/// Quick-add sheet: 2-tap cash spend (amount chip + category), confirm, done.
/// The home-screen widget / quick tile opens this sheet on the dev-machine
/// build (native wiring in PROGRESS); the sheet itself is fully offline.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../core/ledger.dart';
import '../../core/providers.dart';
import '../transactions/entry_logic.dart';

const _quickSpendAmounts = [50.0, 100.0, 200.0, 500.0, 1000.0];

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  double? _picked;
  final _category = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _category.dispose();
    super.dispose();
  }

  /// Cash-first account: first cash-kind wallet, else the first account.
  Account? _cashAccount(List<Account> accounts) {
    if (accounts.isEmpty) return null;
    for (final a in accounts) {
      if (a.kind.toLowerCase().contains('cash')) return a;
    }
    return accounts.first;
  }

  Future<void> _save(List<Account> accounts) async {
    final draft = EntryDraft(
      kind: 'out',
      amountText: _picked == null ? '' : _picked!.toStringAsFixed(0),
      categoryRaw: _category.text,
      accountId: _cashAccount(accounts)?.id,
      dateTime: DateTime.now(),
    );
    final err = validateEntry(draft, hasAccounts: accounts.isNotEmpty);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final entry = spend(draft.amount!);
      await ref.read(transactionRepositoryProvider).add(
            kind: 'out',
            actual: entry.actual,
            budgetImpact: entry.budgetImpact,
            dateTime: DateTime.now(),
            categoryRaw: draft.categoryRaw,
            note: 'via quick-add',
            accountId: draft.accountId,
          );
      ref
        ..invalidate(recentTransactionsProvider)
        ..invalidate(categoryHistoryProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final history = ref.watch(categoryHistoryProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quick cash spend', style: Theme.of(context).textTheme.titleMedium),
            accounts.maybeWhen(
              data: (l) => Text(
                _cashAccount(l) == null ? 'No accounts yet.' : 'From ${_cashAccount(l)!.name} · now',
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final q in _quickSpendAmounts)
                  ChoiceChip(
                    label: Text('₹${q.toStringAsFixed(0)}'),
                    selected: _picked == q,
                    onSelected: (_) => setState(() => _picked = q),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _category,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'food chai cutting',
                border: OutlineInputBorder(),
              ),
            ),
            history.maybeWhen(
              data: (cats) {
                final q = _category.text.trim().toLowerCase();
                final matches = cats.where((c) => q.isEmpty ? true : c.toLowerCase().contains(q)).take(4).toList();
                if (matches.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final m in matches)
                        ActionChip(label: Text(m), onPressed: () => setState(() => _category.text = m)),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () => _save(accounts.maybeWhen(data: (l) => l, orElse: () => const <Account>[])),
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Opens the quick-add confirm sheet. The home widget / quick tile calls
/// this after the native wiring lands (see PROGRESS Phase 9 notes).
Future<bool> openQuickAdd(BuildContext context) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const QuickAddSheet(),
  );
  return saved ?? false;
}
