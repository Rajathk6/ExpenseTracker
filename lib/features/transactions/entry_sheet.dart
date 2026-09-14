/// Entry form for a single In/Out row — used for both Add and Edit.
/// Renders [EntryDraft] + [validateEntry]; persistence goes through
/// TransactionRepository with dual amounts from ledger.dart.
/// Linked rows (debts/splits/transfers) never reach here — the list screen
/// routes those to their own screens.
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
  /// Null = Add mode. Set = Edit mode (must be an unlinked row).
  final Transaction? existing;
  const EntrySheet({super.key, this.existing});

  @override
  ConsumerState<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<EntrySheet> {
  late String _kind;
  late final TextEditingController _amount;
  late final TextEditingController _category;
  late final TextEditingController _note;
  String? _accountId;
  String? _bucket;
  late DateTime _when;
  String? _error;
  bool _saving = false;
  bool _accountSeeded = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _kind = e?.kind == 'in' ? 'in' : 'out';
    _amount = TextEditingController(text: e == null ? '' : e.actual.abs().toStringAsFixed(e.actual.truncateToDouble() == e.actual ? 0 : 2));
    _category = TextEditingController(text: e?.categoryRaw ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _accountId = e?.accountId;
    _bucket = e?.bucket;
    _when = e?.occurredAt ?? DateTime.now();
    _accountSeeded = e != null;
  }

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
      final repo = ref.read(transactionRepositoryProvider);
      final bucket = (_bucket ?? '').trim().isEmpty ? null : _bucket!.trim();
      if (widget.existing == null) {
        await repo.add(
          kind: _kind,
          actual: entry.actual,
          budgetImpact: entry.budgetImpact,
          dateTime: _when,
          categoryRaw: draft.categoryRaw,
          bucket: bucket,
          note: draft.note.isEmpty ? null : draft.note,
          accountId: _accountId,
        );
      } else {
        await repo.update(
          id: widget.existing!.id,
          kind: _kind,
          actual: entry.actual,
          budgetImpact: entry.budgetImpact,
          dateTime: _when,
          categoryRaw: draft.categoryRaw,
          bucket: bucket,
          note: draft.note.isEmpty ? null : draft.note,
          accountId: _accountId,
        );
      }
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

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text('Gone for good — use Reverse from duplicates if you want a paper trail.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep')),
          FilledButton.tonal(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (!(yes ?? false)) return;
    try {
      await ref.read(transactionRepositoryProvider).remove(existing.id);
      ref.invalidate(recentTransactionsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    // Seed the default account exactly once, outside the dropdown builder,
    // so typing elsewhere never rebuilds/reseeds the menu (dropdown glitch).
    accounts.maybeWhen(
      data: (list) {
        if (!_accountSeeded && list.isNotEmpty) {
          _accountSeeded = true;
          final ids = {for (final a in list) a.id};
          if (_accountId == null || !ids.contains(_accountId)) {
            _accountId = list.first.id;
          }
        }
      },
      orElse: () {},
    );
    final bucketNames = ref.watch(_bucketOptionsProvider);
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'Edit entry' : 'Add entry',
                style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center,),
            const SizedBox(height: 8),
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
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'food junk gobi-65',
                helperText: 'space = level, - continues item',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            bucketNames.maybeWhen(
              data: (names) => DropdownButtonFormField<String>(
                initialValue: (_bucket ?? '').isEmpty ? null : _bucket,
                decoration: const InputDecoration(labelText: 'Bucket (need / want / invest…)', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: '', child: Text('— none —')),
                  for (final n in names) DropdownMenuItem(value: n, child: Text(n)),
                ],
                onChanged: (v) => setState(() => _bucket = (v ?? '').isEmpty ? null : v),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            accounts.when(
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();
                return DropdownButtonFormField<String>(
                  key: ValueKey('acct-${list.map((a) => a.id).join(',')}'),
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
              child: Text(_saving ? 'Saving…' : (isEdit ? 'Save changes' : 'Save')),
            ),
            if (isEdit)
              TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete entry'),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Bucket options: this month's effective budget buckets, else the default
/// trio so every entry can still be tagged need/want/invest.
final _bucketOptionsProvider = FutureProvider<List<String>>((ref) async {
  final now = DateTime.now();
  final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final b = await ref.watch(budgetRepositoryProvider).getEffective(key);
  if (b != null && b.buckets.isNotEmpty) return [for (final x in b.buckets) x.name];
  return const ['need', 'want', 'invest'];
});
