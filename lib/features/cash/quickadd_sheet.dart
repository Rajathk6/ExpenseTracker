/// Quick-add sheet: 2-tap cash spend (amount chip + category), confirm, done.
/// Opened from the in-app button and from the home-screen tile, which arrives
/// as `homewidget://quickadd?action=quickadd` (see home_tile.dart). Fully
/// offline — the tile needs no background service.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../core/ledger.dart';
import '../../core/providers.dart';
import '../transactions/category_field.dart';
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
      // Suggestions are autoDispose + re-read the DB, so only the list refreshes.
      ref.invalidate(recentTransactionsProvider);
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
            CategoryField(
              controller: _category,
              autofocus: true,
              hintText: 'food chai cutting',
              helperText: 'type a few letters to pick a past one',
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

/// Opens the quick-add confirm sheet. The home-screen tile calls this when
/// `homewidget://quickadd?action=quickadd` launches or reaches the app.
Future<bool> openQuickAdd(BuildContext context) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const QuickAddSheet(),
  );
  return saved ?? false;
}
