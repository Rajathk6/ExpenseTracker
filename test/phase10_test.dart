import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/auth/pin_service.dart';
import 'package:expense_tracker/core/backup/codec.dart';
import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';

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
            {'id': 'a1', 'name': 'Cash', 'kind': 'cash'}
          ],
          'transactions': [
            {'id': 't1', 'kind': 'out', 'actual': -300.0}
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

  group('PIN + backup lifecycle (needs codegen tables)', () {
    late AppDatabase db;
    late PinService pins;

    setUp(() async {
      db = AppDatabase.memory();
      pins = PinService(db);
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
      expect(await PinService(db).verify('123456'), 'real');
    });
  });
}
