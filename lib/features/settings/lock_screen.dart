import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/lock_service.dart';
import '../../core/providers.dart';

/// Lock gate: PIN pad when a PIN exists, one-tap setup on first run.
/// Decoy PIN opens the demo vault; biometric arrives with local_auth.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  String? _error;
  bool _busy = false;
  bool? _hasPin;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final has = await ref.read(pinServiceProvider).hasPin;
    if (mounted) setState(() => _hasPin = has);
  }

  Future<void> _armTimer() async {
    final minutes = await ref.read(pinServiceProvider).lockMinutes();
    ref.read(lockProvider.notifier).setTimeout(minutes == 0 ? null : Duration(minutes: minutes));
  }

  Future<void> _submit() async {
    if (_pin.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final verdict = await ref.read(pinServiceProvider).verify(_pin);
      if (verdict == null) {
        if (mounted) {
          setState(() {
            _error = 'Wrong PIN — try again';
            _pin = '';
            _busy = false;
          });
        }
        return;
      }
      await _armTimer();
      ref.read(lockProvider.notifier).unlock(ok: true, isDecoyPin: verdict == 'decoy');
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _busy = false;
        });
      }
    }
  }

  void _tap(String d) {
    if (_pin.length >= 6 || _busy) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == 6) _submit();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_hasPin!) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('ExpenseTracker is offline-first. Lock it with a 6-digit PIN, or continue without one.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PinSetupScreen(firstRun: true))),
                  child: const Text('Set PIN'),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(lockProvider.notifier).setTimeout(null);
                    ref.read(lockProvider.notifier).unlock(ok: true);
                  },
                  child: const Text('Continue without PIN'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 40),
              const SizedBox(height: 8),
              Text('Enter PIN', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_pin.replaceAll(RegExp(r'.'), '●'), style: const TextStyle(fontSize: 28, letterSpacing: 8)),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 12),
              for (final row in const [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['', '0', '⌫']])
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final d in row)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: d.isEmpty
                            ? const SizedBox(width: 64, height: 48)
                            : FilledButton.tonal(
                                onPressed: d == '⌫'
                                    ? (_pin.isEmpty ? null : () => setState(() => _pin = _pin.substring(0, _pin.length - 1)))
                                    : () => _tap(d),
                                child: SizedBox(width: 40, child: Center(child: Text(d, style: const TextStyle(fontSize: 20)))),
                              ),
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              const Text('Biometric unlock arrives with the system plugin (dev-machine step).'),
            ],
          ),
        ),
      ),
    );
  }
}

/// PIN create/change sheet, reused by first-run and Settings.
class PinSetupScreen extends ConsumerStatefulWidget {
  final bool firstRun;
  const PinSetupScreen({super.key, this.firstRun = false});

  @override
  ConsumerState<PinSetupScreen> createState() => PinSetupScreenState();
}

class PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pin = TextEditingController();
  final _again = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _pin.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_pin.text != _again.text) {
      setState(() => _error = 'PINs do not match');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref.read(pinServiceProvider).setPin(_pin.text.trim());
      if (!mounted) return;
      if (widget.firstRun) {
        await _armAndUnlock(real: true);
        if (mounted) Navigator.of(context).pop();
      } else {
        if (mounted) Navigator.of(context).pop(true);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Invalid argument(s): ', '');
          _saving = false;
        });
      }
    }
  }

  Future<void> _armAndUnlock({required bool real}) async {
    final minutes = await ref.read(pinServiceProvider).lockMinutes();
    ref.read(lockProvider.notifier).setTimeout(minutes == 0 ? null : Duration(minutes: minutes));
    ref.read(lockProvider.notifier).unlock(ok: true, isDecoyPin: !real);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _pin,
              autofocus: true,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'New 6-digit PIN', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _again,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Repeat PIN', border: OutlineInputBorder()),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 12),
            FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save PIN')),
          ],
        ),
      ),
    );
  }
}
