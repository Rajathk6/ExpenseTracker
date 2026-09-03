import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Phase 0 stub: in-memory lock state. Phase 10 swaps in
/// flutter_secure_storage (PIN hash) + local_auth (biometric) + decoy PIN.
/// UI must read only this provider — no per-screen auth logic.
class LockState {
  final bool locked;
  final bool decoyMode;
  const LockState({required this.locked, this.decoyMode = false});
}

class LockNotifier extends StateNotifier<LockState> {
  LockNotifier() : super(const LockState(locked: true));

  /// TODO(phase-10): verify PIN hash (argon2) or biometric via local_auth.
  /// `isDecoyPin` opens a clean demo vault handle instead of real DB.
  void unlock({required bool ok, bool isDecoyPin = false}) {
    if (!ok) return;
    state = LockState(locked: false, decoyMode: isDecoyPin);
  }

  void lock() => state = const LockState(locked: true);
}

final lockProvider = StateNotifierProvider<LockNotifier, LockState>((ref) => LockNotifier());
