/// Biometric unlock (local_auth), wrapped so the rest of the app never touches
/// the plugin and never has to handle a raw platform exception.
///
/// Two rules, both deliberate:
/// - this stores nothing; the lock gate in lock_service.dart is still the only
///   thing that opens, and a biometric can only ever open the REAL vault —
///   never the decoy, which is the point of a decoy;
/// - the PIN pad always stays reachable. A missing sensor, a locked-out
///   fingerprint or a cancelled prompt must never lock the owner out of their
///   own data.
library;

import 'package:local_auth/local_auth.dart';

enum BiometricOutcome {
  success,
  cancelled,
  failed,
  notEnrolled,
  noHardware,
  lockedOut,
  busy,
  unavailable,
}

class BiometricService {
  BiometricService([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();
  final LocalAuthentication _auth;

  /// The device can do biometrics or fall back to its own PIN/pattern.
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  /// A fingerprint/face is actually enrolled — the honest gate for the
  /// Settings toggle, since "device supports it" is not "you set it up".
  Future<bool> hasEnrolledBiometric() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on Object {
      return false;
    }
  }

  /// Runs the system prompt. Never throws: every failure comes back as an
  /// outcome the lock screen turns into one line of copy.
  ///
  /// [biometricOnly] true = fingerprint/face only. The lock screen keeps it
  /// true when a PIN is set (a fingerprint must not be a weaker door than the
  /// PIN); Settings uses it to confirm a deliberate enrolment.
  Future<BiometricOutcome> authenticate({
    required String reason,
    bool biometricOnly = true,
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
      return ok ? BiometricOutcome.success : BiometricOutcome.failed;
    } on LocalAuthException catch (e) {
      return mapBiometricException(e.code);
    } on Object {
      return BiometricOutcome.unavailable;
    }
  }

  /// Cancels an in-flight prompt (used when the lock screen goes away).
  Future<void> cancel() async {
    try {
      await _auth.stopAuthentication();
    } on Object {
      // Nothing to cancel — fine.
    }
  }
}

/// Pure mapping from platform error codes, so the copy is testable off-device.
BiometricOutcome mapBiometricException(LocalAuthExceptionCode code) {
  switch (code) {
    case LocalAuthExceptionCode.userCanceled:
    case LocalAuthExceptionCode.systemCanceled:
    case LocalAuthExceptionCode.userRequestedFallback:
      return BiometricOutcome.cancelled;
    case LocalAuthExceptionCode.timeout:
    case LocalAuthExceptionCode.noBiometricsEnrolled:
      return BiometricOutcome.notEnrolled;
    case LocalAuthExceptionCode.noCredentialsSet:
    case LocalAuthExceptionCode.noBiometricHardware:
      return BiometricOutcome.noHardware;
    case LocalAuthExceptionCode.biometricLockout:
    case LocalAuthExceptionCode.temporaryLockout:
    case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
      return BiometricOutcome.lockedOut;
    case LocalAuthExceptionCode.authInProgress:
      return BiometricOutcome.busy;
    case LocalAuthExceptionCode.uiUnavailable:
    case LocalAuthExceptionCode.deviceError:
    case LocalAuthExceptionCode.unknownError:
      return BiometricOutcome.unavailable;
  }
}

/// One line of copy. [null] for success = nothing to say.
String? biometricMessage(BiometricOutcome outcome) {
  switch (outcome) {
    case BiometricOutcome.success:
      return null;
    case BiometricOutcome.cancelled:
      return 'Cancelled — use your PIN.';
    case BiometricOutcome.failed:
      return 'Not recognised — use your PIN.';
    case BiometricOutcome.notEnrolled:
      return 'No fingerprint or face set up on this phone. Add one in Android settings.';
    case BiometricOutcome.noHardware:
      return 'This device has no fingerprint or face sensor.';
    case BiometricOutcome.lockedOut:
      return 'Too many attempts. Unlock with your PIN, then try again.';
    case BiometricOutcome.busy:
      return 'A scan is already running — wait a moment or use your PIN.';
    case BiometricOutcome.unavailable:
      return 'Biometric unlock unavailable right now — use your PIN.';
  }
}
