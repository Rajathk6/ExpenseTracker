/// Intake confirm screen: the mandatory human checkpoint between shared
/// text (or OCR output) and the ledger. Nothing here auto-saves.
///
/// Native share-target / OCR plugins feed [initialText] on the dev machine
/// (wiring steps in PROGRESS); until then paste any payment SMS, UPI
/// message or OCR dump into the box. Manual entry is never blocked.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../core/intake/share_parser.dart';
import '../../core/ledger.dart';
import '../../core/providers.dart';
import '../transactions/entry_logic.dart';

class IntakeScreen extends ConsumerStatefulWidget {
  /// Pre-filled by the OS share sheet on the dev-machine build. Null = manual.
  final String? initialText;
  const IntakeScreen({super.key, this.initialText});

  @override
  ConsumerState<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends ConsumerState<IntakeScreen> {
  late final TextEditingController _raw;
  late final TextEditingController _amount;
  late final TextEditingController _category;
  String _kind = 'out';
  String? _accountId;
  String? _error;
  bool _saving = false;
  SharedPayment? _parsed;

  @override
  void initState() {
    super.initState();
    _raw = TextEditingController(text: widget.initialText ?? '');
    _amount = TextEditingController();
    _category = TextEditingController();
    if ((widget.initialText ?? '').isNotEmpty) _reparse(initial: true);
  }

  @override
  void dispose() {
    _raw.dispose();
    _amount.dispose();
    _category.dispose();
    super.dispose();
  }

  void _reparse({bool initial = false}) {
    final p = parseSharedText(_raw.text);
    setState(() {
      _parsed = p;
      if (!initial || _amount.text.isEmpty) {
        final a = p.amount;
        _amount.text = a == null ? '' : a.toStringAsFixed(a % 1 == 0 ? 0 : 2);
      }
      _kind = p.kindHint;
      if (_category.text.isEmpty && (p.merchant ?? '').isNotEmpty) {
        _category.text = p.merchant!.toLowerCase();
      }
    });
  }

  Future<void> _save(List<Account> accounts) async {
    final draft = EntryDraft(
      kind: _kind,
      amountText: _amount.text,
      categoryRaw: _category.text,
      accountId: _accountId,
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
      final amount = draft.amount!;
      final entry = _kind == 'out' ? spend(amount) : income(amount);
      await ref.read(transactionRepositoryProvider).add(
            kind: _kind,
            actual: entry.actual,
            budgetImpact: entry.budgetImpact,
            dateTime: DateTime.now(),
            categoryRaw: draft.categoryRaw,
            note: _parsed?.upiRef == null ? 'via intake' : 'via intake · ${_parsed!.upiRef}',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Intake confirm')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('Paste a payment SMS / UPI message / OCR dump. Nothing saves until you tap Confirm.'),
          const SizedBox(height: 8),
          TextField(
            controller: _raw,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Shared text',
              hintText: 'Paid Rs.450 to Swiggy',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _reparse(),
          ),
          const SizedBox(height: 8),
          if (_parsed != null && _raw.text.trim().isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detected', style: Theme.of(context).textTheme.titleSmall),
                    Text('Amount: ${_parsed!.amount?.toStringAsFixed(0) ?? '—'}'),
                    if (_parsed!.merchant != null) Text('Who: ${_parsed!.merchant}'),
                    if (_parsed!.upiRef != null) Text('UPI ref: ${_parsed!.upiRef}'),
                    Text('Looks like money ${_kind == 'in' ? 'received' : 'spent'} — change below if wrong.'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'out', label: Text('Spent'), icon: Icon(Icons.arrow_upward)),
              ButtonSegment(value: 'in', label: Text('Received'), icon: Icon(Icons.arrow_downward)),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount (editable)', prefixText: '₹ ', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _category,
            decoration: const InputDecoration(
              labelText: 'Category (pickable)',
              hintText: 'food swiggy order',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          accounts.when(
            data: (list) {
              if (list.isEmpty) return const Text('No accounts yet — add one from Transactions → Accounts first.');
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
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving
                ? null
                : () => _save(accounts.maybeWhen(data: (l) => l, orElse: () => const <Account>[])),
            child: Text(_saving ? 'Saving…' : 'Confirm & save offline'),
          ),
        ],
      ),
    );
  }
}
