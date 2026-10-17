import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/biometric_service.dart';
import '../../core/auth/lock_service.dart';
import '../../core/providers.dart';

/// Lock gate: PIN pad when a PIN exists, one-tap setup on first run.
/// Styled as a bottom sheet like the system lock — content rises from the
/// bottom and grows as tall as it needs. Forgot-PIN recovers through the
/// security question set alongside the PIN (answer is salted+hashed;
/// without it there is no reset — offline vault, no backdoor).
/// Decoy PIN opens the demo vault; fingerprint/face (local_auth) is offered
/// only when the owner turned it on in Settings, and it can only ever open
/// the real vault.
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
  bool _bioReady = false;
  bool _bioBusy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    // Never leave a system prompt hanging behind a dead lock screen.
    if (_bioBusy) ref.read(biometricServiceProvider).cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final has = await ref.read(pinServiceProvider).hasPin;
    final enabled = has && await ref.read(pinServiceProvider).biometricEnabled;
    final enrolled = enabled && await ref.read(biometricServiceProvider).hasEnrolledBiometric();
    if (mounted) {
      setState(() {
        _hasPin = has;
        _bioReady = enrolled;
      });
    }
  }

  /// Biometric path. A success opens the REAL vault — a fingerprint must never
  /// be able to land in the decoy.
  Future<void> _biometric() async {
    if (_bioBusy) return;
    setState(() {
      _bioBusy = true;
      _error = null;
    });
    final outcome = await ref.read(biometricServiceProvider).authenticate(
          reason: 'Unlock ExpenseTracker',
        );
    if (!mounted) return;
    if (outcome == BiometricOutcome.success) {
      ref.read(lockProvider.notifier).unlock(ok: true);
      return;
    }
    setState(() {
      _bioBusy = false;
      _error = biometricMessage(outcome);
      if (outcome == BiometricOutcome.notEnrolled || outcome == BiometricOutcome.noHardware) {
        _bioReady = false;
      }
    });
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
          onPressed: () => ref.read(lockProvider.notifier).unlock(ok: true),
          child: const Text('Continue without PIN'),
        ),
      ],
    );
  }

  Widget _pinPad(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_bioReady) ...[
          FilledButton.icon(
            onPressed: _bioBusy ? null : _biometric,
            icon: const Icon(Icons.fingerprint),
            label: Text(_bioBusy ? 'Waiting…' : 'Unlock with fingerprint / face'),
          ),
          const SizedBox(height: 12),
        ],
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
///
/// When a PIN already exists, changing it is a two-step gate: the owner must
/// prove it is them first, with the **current PIN** or, if they cannot
/// remember it, with the **security answer** they set alongside it. Before
/// this, "Change PIN" asked nothing and just overwrote the lock.
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
  final _currentPin = TextEditingController();
  final _recoveryAnswer = TextEditingController();
  String? _error;
  bool _saving = false;

  /// null = not checked yet. True once the owner proved it is them.
  bool? _unlocked;
  bool _checking = false;

  @override
  void dispose() {
    _pin.dispose();
    _again.dispose();
    _question.dispose();
    _answer.dispose();
    _currentPin.dispose();
    _recoveryAnswer.dispose();
    super.dispose();
  }

  /// Proves ownership before a PIN can be replaced: the current PIN, or the
  /// security answer when the PIN is forgotten. A decoy PIN is accepted too —
  /// the owner set it, so it is theirs to change.
  Future<bool> _verifyOwner() async {
    final pins = ref.read(pinServiceProvider);
    final entered = _currentPin.text.trim();
    if (entered.length == 6) {
      final verdict = await pins.verify(entered);
      if (verdict != null) return true;
      setState(() => _error = 'That is not your current PIN');
      return false;
    }
    if (await pins.hasRecovery) {
      if (await pins.verifyRecoveryAnswer(_recoveryAnswer.text)) return true;
      setState(() => _error = 'Wrong security answer');
      return false;
    }
    setState(() => _error = 'Enter your current 6-digit PIN to change it');
    return false;
  }

  Future<void> _checkIdentity() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    final ok = await _verifyOwner();
    if (!mounted) return;
    setState(() {
      _unlocked = ok;
      _checking = false;
    });
  }

  Future<void> _save() async {
    if (_unlocked != true) {
      await _checkIdentity();
      return;
    }
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
        _armAndUnlock(real: true);
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

  void _armAndUnlock({required bool real}) {
    ref.read(lockProvider.notifier).unlock(ok: true, isDecoyPin: !real);
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(pinServiceProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.firstRun ? 'Set PIN' : 'Change PIN')),
      body: FutureBuilder<bool>(
        future: svc.hasPin,
        builder: (context, snap) {
          final existingPin = snap.data ?? false;
          if (!existingPin) return _form(firstRun: true);
          if (_unlocked != true) return _identityGate(svc.hasRecovery);
          return _form(firstRun: false);
        },
      ),
    );
  }

  /// Step 1 for an existing PIN: prove you are the owner.
  Widget _identityGate(Future<bool> hasRecovery) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Confirm it is you before the PIN changes.'),
          const SizedBox(height: 16),
          TextField(
            controller: _currentPin,
            autofocus: true,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Your current 6-digit PIN',
              helperText: 'Leave this empty if you cannot remember it',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<bool>(
            future: hasRecovery,
            builder: (context, rec) => rec.data == true
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('…or answer your security question:'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _recoveryAnswer,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Security answer', border: OutlineInputBorder()),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          FilledButton(onPressed: _checking ? null : _checkIdentity, child: Text(_checking ? 'Checking…' : 'Continue')),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Step 2 (or the whole flow on first run): the new PIN + recovery Q&A.
  Widget _form({required bool firstRun}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!firstRun)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Identity confirmed. Set your new PIN.'),
            ),
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
          const Text('Recovery question — the way back in if you forget the PIN.'),
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
    );
  }
}
