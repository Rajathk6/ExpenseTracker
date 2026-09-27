import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/auth/biometric_service.dart';
import 'package:expense_tracker/core/auth/pin_service.dart';
import 'package:expense_tracker/core/auth/secret_store.dart';
import 'package:expense_tracker/core/backup/backup_service.dart';
import 'package:expense_tracker/core/backup/codec.dart';
import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';
import 'package:local_auth/local_auth.dart';

/// Stands in for the Android keychain so the migration path is testable.
class _FakeKeychain implements SecureKeyValue {
  final Map<String, String> values = {};
  final bool throws;
  _FakeKeychain({this.throws = false});

  @override
  Future<String?> read(String key) async {
    if (throws) throw StateError('keystore unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String? value) async {
    if (throws) throw StateError('keystore unavailable');
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete(String key) async {
    if (throws) throw StateError('keystore unavailable');
    values.remove(key);
  }
}

void main() {
  group('PIN hashing (pure crypto)', () {
    test('format gate is exactly 6 digits', () {
      expect(validatePinFormat('123456'), isNull);
      expect(validatePinFormat('12345'), isNotNull);
      expect(validatePinFormat('abcdef'), isNotNull);
    });

    test('same PIN, different salts, different hashes — and verifies', () async {
      final h1 = await hashPin('123456', 'salt-one');
      final h2 = await hashPin('123456', 'salt-two');
      expect(h1, isNot(equals(h2)));
      expect(await hashPin('123456', 'salt-one'), h1);
      expect(await hashPin('654321', 'salt-one'), isNot(equals(h1)));
    });
  });

  group('encrypted backup codec (pure)', () {
    Map<String, dynamic> sample() => {
          'accounts': [
            {'id': 'a1', 'name': 'Cash', 'kind': 'cash'},
          ],
          'transactions': [
            {'id': 't1', 'kind': 'out', 'actual': -300.0},
          ],
        };

    test('round-trips byte-identical tables', () async {
      final packed = await encryptBackup(sample(), 'correct-horse');
      final back = await decryptBackup(packed, 'correct-horse');
      expect(back['accounts'], sample()['accounts']);
      expect(back['transactions'], sample()['transactions']);
    });

    test('wrong password fails cleanly, short bytes rejected', () async {
      final packed = await encryptBackup(sample(), 'correct-horse');
      expect(() => decryptBackup(packed, 'wrong-horse'), throwsA(isA<BackupPasswordError>()));
      expect(() => decryptBackup(Uint8List.fromList([1, 2, 3]), 'x'), throwsFormatException);
      expect(() => encryptBackup(sample(), ''), throwsArgumentError);
    });
  });

  group('keychain secret store (fake platform, real migration path)', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.memory());
    tearDown(() => db.close());

    test('a hash written before the keychain existed is migrated and scrubbed', () async {
      // Pre-upgrade layout: hashes sit in the plain settings table.
      await db.setSetting('pin.hash', 'deadbeef');
      await db.setSetting('pin.salt', 'cafe');
      final store = KeychainSecretStore(db, vault: 'real', keychain: _FakeKeychain());

      expect(await store.read('pin.hash'), 'deadbeef');
      expect(await db.getSetting('pin.hash'), isNull, reason: 'plain copy must be deleted');
      expect(await store.read('pin.salt'), 'cafe');
      expect(await store.read('decoy.hash'), isNull);
    });

    test('real and demo vaults never share a key', () async {
      final backing = _FakeKeychain();
      final real = KeychainSecretStore(db, vault: 'real', keychain: backing);
      final demo = KeychainSecretStore(db, vault: 'demo', keychain: backing);
      await real.write('pin.hash', 'real-hash');
      await demo.write('pin.hash', 'demo-hash');
      expect(await real.read('pin.hash'), 'real-hash');
      expect(await demo.read('pin.hash'), 'demo-hash');
    });

    test('an unreadable keystore never loses an existing PIN', () async {
      await db.setSetting('pin.hash', 'legacy-hash');
      final store = KeychainSecretStore(db, vault: 'real', keychain: _FakeKeychain(throws: true));
      expect(await store.read('pin.hash'), 'legacy-hash');
      expect(await db.getSetting('pin.hash'), 'legacy-hash', reason: 'kept for a later migration');
    });
  });

