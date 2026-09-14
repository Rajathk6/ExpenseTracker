import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/lock_service.dart';
import '../../core/providers.dart';

/// Lock gate: PIN pad when a PIN exists, one-tap setup on first run.
/// Styled as a bottom sheet like the system lock — content rises from the
/// bottom and grows as tall as it needs. Forgot-PIN recovers through the
/// security question set alongside the PIN (answer is salted+hashed;
/// without it there is no reset — offline vault, no backdoor).
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

  Future<void> _forgotPin() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _ForgotPinDialog(),
    );
    if (ok ?? false) {
      await _armTimer();
      ref.read(lockProvider.notifier).unlock(ok: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black26)],
          ),
          child: SafeArea(
            top: false,
            child: _hasPin! ? _pinPad(context) : _firstRun(context),
          ),
        ),
      ),
    );
  }

  Widget _firstRun(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Icon(Icons.lock_outline, size: 40),
        const SizedBox(height: 8),
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
    );
  }

  Widget _pinPad(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        const Icon(Icons.lock_outline, size: 36),
        const SizedBox(height: 4),
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
        TextButton(onPressed: _forgotPin, child: const Text('Forgot PIN?')),
        const Text('Biometric unlock arrives with the system plugin (dev-machine step).'),
      ],
    );
  }
}

/// Forgot-PIN flow: answer the security question → set a new PIN.
/// Wrong answer reveals nothing and resets nothing.
class _ForgotPinDialog extends ConsumerStatefulWidget {
  const _ForgotPinDialog();

  @override
  ConsumerState<_ForgotPinDialog> createState() => _ForgotPinDialogState();
}

class _ForgotPinDialogState extends ConsumerState<_ForgotPinDialog> {
  final _answer = TextEditingController();
  final _pin = TextEditingController();
  final _again = TextEditingController();
  String? _error;
  String? _question;
  bool? _hasRecovery;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = ref.read(pinServiceProvider);
    final has = await svc.hasRecovery;
    final q = has ? await svc.recoveryQuestion : null;
    if (mounted) {
      setState(() {
        _hasRecovery = has;
        _question = q;
      });
    }
  }

  @override
  void dispose() {
    _answer.dispose();
    _pin.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (_pin.text != _again.text) {
      setState(() => _error = 'PINs do not match');
      return;
    }
    try {
      await ref.read(pinServiceProvider).resetPinWithAnswer(answer: _answer.text, newPin: _pin.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Invalid argument(s): ', '').replaceFirst('Bad state: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Forgot PIN'),
      content: _hasRecovery == null
          ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
          : !(_hasRecovery!)
              ? const Text('No recovery question was set with this PIN, so it cannot be reset. '
                  'Your data stays locked — this is by design for an offline vault.')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_question ?? '', style: Theme.of(context).textTheme.titleSmall),
                      TextField(controller: _answer, decoration: const InputDecoration(labelText: 'Your answer', border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      TextField(controller: _pin, obscureText: true, maxLength: 6, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'New 6-digit PIN', border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      TextField(controller: _again, obscureText: true, maxLength: 6, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repeat PIN', border: OutlineInputBorder())),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                    ],
                  ),
                ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        if (_hasRecovery ?? false) FilledButton(onPressed: _reset, child: const Text('Reset PIN')),
      ],
    );
  }
}

/// PIN create/change sheet, reused by first-run and Settings.
/// Also captures the security question + answer used by Forgot PIN.
class PinSetupScreen extends ConsumerStatefulWidget {
  final bool firstRun;
  const PinSetupScreen({super.key, this.firstRun = false});

  @override
  ConsumerState<PinSetupScreen> createState() => PinSetupScreenState();
}

class PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pin = TextEditingController();
  final _again = TextEditingController();
  final _question = TextEditingController();
  final _answer = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _pin.dispose();
    _again.dispose();
    _question.dispose();
    _answer.dispose();
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
      final svc = ref.read(pinServiceProvider);
      await svc.setPin(_pin.text.trim());
      if (_question.text.trim().isNotEmpty || _answer.text.trim().isNotEmpty) {
        await svc.setRecovery(question: _question.text, answer: _answer.text);
      }
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
      body: SingleChildScrollView(
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
            const SizedBox(height: 16),
            const Text('Recovery question — only way back in if you forget the PIN.'),
            const SizedBox(height: 8),
            TextField(
              controller: _question,
              decoration: const InputDecoration(labelText: 'Question (e.g. first school?)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _answer,
              decoration: const InputDecoration(labelText: 'Answer', border: OutlineInputBorder()),
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
