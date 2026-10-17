/// Backup service: full database dump → encrypted file and back.
/// Uses only core/database + backup/codec (no feature imports). Drive
/// upload stays manual per PLAN: export writes a file, the user moves it
/// with the Files app. Restoring overwrites conflicting rows (including
/// settings/PIN hashes) — export → delete → import returns identical data.
library;

import 'dart:io';
import 'dart:typed_data';

import '../database.dart';
import '../export/export_paths.dart';
import 'codec.dart';

/// Every table an .etbak carries. Dump, restore and the row-count report all
/// walk this one list, so a new table can never be silently left out again.
const backupTables = [
  'accounts',
  'transactions',
  'budgets',
  'debts',
  'splits',
  'instruments',
  'snapshots',
  'settings',
  'month_open',
  'recurring_rules',
  'groups',
  'group_members',
  'group_expenses',
  'group_payments',
];

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
      'month_open': [for (final r in await db.allMonthOpens()) r.toJson()],
      'recurring_rules': [for (final r in await db.allRecurring()) r.toJson()],
      'groups': [for (final r in await db.allGroups()) r.toJson()],
      'group_members': [for (final r in await db.allMembers()) r.toJson()],
      'group_expenses': [for (final r in await db.allGroupExpenses()) r.toJson()],
      'group_payments': [for (final r in await db.allGroupPayments()) r.toJson()],
    };
  }

  /// Restores every table. Returns per-table row counts.
  Future<Map<String, int>> restoreTables(Map<String, dynamic> tables) async {
    List<Map<String, dynamic>> rows(String name) => [
      for (final m in (tables[name] as List? ?? const [])) (m as Map).cast<String, dynamic>(),
    ];

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
    for (final m in rows('month_open')) {
      await db.into(db.monthOpen).insertOnConflictUpdate(MonthOpenData.fromJson(m).toCompanion(true));
    }
    for (final m in rows('recurring_rules')) {
      await db.into(db.recurringRules).insertOnConflictUpdate(RecurringRule.fromJson(m).toCompanion(true));
    }
    for (final m in rows('groups')) {
      await db.into(db.groups).insertOnConflictUpdate(Group.fromJson(m).toCompanion(true));
    }
    for (final m in rows('group_members')) {
      await db.into(db.groupMembers).insertOnConflictUpdate(GroupMember.fromJson(m).toCompanion(true));
    }
    for (final m in rows('group_expenses')) {
      await db.into(db.groupExpenses).insertOnConflictUpdate(GroupExpense.fromJson(m).toCompanion(true));
    }
    for (final m in rows('group_payments')) {
      await db.into(db.groupPayments).insertOnConflictUpdate(GroupPayment.fromJson(m).toCompanion(true));
    }
    return {
      for (final k in backupTables) k: rows(k).length,
    };
  }

  /// Dumps, encrypts and writes `expensetracker-<date>-<time>.etbak` into
  /// Downloads/ExpenseTracker — a place the Files app can actually see, so
  /// "where did my backup go?" is answerable. Returns the path.
  Future<String> exportToFile(String password) async {
    final packed = await encryptBackup(await dumpTables(), password);
    final paths = await ExportPaths.resolve();
    final file = paths.stamped('etbak');
    return ExportPaths.save(file.uri.pathSegments.last, packed, paths.directory);
  }

  /// Reads + decrypts + restores. Wrong password throws [BackupPasswordError].
  Future<Map<String, int>> importFromFile(String path, String password) async {
    final packed = await File(path).readAsBytes();
    final tables = await decryptBackup(Uint8List.fromList(packed), password);
    return restoreTables(tables);
  }
}
