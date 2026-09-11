/// Backup service: full database dump → encrypted file and back.
/// Uses only core/database + backup/codec (no feature imports). Drive
/// upload stays manual per PLAN: export writes a file, the user moves it
/// with the Files app. Restoring overwrites conflicting rows (including
/// settings/PIN hashes) — export → delete → import returns identical data.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database.dart';
import 'codec.dart';

class BackupService {
  final AppDatabase db;
  const BackupService(this.db);

  Future<Map<String, dynamic>> dumpTables() async {
    final settingsRows = await db.select(db.settings).get();
    return {
      'accounts': [for (final r in await db.allAccounts()) r.toJson()],
      'transactions': [for (final r in await db.allTransactions()) r.toJson()],
      'budgets': [for (final r in await db.allBudgets()) r.toJson()],
      'debts': [for (final r in await db.allDebts()) r.toJson()],
      'splits': [for (final r in await db.allSplits()) r.toJson()],
      'instruments': [for (final r in await db.allInstruments()) r.toJson()],
      'snapshots': [for (final r in await db.allSnapshots()) r.toJson()],
      'settings': [for (final r in settingsRows) r.toJson()],
    };
  }

  /// Restores every table. Returns per-table row counts.
  Future<Map<String, int>> restoreTables(Map<String, dynamic> tables) async {
    List<Map<String, dynamic>> rows(String name) =>
        [(for (final m in (tables[name] as List? ?? [])) (m as Map).cast<String, dynamic>())];

    for (final m in rows('accounts')) {
      await db.into(db.accounts).insertOnConflictUpdate(Account.fromJson(m).toCompanion(true));
    }
    for (final m in rows('transactions')) {
      await db.into(db.transactions).insertOnConflictUpdate(Transaction.fromJson(m).toCompanion(true));
    }
    for (final m in rows('budgets')) {
      await db.into(db.budgets).insertOnConflictUpdate(Budget.fromJson(m).toCompanion(true));
    }
    for (final m in rows('debts')) {
      await db.into(db.debts).insertOnConflictUpdate(Debt.fromJson(m).toCompanion(true));
    }
    for (final m in rows('splits')) {
      await db.into(db.splits).insertOnConflictUpdate(Split.fromJson(m).toCompanion(true));
    }
    for (final m in rows('instruments')) {
      await db.into(db.instruments).insertOnConflictUpdate(Instrument.fromJson(m).toCompanion(true));
    }
    for (final m in rows('snapshots')) {
      await db.into(db.snapshots).insertOnConflictUpdate(Snapshot.fromJson(m).toCompanion(true));
    }
    for (final m in rows('settings')) {
      await db.into(db.settings).insertOnConflictUpdate(Setting.fromJson(m).toCompanion(true));
    }
    return {
      for (final k in const ['accounts', 'transactions', 'budgets', 'debts', 'splits', 'instruments', 'snapshots', 'settings'])
        k: rows(k).length,
    };
  }

  /// Dumps, encrypts and writes `expensetracker-<date>.etbak`. Returns path.
  /// Upload the file to Drive with the Files app (manual step per PLAN).
  Future<String> exportToFile(String password) async {
    final packed = await encryptBackup(await dumpTables(), password);
    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final name = 'expensetracker-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.etbak';
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(packed, flush: true);
    return file.path;
  }

  /// Reads + decrypts + restores. Wrong password throws [BackupPasswordError].
  Future<Map<String, int>> importFromFile(String path, String password) async {
    final packed = await File(path).readAsBytes();
    final tables = await decryptBackup(Uint8List.fromList(packed), password);
    return restoreTables(tables);
  }
}
