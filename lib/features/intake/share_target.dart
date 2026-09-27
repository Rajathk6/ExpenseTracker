/// Android share target: a payment SMS / UPI message, or a screenshot, shared
/// from any app lands here. Text is parsed offline; a screenshot is read
/// on-device (ML Kit, see ocr_reader.dart) and goes through the same parser.
/// Either way the intake confirm sheet opens — nothing is ever saved without a
/// tap.
///
/// The manifest registers `ACTION_SEND` / `ACTION_SEND_MULTIPLE` for
/// `text/plain` and `image/*`; MainActivity hands the payload over these two
/// channels.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/lock_service.dart' show lockProvider;
import 'intake_screen.dart';

/// What a share carried: text, screenshots, or both. Null when the share held
/// neither — the sheet must never open empty.
class SharePayload {
  final String? text;
  final List<String> images;
  const SharePayload({required this.text, required this.images});

  /// Pure parse of the platform map, so "a blank share is not a share" is
  /// testable off-device. Bad shapes degrade to empty, never to a crash.
  static SharePayload? from(Object? raw) {
    if (raw is! Map) return null;
    final text = raw['text'];
    final images = raw['images'];
    final cleanText = text is String && text.trim().isNotEmpty ? text.trim() : null;
    final cleanImages = <String>[
      if (images is List)
        for (final i in images)
          if (i is String && i.isNotEmpty) i,
    ];
    if (cleanText == null && cleanImages.isEmpty) return null;
    return SharePayload(text: cleanText, images: cleanImages);
  }

  bool get isScreenshotOnly => text == null && images.isNotEmpty;
}

/// The two channels MainActivity listens on. Kept tiny: this is our own
/// manifest filter, not a plugin, so there is nothing to configure.
class ShareIntentBridge {
  static const _method = MethodChannel('dev.rajath.expense_tracker/share');
  static const _events = EventChannel('dev.rajath.expense_tracker/share_events');

  /// The payload of the intent that launched the app, consumed once.
  static Future<SharePayload?> initialPayload() async {
    try {
      return SharePayload.from(await _method.invokeMethod<Object?>('initialPayload'));
    } on Object {
      // No platform side (tests, desktop) or a dead channel — not fatal.
      return null;
    }
  }

  /// Shared while the app is already open. Empty shares are dropped.
  static Stream<SharePayload> get stream => _events
      .receiveBroadcastStream()
      .map(SharePayload.from)
      .where((payload) => payload != null)
      .cast<SharePayload>();
}

/// Watches the OS share channel and opens [IntakeScreen] with what was shared.
///
/// Mounted inside MaterialApp (so a Navigator is available) from main.dart.
/// If the app is still locked the payload is held until the vault opens — a
/// share must never be a way around the lock gate.
class ShareTargetListener extends ConsumerStatefulWidget {
  final Widget child;
  const ShareTargetListener({super.key, required this.child});

  @override
  ConsumerState<ShareTargetListener> createState() => _ShareTargetListenerState();
}

class _ShareTargetListenerState extends ConsumerState<ShareTargetListener> {
  StreamSubscription<SharePayload>? _stream;
  SharePayload? _pending;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _stream = ShareIntentBridge.stream.listen(
          _queue,
          onError: (Object _) {}, // a dead channel must not crash the app
        );
    // Cold start: the share sheet is what launched us.
    unawaited(
      ShareIntentBridge.initialPayload().then((payload) {
        if (payload != null) _queue(payload);
      }),
    );
  }

  @override
  void dispose() {
    _stream?.cancel();
    super.dispose();
  }

  void _queue(SharePayload? payload) {
    if (payload == null || !mounted) return;
    setState(() => _pending = payload);
    _maybeOpen();
  }

  void _maybeOpen() {
    final payload = _pending;
    if (payload == null || _opening) return;
    if (ref.read(lockProvider).locked) return; // held until the vault opens
    _opening = true;
    _pending = null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      _opening = false;
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => IntakeScreen(
            initialText: payload.text,
            initialImages: payload.images,
          ),
        ),
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
