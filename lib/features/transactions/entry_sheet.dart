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
import '../../core/months.dart';
import '../../core/providers.dart';
import '../budgets/bucket_math.dart';
import 'category_field.dart';
import 'entry_logic.dart';

/// What this entry *is*, beyond in/out. Owner rule 2026-09-27: a payment with a
/// person's name on it should become a lend/borrow/settlement of that
/// contract, not a note somebody has to read later.
enum EntryRole {
  normal('Normal entry'),
  lend('Lend to person'),
  borrow('Borrow from person'),
  settle('Settle / pay back');

  const EntryRole(this.label);
  final String label;
}

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
  EntryRole _role = EntryRole.normal;
  final _person = TextEditingController();

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
    _person.dispose();
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
      final person = _person.text.trim();
      // A person only means something for a lend/borrow/settle. Anything else
      // is a normal entry — silently dropping it used to lose the entry while
      // the sheet reported success.
      if (person.isNotEmpty && _role != EntryRole.normal) {
        await _saveThroughPerson(amount, person, bucket);
        return;
      }
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

  /// Lend / borrow / settle with a named person. All three go through
  /// DebtRepository so the contract, the partials and the neutral ledger stay
  /// consistent — a front-screen entry must never invent its own contract.
  Future<void> _saveThroughPerson(double amount, String person, String? bucket) async {
    final debts = ref.read(debtRepositoryProvider);
    final note = _note.text.trim();
    final at = _when;
    final accountId = _accountId;
    try {
      switch (_role) {
        case EntryRole.lend:
          await debts.lend(
            counterparty: person,
            principal: amount,
            accountId: accountId,
            at: at,
            note: note.isEmpty ? null : note,
          );
        case EntryRole.borrow:
          await debts.borrow(
            counterparty: person,
            principal: amount,
            accountId: accountId,
            at: at,
            note: note.isEmpty ? null : note,
          );
        case EntryRole.settle:
          // Pay back / collect back from an existing contract of theirs.
          final open = (await debts.all()).where(
            (d) =>
                d.counterparty.toLowerCase() == person.toLowerCase() &&
                d.status == 'open' &&
                (d.principal - d.paid) > 0.005,
          );
          if (open.isEmpty) {
            throw ArgumentError('No open contract with $person — record a lend/borrow first');
          }
          // All-or-nothing: check what is due *before* writing anything, so a
          // half-finished settlement can never be left behind.
          final due = open.fold<double>(0, (s, d) => s + (d.principal - d.paid));
          if (amount > due + 0.005) {
            throw ArgumentError('Only ₹${due.round()} is due with $person right now');
          }
          var left = amount;
          for (final d in open) {
            if (left <= 0.005) break;
            final chunk = left > (d.principal - d.paid) ? d.principal - d.paid : left;
            await debts.pay(debtId: d.id, amount: chunk, accountId: accountId, at: at, note: note.isEmpty ? null : note);
            left -= chunk;
          }
        case EntryRole.normal:
          break;
      }
      ref
        ..invalidate(recentTransactionsProvider)
        ..invalidate(openDebtsProvider)
        ..invalidate(allDebtsProvider)
          ..invalidate(unabsorbedNeutralProvider)
        ..invalidate(budgetStatusProvider(monthKey(_when)))
        ..invalidate(monthSummaryProvider(monthKey(_when)));
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString()
              .replaceFirst('Invalid argument(s): ', '')
              .replaceFirst('Bad state: ', '');
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
            DropdownButtonFormField<EntryRole>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'This entry is a…', border: OutlineInputBorder()),
              items: [
                for (final r in EntryRole.values) DropdownMenuItem(value: r, child: Text(r.label)),
              ],
              onChanged: (v) => setState(() => _role = v ?? EntryRole.normal),
            ),
            if (_role != EntryRole.normal) ...[
              const SizedBox(height: 8),
              PersonField(
                controller: _person,
                role: _role,
                hint: switch (_role) {
                  EntryRole.lend => 'Who are you lending to?',
                  EntryRole.borrow => 'Who are you borrowing from?',
                  EntryRole.settle => 'Who are you settling with?',
                  EntryRole.normal => '',
                },
              ),
            ],
            const SizedBox(height: 12),
            CategoryField(
              controller: _category,
              hintText: 'food junk gobi-65',
              helperText: 'type a few letters to pick a past one · space = level, - continues item',
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

/// Person picker over everyone the owner has ever dealt with. Offers one tap
/// for a known name instead of hoping they type it exactly right, and shows
/// what that contract still owes so a settlement cannot overshoot by accident.
class PersonField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final EntryRole role;
  final String hint;
  const PersonField({
    super.key,
    required this.controller,
    required this.role,
    required this.hint,
  });

  @override
  ConsumerState<PersonField> createState() => _PersonFieldState();
}

class _PersonFieldState extends ConsumerState<PersonField> {
  final _focus = FocusNode();
  bool _open = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focus.addListener(() {
      if (!_focus.hasFocus && _focus.canRequestFocus) setState(() => _open = false);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(peopleProvider);
    final typed = widget.controller.text.trim().toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          onTap: () => setState(() => _open = true),
          onChanged: (_) => setState(() => _open = true),
          decoration: InputDecoration(
            labelText: widget.hint,
            helperText: 'Or pick someone you have dealt with before',
            border: const OutlineInputBorder(),
          ),
        ),
        if (_open)
          people.maybeWhen(
            data: (names) {
              final shown = [
                for (final n in names)
                  if (typed.isEmpty || n.toLowerCase().contains(typed)) n,
              ].take(6).toList();
              if (shown.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final n in shown)
                      ActionChip(
                        avatar: const Icon(Icons.person_outline, size: 18),
                        label: Text(n),
                        onPressed: () {
                          widget.controller.text = n;
                          setState(() => _open = false);
                        },
                      ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
      ],
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
  return [for (final b in defaultBuckets) b.name];
});