  group('biometric outcomes (pure mapping + copy)', () {
    test('platform error codes map to outcomes the lock screen can explain', () {
      expect(mapBiometricException(LocalAuthExceptionCode.userCanceled), BiometricOutcome.cancelled);
      expect(mapBiometricException(LocalAuthExceptionCode.systemCanceled), BiometricOutcome.cancelled);
      expect(mapBiometricException(LocalAuthExceptionCode.timeout), BiometricOutcome.notEnrolled);
      expect(mapBiometricException(LocalAuthExceptionCode.noBiometricsEnrolled), BiometricOutcome.notEnrolled);
      expect(mapBiometricException(LocalAuthExceptionCode.noCredentialsSet), BiometricOutcome.noHardware);
      expect(mapBiometricException(LocalAuthExceptionCode.noBiometricHardware), BiometricOutcome.noHardware);
      expect(mapBiometricException(LocalAuthExceptionCode.temporaryLockout), BiometricOutcome.lockedOut);
      expect(mapBiometricException(LocalAuthExceptionCode.biometricLockout), BiometricOutcome.lockedOut);
      expect(mapBiometricException(LocalAuthExceptionCode.authInProgress), BiometricOutcome.busy);
      expect(mapBiometricException(LocalAuthExceptionCode.uiUnavailable), BiometricOutcome.unavailable);
      expect(mapBiometricException(LocalAuthExceptionCode.deviceError), BiometricOutcome.unavailable);
    });

    test('every outcome has copy except success, and dead ends point at the PIN', () {
      for (final outcome in BiometricOutcome.values) {
        final message = biometricMessage(outcome);
        if (outcome == BiometricOutcome.success) {
          expect(message, isNull);
        } else {
          expect(message, isNotNull);
        }
      }
      // A refused scan must always tell the owner the PIN still works.
      for (final outcome in const [
        BiometricOutcome.cancelled,
        BiometricOutcome.failed,
        BiometricOutcome.lockedOut,
        BiometricOutcome.busy,
        BiometricOutcome.unavailable,
      ]) {
        expect(biometricMessage(outcome)!.toLowerCase(), contains('pin'));
      }
    });
  });

  group('PIN + backup lifecycle (needs codegen tables)', () {
    late AppDatabase db;
    late MemorySecretStore keychain;
    late PinService pins;

    setUp(() async {
      db = AppDatabase.memory();
      keychain = MemorySecretStore();
      pins = PinService(db, secrets: keychain);
    });

    tearDown(() => db.close());

    test('set → verify real, decoy opens demo verdict, wrong fails', () async {
      await pins.setPin('123456');
      await pins.setDecoy('000000');
      expect(await pins.verify('123456'), 'real');
      expect(await pins.verify('000000'), 'decoy');
      expect(await pins.verify('999999'), isNull);
      expect(() => pins.setPin('123'), throwsArgumentError);
    });

    test('no secret ever lands in the plain settings table', () async {
      await pins.setPin('123456');
      await pins.setDecoy('000000');
      await pins.setRecovery(question: 'first school?', answer: 'dps');
      final plain = {for (final r in await db.select(db.settings).get()) r.key};
      expect(plain, isNot(contains(anyOf(secretSettingKeys))));
      expect(keychain.values.keys, isNotEmpty);
      expect(await pins.verifyRecoveryAnswer('DPS'), true);
    });

    test('an .etbak carries no PIN, decoy or recovery hash', () async {
      await pins.setPin('123456');
      await pins.setDecoy('000000');
      await pins.setRecovery(question: 'first school?', answer: 'dps');
      final packed = await encryptBackup(await BackupService(db).dumpTables(), 'pw');
      final tables = await decryptBackup(packed, 'pw');
      final settingsKeys = [
        for (final m in (tables['settings'] as List).cast<Map<String, dynamic>>()) m['key'] as String,
      ];
      expect(settingsKeys, isNot(contains(anyOf(secretSettingKeys))));
    });

    test('export → wipe → import restores everything', () async {
      final txns = TransactionRepository(db);
      final cashId = (await AccountRepository(db).create(name: 'Cash')).id;
      await txns.add(
        kind: 'out',
        actual: -300,
        budgetImpact: -300,
        dateTime: DateTime(2026, 9, 2),
        categoryRaw: 'food lunch meals',
        accountId: cashId,
      );
      await pins.setPin('123456');

      final packed = await encryptBackup(
        {
          'accounts': [for (final r in await db.allAccounts()) r.toJson()],
          'transactions': [for (final r in await db.allTransactions()) r.toJson()],
          'settings': [for (final r in await db.select(db.settings).get()) r.toJson()],
        },
        'pw',
      );

      // Wipe: fresh database, nothing survives.
      await db.close();
      db = AppDatabase.memory();
      expect(await db.allAccounts(), isEmpty);

      final tables = await decryptBackup(packed, 'pw');
      for (final m in (tables['accounts'] as List).cast<Map<String, dynamic>>()) {
        await db.into(db.accounts).insertOnConflictUpdate(Account.fromJson(m).toCompanion(true));
      }
      for (final m in (tables['transactions'] as List).cast<Map<String, dynamic>>()) {
        await db.into(db.transactions).insertOnConflictUpdate(Transaction.fromJson(m).toCompanion(true));
      }
      for (final m in (tables['settings'] as List).cast<Map<String, dynamic>>()) {
        await db.into(db.settings).insertOnConflictUpdate(Setting.fromJson(m).toCompanion(true));
      }

      expect((await db.allAccounts()).single.name, 'Cash');
      expect((await db.allTransactions()).single.actual, -300);
      // The unlock hash is per-device (OS keychain), so it is deliberately not
      // restored from a file: a new device starts without a PIN.
      expect(await PinService(db, secrets: MemorySecretStore()).verify('123456'), isNull);
      expect(await PinService(db, secrets: keychain).verify('123456'), 'real');
    });
  });
}
