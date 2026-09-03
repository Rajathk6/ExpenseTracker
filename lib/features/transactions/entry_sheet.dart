/// Bottom-sheet form for a single In/Out entry.
/// Renders [EntryDraft] + [validateEntry]; persistence goes through
/// TransactionRepository with dual amounts from ledger.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../core/ledger.dart';
import '../../core/providers.dart';
import 'entry_logic.dart';

final _whenFmt = DateFormat('d MMM yyyy, h:mm a');

class EntrySheet extends ConsumerStatefulWidget {
  const EntrySheet({super.key});

  @override
  ConsumerState<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<EntrySheet> {
  String _kind = 'out';
  final _amount = TextEditingController();
  final _category = TextEditingController();
  final _note = TextEditingController();
  String? _accountId;
  DateTime _when = DateTime.now();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _category.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_when));
    if (!mounted) return;
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time?.hour ?? _when.hour, time?.minute ?? _when.minute);
    });
  }

  Future<void> _save(List<Account> accounts) async {
    final draft = EntryDraft(
      kind: _kind,
      amountText: _amount.text,
      categoryRaw: _category.text,
      accountId: _accountId,
      dateTime: _when,
      note: _note.text.trim(),
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
      final amount = draft.amount!;
      final entry = _kind == 'out' ? spend(amount) : income(amount);
      await ref.read(transactionRepositoryProvider).add(
            kind: _kind,
            actual: entry.actual,
            budgetImpact: entry.budgetImpact,
            dateTime: _when,
            categoryRaw: draft.categoryRaw,
            note: draft.note.isEmpty ? null : draft.note,
            accountId: _accountId,
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
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'out', label: Text('Out'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: 'in', label: Text('In'), icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _category,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'food junk gobi-65',
                helperText: 'space = level, - continues item',
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
            const SizedBox(height: 12),
            accounts.when(
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();
                _accountId ??= list.first.id;
                return DropdownButtonFormField<String>(
                  initialValue: _accountId,
                  decoration: const InputDecoration(labelText: 'Source account', border: OutlineInputBorder()),
                  items: [for (final a in list) DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.kind})'))],
                  onChanged: (v) => setState(() => _accountId = v),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Accounts unavailable: $e'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text(_whenFmt.format(_when))),
                TextButton.icon(
                  onPressed: _pickWhen,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Change'),
                ),
              ],
            ),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
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
