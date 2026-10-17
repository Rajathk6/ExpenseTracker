import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App lock gate: PIN/decoy verdicts, demo-vault flag, manual lock.
///
/// - `unlock(ok:isDecoyPin:)` flips the gate; the database provider swaps
///   the real/demo file handle off [decoyMode] (see providers.dart).
/// - Locking is **manual** (Settings → Lock now) plus whatever the OS does to
///   the process. An idle timer used to exist and was removed on 2026-09-27:
///   it locked the app while the owner was in the middle of typing an entry,
///   which is worse than leaving it unlocked on a personal phone. Fingerprint
///   unlock makes returning cheap enough that a timer is not needed.
class LockState {
  final bool locked;
  final bool decoyMode;
  const LockState({required this.locked, this.decoyMode = false});
}

class LockNotifier extends StateNotifier<LockState> {
  LockNotifier() : super(const LockState(locked: true));

  /// ok=false keeps the gate shut (wrong PIN / failed biometric).
  /// `isDecoyPin` opens the clean demo vault handle instead of real data.
  void unlock({required bool ok, bool isDecoyPin = false}) {
    if (!ok) return;
    state = LockState(locked: false, decoyMode: isDecoyPin);
  }

  void lock() {
    state = const LockState(locked: true);
  }
}

final lockProvider = StateNotifierProvider<LockNotifier, LockState>((ref) => LockNotifier());