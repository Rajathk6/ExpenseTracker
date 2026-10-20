/// First run: two things the app needs before it can be useful — your name
/// (so a split can say "Me") and your accounts (Cash and the bank you use).
///
/// Asked once, skippable, and editable later in Settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/months.dart';
import '../../core/owner_profile.dart';
import '../../core/providers.dart';

/// Shows the welcome sheet when the app has no accounts yet.
class FirstRunSheet extends ConsumerStatefulWidget {
  const FirstRunSheet({super.key});

  @override
  ConsumerState<FirstRunSheet> createState() => _FirstRunSheetState();
}

class _FirstRunSheetState extends ConsumerState<FirstRunSheet> {
  final _name = TextEditingController();
  final _cash = TextEditingController(text: 'Cash');
  final _bank = TextEditingController(text: 'Bank');
  final _bankBalance = TextEditingController();
  final _cashBalance = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _cash.dispose();
    _bank.dispose();
    _bankBalance.dispose();
    _cashBalance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final accounts = ref.read(accountRepositoryProvider);
      // Cash first, then the bank: the two things everyone has. Both can be
      // renamed later, and the balances are optional.
      if (_cash.text.trim().isNotEmpty) {
        await accounts.create(name: _cash.text.trim(), kind: 'cash');
      }
      if (_bank.text.trim().isNotEmpty) {
        await accounts.create(name: _bank.text.trim(), kind: 'bank');
      }
      await ref.read(ownerProfileProvider).setName(_name.text);

      // Opening balances go into the month opener, so reconcile and net worth
      // have a starting point from day one.
      final bank = double.tryParse(_bankBalance.text.trim());
      final cash = double.tryParse(_cashBalance.text.trim());
      if (bank != null || cash != null) {
        await ref.read(monthStartServiceProvider).apply(
              month: monthKey(DateTime.now()),
              bankBalance: bank,
              cashBalance: cash,
            );
      }
      ref
        ..invalidate(accountsProvider)
        ..invalidate(ownerNameProvider)
        ..invalidate(monthOpenProvider(monthKey(DateTime.now())))
        ..invalidate(budgetStatusProvider(monthKey(DateTime.now())));
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
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome to ExpenseTracker', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Offline, on your phone. Two quick things and you are set.'),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your name',
                hintText: 'Rajath',
                helperText: 'Used wherever the app says "Me" — in splits and groups',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cash,
              decoration: const InputDecoration(
                labelText: 'Cash wallet',
                helperText: 'The money in your pocket',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cashBalance,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Cash in hand ₹ (optional)', prefixText: '₹ ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bank,
              decoration: const InputDecoration(
                labelText: 'Primary bank',
                helperText: 'The account most of your money sits in',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bankBalance,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Bank balance ₹ (optional)', prefixText: '₹ ', border: OutlineInputBorder()),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Setting up…' : 'Start'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Skip — I will do it later'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Opens the first-run sheet. Returns true when accounts were created.
Future<bool> openFirstRun(BuildContext context) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const FirstRunSheet(),
  );
  return done ?? false;
}
