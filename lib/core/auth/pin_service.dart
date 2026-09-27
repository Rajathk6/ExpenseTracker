/// PIN service: 6-digit PIN + decoy PIN, salted SHA-256 hashes in the OS
/// keychain (see secret_store.dart — nothing secret is written to the SQLite
/// file). No raw PIN is ever stored. Biometrics feed the same
/// 'real'/'decoy'/null verdict shape from core/auth/biometric_service.dart.
library;

import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../database.dart';
import 'secret_store.dart';

const _pinKey = 'pin.hash';
const _pinSaltKey = 'pin.salt';
const _decoyKey = 'decoy.hash';
const _decoySaltKey = 'decoy.salt';
const _lockMinutesKey = 'lock.minutes';
const _recoveryQKey = 'recovery.question';
const _recoveryAHashKey = 'recovery.answer.hash';
const _recoveryASaltKey = 'recovery.answer.salt';
const _biometricKey = 'biometric.enabled';

String? validatePinFormat(String pin) {
  if (!RegExp(r'^\d{6}$').hasMatch(pin)) return 'PIN must be exactly 6 digits';
  return null;
}

/// Random 16-byte hex salt.
String newSalt() {
  final r = Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// SHA-256(salt:pin) hex. Pure — unit-testable without a database.
Future<String> hashPin(String pin, String salt) async {
  final hash = await Sha256().hash(utf8.encode('$salt:$pin'));
  return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

class PinService {
  final AppDatabase db;
  final SecretStore secrets;

  /// Secrets default to the Android keychain; tests inject a memory store.
  /// [vault] namespaces the keychain keys per vault ('real' / 'demo').
  PinService(this.db, {SecretStore? secrets, String vault = 'real'})
      : secrets = secrets ?? KeychainSecretStore(db, vault: vault);

  Future<bool> get hasPin async => (await secrets.read(_pinKey)) != null;

  Future<bool> get hasDecoy async => (await secrets.read(_decoyKey)) != null;

  Future<void> setPin(String pin) async {
    final err = validatePinFormat(pin);
    if (err != null) throw ArgumentError(err);
    final salt = newSalt();
    await secrets.write(_pinSaltKey, salt);
    await secrets.write(_pinKey, await hashPin(pin, salt));
  }

  Future<void> setDecoy(String pin) async {
    final err = validatePinFormat(pin);
    if (err != null) throw ArgumentError(err);
    final salt = newSalt();
    await secrets.write(_decoySaltKey, salt);
    await secrets.write(_decoyKey, await hashPin(pin, salt));
  }

  /// 'real' | 'decoy' | null (wrong). Decoy is checked first so a shared
  /// prefix can't leak which PIN matched.
  Future<String?> verify(String pin) async {
    final decoyHash = await secrets.read(_decoyKey);
    if (decoyHash != null) {
      final salt = await secrets.read(_decoySaltKey) ?? '';
      if (await hashPin(pin, salt) == decoyHash) return 'decoy';
    }
    final pinHash = await secrets.read(_pinKey);
    if (pinHash == null) return null;
    final salt = await secrets.read(_pinSaltKey) ?? '';
    if (await hashPin(pin, salt) == pinHash) return 'real';
    return null;
  }

  Future<void> clearPin() async {
    await secrets.remove(_pinKey);
    await secrets.remove(_pinSaltKey);
  }

  Future<void> clearDecoy() async {
    await secrets.remove(_decoyKey);
    await secrets.remove(_decoySaltKey);
  }

  /// Recovery Q&A for "forgot PIN". The answer is salted+hashed like a PIN;
  /// matching is case-insensitive on trimmed text. Optional — without it,
  /// forgot-PIN cannot reset (by design: offline vault, no backdoor).
  Future<bool> get hasRecovery async =>
      (await db.getSetting(_recoveryQKey)) != null && (await secrets.read(_recoveryAHashKey)) != null;

  Future<String?> get recoveryQuestion async => db.getSetting(_recoveryQKey);

  Future<void> setRecovery({required String question, required String answer}) async {
    if (question.trim().isEmpty) throw ArgumentError('Pick a security question');
    if (answer.trim().isEmpty) throw ArgumentError('Answer cannot be empty');
    final salt = newSalt();
    await db.setSetting(_recoveryQKey, question.trim());
    await secrets.write(_recoveryASaltKey, salt);
    await secrets.write(_recoveryAHashKey, await hashPin(answer.trim().toLowerCase(), salt));
  }

  /// True when [answer] matches (case-insensitive). Never reveals anything.
  Future<bool> verifyRecoveryAnswer(String answer) async {
    final want = await secrets.read(_recoveryAHashKey);
    if (want == null) return false;
    final salt = await secrets.read(_recoveryASaltKey) ?? '';
    return (await hashPin(answer.trim().toLowerCase(), salt)) == want;
  }

  /// Resets the real PIN after a correct recovery answer. Decoy untouched.
  Future<void> resetPinWithAnswer({required String answer, required String newPin}) async {
    if (!await verifyRecoveryAnswer(answer)) throw StateError('Wrong answer');
    await setPin(newPin);
  }

  Future<int> lockMinutes() async {
    final raw = await db.getSetting(_lockMinutesKey);
    return int.tryParse(raw ?? '') ?? 5;
  }

  Future<void> setLockMinutes(int minutes) async {
    if (minutes != 0 && (minutes < 1 || minutes > 120)) {
      throw ArgumentError('Auto-lock must be 0 (never) or 1–120 minutes');
    }
    await db.setSetting(_lockMinutesKey, '$minutes');
  }

  /// Biometric unlock is opt-in and off by default. Not a secret: it lives in
  /// the plain settings table like auto-lock does.
  Future<bool> get biometricEnabled async => (await db.getSetting(_biometricKey)) == '1';

  Future<void> setBiometricEnabled(bool on) => db.setSetting(_biometricKey, on ? '1' : '0');
}
