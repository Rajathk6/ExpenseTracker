/// PIN service: 6-digit PIN + decoy PIN, salted SHA-256 hashes in Settings.
/// No raw PIN is ever stored. Biometric (local_auth) is a dev-machine
/// re-add — this layer already returns the same 'real'/'decoy'/null verdict
/// shape a biometric path will feed. Phase 10.
library;

import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../database.dart';

const _pinKey = 'pin.hash';
const _pinSaltKey = 'pin.salt';
const _decoyKey = 'decoy.hash';
const _decoySaltKey = 'decoy.salt';
const _lockMinutesKey = 'lock.minutes';

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
  const PinService(this.db);

  Future<bool> get hasPin async => (await db.getSetting(_pinKey)) != null;

  Future<bool> get hasDecoy async => (await db.getSetting(_decoyKey)) != null;

  Future<void> setPin(String pin) async {
    final err = validatePinFormat(pin);
    if (err != null) throw ArgumentError(err);
    final salt = newSalt();
    await db.setSetting(_pinSaltKey, salt);
    await db.setSetting(_pinKey, await hashPin(pin, salt));
  }

  Future<void> setDecoy(String pin) async {
    final err = validatePinFormat(pin);
    if (err != null) throw ArgumentError(err);
    final salt = newSalt();
    await db.setSetting(_decoySaltKey, salt);
    await db.setSetting(_decoyKey, await hashPin(pin, salt));
  }

  /// 'real' | 'decoy' | null (wrong). Decoy is checked first so a shared
  /// prefix can't leak which PIN matched.
  Future<String?> verify(String pin) async {
    final decoyHash = await db.getSetting(_decoyKey);
    if (decoyHash != null) {
      final salt = await db.getSetting(_decoySaltKey) ?? '';
      if (await hashPin(pin, salt) == decoyHash) return 'decoy';
    }
    final pinHash = await db.getSetting(_pinKey);
    if (pinHash == null) return null;
    final salt = await db.getSetting(_pinSaltKey) ?? '';
    if (await hashPin(pin, salt) == pinHash) return 'real';
    return null;
  }

  Future<void> clearPin() async {
    await db.deleteSetting(_pinKey);
    await db.deleteSetting(_pinSaltKey);
  }

  Future<void> clearDecoy() async {
    await db.deleteSetting(_decoyKey);
    await db.deleteSetting(_decoySaltKey);
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
}
