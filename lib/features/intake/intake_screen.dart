/// Intake confirm screen: the mandatory human checkpoint between shared
/// text (or an OCR'd screenshot) and the ledger. Nothing here auto-saves.
///
/// Both entry points feed the same box: an Android share (or the app being
/// launched by one) lands in [initialText] / [initialImages], and the
/// "Read a screenshot" button picks an image from the device. Manual entry is
/// never blocked.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../core/intake/share_parser.dart';
import '../../core/ledger.dart';
import '../../core/providers.dart';
import '../transactions/category_field.dart';
import '../transactions/entry_logic.dart';
import 'ocr_reader.dart';

class IntakeScreen extends ConsumerStatefulWidget {
  /// Pre-filled by the Android share sheet. Null = manual.
  final String? initialText;
  /// Screenshots shared from another app, already copied into our cache.
  final List<String> initialImages;
  /// Overridable so tests never touch ML Kit.
  final TextReader reader;

  const IntakeScreen({
    super.key,
    this.initialText,
    this.initialImages = const [],
    this.reader = const RecogniseText(),
  });

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
  bool _reading = false;
  SharedPayment? _parsed;

  @override
  void initState() {
    super.initState();
    _raw = TextEditingController(text: widget.initialText ?? '');
    _amount = TextEditingController();
    _category = TextEditingController();
    if ((widget.initialText ?? '').isNotEmpty) _reparse(initial: true);
    if (widget.initialImages.isNotEmpty) _readImages(widget.initialImages);
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

  /// On-device OCR. The recognised text lands in the same box a shared SMS
  /// uses, so one parser and one confirm screen cover both.
  Future<void> _readImages(List<String> paths) async {
    final readable = paths.where(isReadableImage).toList();
    if (readable.isEmpty) {
      _setError('That screenshot could not be opened. Paste the text instead.');
      return;
    }
    setState(() {
      _reading = true;
      _error = null;
    });
    final buffer = StringBuffer();
    var failed = 0;
    for (final path in readable) {
      try {
        final text = await widget.reader.read(path);
        if (text.trim().isEmpty) {
          failed++;
        } else {
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(text.trim());
        }
      } on Object {
        failed++;
      }
    }
    if (!mounted) return;
    if (buffer.isEmpty) {
      setState(() {
        _reading = false;
        _error = 'No text found in the screenshot — paste the message instead.';
      });
      return;
    }
    setState(() {
      _reading = false;
      if (failed > 0) _error = 'Read ${buffer.toString().split('\n').length} line(s); $failed screenshot(s) unreadable.';
    });
    _raw.text = buffer.toString();
    _reparse();
  }

  void _setError(String message) {
    if (mounted) setState(() => _error = message);
  }

  /// Pick a screenshot from the device (no share sheet needed).
  Future<void> _pickImage() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.image,
        dialogTitle: 'Choose a payment screenshot',
      );
      final path = file?.path;
      if (path == null || path.isEmpty) return;
      await _readImages([path]);
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open the file browser: $e')));
    }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Intake confirm')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('Paste a payment SMS / UPI message, or read a screenshot. Nothing saves until you tap Confirm.'),
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
          OutlinedButton.icon(
            onPressed: _reading ? null : _pickImage,
            icon: _reading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.image_search),
            label: Text(_reading ? 'Reading screenshot…' : 'Read a screenshot (on-device OCR)'),
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
          CategoryField(
            controller: _category,
            label: 'Category (pickable)',
            hintText: 'food swiggy order',
            helperText: 'type a few letters to pick a past one',
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
