/// Android share target: a payment SMS / UPI message shared from any app
/// lands here, is parsed offline and opens the confirm sheet — the same
/// checkpoint manual entry uses. Nothing is ever saved without a tap.
///
/// The manifest registers `ACTION_SEND` / `ACTION_SEND_MULTIPLE` for
/// `text/plain`; MainActivity hands the payload over these two channels.
/// Images get their own manifest filter when the OCR plugin lands.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/lock_service.dart' show lockProvider;
import 'intake_screen.dart';

/// The shareable text of a share payload, or null when there is nothing to
/// parse. Pure so "blank shares never open a half-empty sheet" is testable.
String? shareTextFrom(Object? payload) {
  if (payload is! String) return null;
  final text = payload.trim();
  return text.isEmpty ? null : text;
}

/// The two channels MainActivity listens on. Kept tiny: this is our own
/// manifest filter, not a plugin, so there is nothing to configure.
class ShareIntentBridge {
  static const _method = MethodChannel('dev.rajath.expense_tracker/share');
  static const _events = EventChannel('dev.rajath.expense_tracker/share_events');

  /// The payload of the intent that launched the app, consumed once.
  static Future<String?> initialText() async {
    try {
      return await _method.invokeMethod<String>('initialText');
    } on Object {
      // No platform side (tests, desktop) or a dead channel — not fatal.
      return null;
    }
  }

  /// Text shared while the app is already open. A blank payload is dropped
  /// rather than pushed as an empty sheet.
  static Stream<String> get stream => _events
      .receiveBroadcastStream()
      .map(shareTextFrom)
      .where((text) => text != null)
      .cast<String>();
}

/// Watches the OS share channel and opens [IntakeScreen] with the shared text.
///
/// Mounted inside MaterialApp (so a Navigator is available) from main.dart.
/// If the app is still locked the text is held until the vault opens — a
/// share must never be a way around the lock gate.
class ShareTargetListener extends ConsumerStatefulWidget {
  final Widget child;
  const ShareTargetListener({super.key, required this.child});

  @override
  ConsumerState<ShareTargetListener> createState() => _ShareTargetListenerState();
}

class _ShareTargetListenerState extends ConsumerState<ShareTargetListener> {
  StreamSubscription<String>? _stream;
  String? _pending;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _stream = ShareIntentBridge.stream.listen(
      (text) => _queue(text),
      onError: (Object _) {}, // a dead channel must not crash the app
    );
    // Cold start: the share sheet is what launched us.
    unawaited(
      ShareIntentBridge.initialText().then((text) {
        if (text != null) _queue(shareTextFrom(text));
      }),
    );
  }

  @override
  void dispose() {
    _stream?.cancel();
    super.dispose();
  }

  void _queue(String? text) {
    if (text == null || !mounted) return;
    setState(() => _pending = text);
    _maybeOpen();
  }

  void _maybeOpen() {
    final text = _pending;
    if (text == null || _opening) return;
    if (ref.read(lockProvider).locked) return; // held until the vault opens
    _opening = true;
    _pending = null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      _opening = false;
      await navigator.push(
        MaterialPageRoute(builder: (_) => IntakeScreen(initialText: text)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // The held share opens as soon as the PIN/biometric gate lets us through.
    ref.listen(lockProvider, (_, next) {
      if (!next.locked) _maybeOpen();
    });
    return widget.child;
  }
}
