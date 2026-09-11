/// Self-transfer sheet: move money between own accounts (ATM Bank→Cash).
/// Writes two budget-neutral rows sharing one linkId. Phase 9.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../core/providers.dart';

const _quickTransferAmounts = [100.0, 200.0, 500.0, 1000.0, 2000.0, 5000.0];

class TransferSheet extends ConsumerStatefulWidget {
  const TransferSheet({super.key});

  @override
  ConsumerState<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<TransferSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _fromId;
  String? _toId;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (_fromId == null || _toId == null) {
      setState(() => _error = 'Pick both accounts');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount above zero');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref.read(transactionRepositoryProvider).transfer(
            fromId: _fromId!,
            toId: _toId!,
            amount: amount,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      ref.invalidate(recentTransactionsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Invalid argument(s): ', '');
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
            Text('Move between accounts', style: Theme.of(context).textTheme.titleMedium),
            const Text('Budget-neutral by design: months never inflate.'),
            const SizedBox(height: 12),
            accounts.when(
              data: (list) {
                if (list.length < 2) {
                  return const Text('Need two accounts — add another from Transactions → Accounts.');
                }
                _fromId ??= list.first.id;
                _toId ??= list.length > 1 ? list[1].id : list.first.id;
                final items = [for (final a in list) DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.kind})'))];
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _fromId,
                      decoration: const InputDecoration(labelText: 'From', border: OutlineInputBorder()),
                      items: items,
                      onChanged: (v) => setState(() => _fromId = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _toId,
                      decoration: const InputDecoration(labelText: 'To', border: OutlineInputBorder()),
                      items: items,
                      onChanged: (v) => setState(() => _toId = v),
                    ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Accounts unavailable: $e'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final q in _quickTransferAmounts)
                  ActionChip(
                    label: Text('₹${q.toStringAsFixed(0)}'),
                    onPressed: () => setState(() => _amount.text = q.toStringAsFixed(0)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Note (optional, e.g. ATM)', border: OutlineInputBorder()),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 12),
            FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Moving…' : 'Move')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
