/// Secret settings live in the OS keychain (Android Keystore), not in the
/// SQLite file. Before this existed, salted PIN/recovery hashes were written
/// to the plain `settings` table; those rows are migrated on first read and
/// then deleted, so upgrading never leaves a hash sitting in the database.
///
/// [MemorySecretStore] is the no-plugin store the unit tests use.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../database.dart';

/// Settings keys that must never live in the plain database. Non-secret
/// settings (auto-lock minutes, biometric toggle) stay in the database.
const secretSettingKeys = [
  'pin.hash',
  'pin.salt',
  'decoy.hash',
  'decoy.salt',
  'recovery.answer.hash',
  'recovery.answer.salt',
];

abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

/// The three keychain calls we need. Narrow on purpose: the plugin type is an
/// implementation detail, tests fake this instead.
abstract class SecureKeyValue {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
  Future<void> delete(String key);
}

/// Production adapter over flutter_secure_storage.
class FlutterSecureKeyValue implements SecureKeyValue {
  final FlutterSecureStorage store;
  const FlutterSecureKeyValue([
    this.store = const FlutterSecureStorage(
      aOptions: AndroidOptions(storageNamespace: 'expense_tracker'),
    ),
  ]);

  @override
  Future<String?> read(String key) => store.read(key: key);

  @override
  Future<void> write(String key, String? value) => store.write(key: key, value: value);

  @override
  Future<void> delete(String key) => store.delete(key: key);
}

/// Tests: a plain map, no platform channel.
class MemorySecretStore implements SecretStore {
  final Map<String, String> values = {};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);
}

/// Production store. Keys are namespaced per vault so the real vault and the
/// decoy (demo) vault can each own a `pin.hash` without colliding.
class KeychainSecretStore implements SecretStore {
  final AppDatabase db;
  final String vault;
  final SecureKeyValue keychain;

  KeychainSecretStore(this.db, {this.vault = 'real', SecureKeyValue? keychain})
      : keychain = keychain ?? const FlutterSecureKeyValue();

  String _key(String key) => 'expense_tracker/$vault/$key';

  /// Keystore first. A legacy `settings` row is copied across and deleted —
  /// but only once the secure write actually succeeded, so a keystore failure
  /// can never lose an existing PIN.
  @override
  Future<String?> read(String key) async {
    try {
      final secure = await keychain.read(_key(key));
      if (secure != null) return secure;
    } on Object {
      // Keystore unreadable: fall through to the legacy row rather than
      // pretending the PIN is gone (the gate is still PIN-owned).
    }
    final legacy = await db.getSetting(key);
    if (legacy == null) return null;
    try {
      await keychain.write(_key(key), legacy);
      await db.deleteSetting(key);
    } on Object {
      // Keep the plain copy: a later read can still migrate it.
    }
    return legacy;
  }

  @override
  Future<void> write(String key, String value) async {
    await keychain.write(_key(key), value);
    await db.deleteSetting(key);
  }

  @override
  Future<void> remove(String key) async {
    await keychain.delete(_key(key));
    await db.deleteSetting(key);
  }
}
