/// Settings: PIN + decoy, auto-lock, encrypted backup, about.
/// Everything here works offline. Drive upload stays a manual Files-app
/// step per PLAN (export shows the exact file path).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/lock_service.dart';
import '../../core/backup/codec.dart';
import '../../core/providers.dart';
import 'lock_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _refreshAll(WidgetRef ref) async {
    ref
      ..invalidate(accountsProvider)
      ..invalidate(recentTransactionsProvider)
      ..invalidate(openDebtsProvider)
      ..invalidate(allDebtsProvider)
      ..invalidate(openSplitsProvider)
      ..invalidate(allSplitsProvider)
      ..invalidate(openInstrumentsProvider)
      ..invalidate(allInstrumentsProvider);
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final password = TextEditingController();
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Encrypted backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('One password encrypts everything. Lose it and the file is unreadable — by design.'),
              const SizedBox(height: 8),
              TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Backup password', border: OutlineInputBorder())),
              if (error != null) Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (password.text.isEmpty) {
                  setDialog(() => error = 'Enter a password');
                  return;
                }
                try {
                  final path = await ref.read(backupServiceProvider).exportToFile(password.text);
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved: $path — upload it to Drive with Files.')));
                  }
                } on Object catch (e) {
                  setDialog(() => error = e.toString());
                }
              },
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );
    if (ok ?? false) _refreshAll(ref);
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final path = TextEditingController();
    final password = TextEditingController();
    String? error;
    final counts = await showDialog<Map<String, int>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Restore backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Restoring overwrites conflicting rows. Export first if unsure.'),
              const SizedBox(height: 8),
              TextField(controller: path, decoration: const InputDecoration(labelText: 'File path (.etbak)', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Backup password', border: OutlineInputBorder())),
              if (error != null) Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  final c = await ref.read(backupServiceProvider).importFromFile(path.text.trim(), password.text);
                  if (ctx.mounted) Navigator.of(ctx).pop(c);
                } on BackupPasswordError {
                  setDialog(() => error = 'Wrong password — file untouched');
                } on Object catch (e) {
                  setDialog(() => error = e.toString());
                }
              },
              child: const Text('Restore'),
            ),
          ],
        ),
      ),
    );
    if (counts != null && context.mounted) {
      await _refreshAll(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restored ${counts['transactions'] ?? 0} entries, ${counts['accounts'] ?? 0} accounts.')),
      );
    }
  }

  Future<void> _decoy(BuildContext context, WidgetRef ref) async {
    final pin = TextEditingController();
    String? error;
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Decoy PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('A second 6-digit PIN that opens a clean demo vault instead of real data.'),
              const SizedBox(height: 8),
              TextField(controller: pin, obscureText: true, maxLength: 6, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Decoy PIN', border: OutlineInputBorder())),
              if (error != null) Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  await ref.read(pinServiceProvider).setDecoy(pin.text.trim());
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                } on Object catch (e) {
                  setDialog(() => error = e.toString().replaceFirst('Invalid argument(s): ', ''));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if ((done ?? false) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Decoy PIN set — it opens the demo vault.')));
    }
  }

  Future<void> _autoLock(BuildContext context, WidgetRef ref) async {
    final current = await ref.read(pinServiceProvider).lockMinutes();
    int picked = current;
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Auto-lock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in const [0, 1, 5, 15])
                RadioListTile<int>(
                  title: Text(m == 0 ? 'Never (manual)' : '$m min idle'),
                  value: m,
                  groupValue: picked,
                  onChanged: (v) => setDialog(() => picked = v ?? picked),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                await ref.read(pinServiceProvider).setLockMinutes(picked);
                ref.read(lockProvider.notifier).setTimeout(picked == 0 ? null : Duration(minutes: picked));
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if ((done ?? false) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auto-lock updated.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pin = ref.watch(pinServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Security', style: Theme.of(context).textTheme.titleSmall),
          FutureBuilder<bool>(
            future: pin.hasPin,
            builder: (_, s) => ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: Text(s.data ?? false ? 'Change PIN' : 'Set PIN'),
              subtitle: const Text('6 digits, salted hash, never stored raw'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PinSetupScreen())),
            ),
          ),
          FutureBuilder<bool>(
            future: pin.hasDecoy,
            builder: (_, s) => ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: Text((s.data ?? false) ? 'Change decoy PIN' : 'Set decoy PIN'),
              subtitle: const Text('Second PIN opens a clean demo vault'),
              onTap: () => _decoy(context, ref),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Auto-lock'),
            subtitle: const Text('Locks after idle time'),
            onTap: () => _autoLock(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Biometric unlock'),
            subtitle: const Text('Re-added on the dev machine (local_auth)'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Needs the native plugin — dev-machine step, see PROGRESS.')),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_open_outlined),
            title: const Text('Lock now'),
            onTap: () => ref.read(lockProvider.notifier).lock(),
          ),
          const SizedBox(height: 8),
          Text('Backup (encrypted, offline)', style: Theme.of(context).textTheme.titleSmall),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Export backup'),
            subtitle: const Text('Password-encrypted .etbak file, then manual Drive upload'),
            onTap: () => _export(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Restore backup'),
            subtitle: const Text('Wrong password fails cleanly, file untouched'),
            onTap: () => _import(context, ref),
          ),
          const SizedBox(height: 8),
          Text('About', style: Theme.of(context).textTheme.titleSmall),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('ExpenseTracker'),
            subtitle: Text('Offline-first. No backend. SQLCipher lands with the signed release.'),
          ),
        ],
      ),
    );
  }
}
