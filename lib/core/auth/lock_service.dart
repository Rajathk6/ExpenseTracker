import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App lock gate: PIN/decoy verdicts, demo-vault flag, auto-lock timer.
/// UI must read only this provider — no per-screen auth logic.
///
/// - `unlock(ok:isDecoyPin:)` flips the gate; the database provider swaps
///   the real/demo file handle off [decoyMode] (see providers.dart).
/// - Auto-lock: [setTimeout] arms an idle timer; [noteActivity] refreshes
///   it (called on unlock + app resume). `null` timeout = manual lock only.
/// - Biometric feeds the same `unlock()` once local_auth is re-added.
class LockState {
  final bool locked;
  final bool decoyMode;
  const LockState({required this.locked, this.decoyMode = false});
}

class LockNotifier extends StateNotifier<LockState> {
  LockNotifier() : super(const LockState(locked: true));

  Timer? _idle;
  Duration? _timeout;

  /// ok=false keeps the gate shut (wrong PIN / failed biometric).
  /// `isDecoyPin` opens the clean demo vault handle instead of real data.
  void unlock({required bool ok, bool isDecoyPin = false}) {
    if (!ok) return;
    state = LockState(locked: false, decoyMode: isDecoyPin);
    noteActivity();
  }

  void lock() {
    _idle?.cancel();
    state = const LockState(locked: true);
  }

  /// Arms the auto-lock timer. `null` disables it (manual lock only).
  void setTimeout(Duration? timeout) {
    _timeout = timeout;
    noteActivity();
  }

  /// Call on unlock + app resume. Restarts the idle countdown.
  void noteActivity() {
    _idle?.cancel();
    if (state.locked || _timeout == null) return;
    _idle = Timer(_timeout!, lock);
  }

  @override
  void dispose() {
    _idle?.cancel();
    super.dispose();
  }
}

final lockProvider = StateNotifierProvider<LockNotifier, LockState>((ref) => LockNotifier());
