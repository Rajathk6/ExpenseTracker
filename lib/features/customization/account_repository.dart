/// Account repository: user-defined money sources/dests (banks, cash, cards...).
/// `kind` is freeform text — the DB never constrains it, UI only suggests.
library;

import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:uuid/uuid.dart';

import '../../core/database.dart';

/// Suggested kinds for the picker. Suggestions only — any string is accepted.
const suggestedAccountKinds = ['bank', 'cash', 'card', 'wallet', 'upi'];

class AccountRepository {
  final AppDatabase db;
  const AccountRepository(this.db);

  Future<List<Account>> list() => db.allAccounts();

  Stream<List<Account>> watch() => db.watchAccounts();

  Future<Account> create({required String name, String kind = 'cash', double openingBalance = 0, String? note}) async {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Account name cannot be empty');
    final entry = AccountsCompanion(
      id: Value(const Uuid().v4()),
      name: Value(clean),
      kind: Value(kind.trim().isEmpty ? 'cash' : kind.trim().toLowerCase()),
      openingBalance: Value(openingBalance),
      note: Value(note),
    );
    try {
      await db.into(db.accounts).insert(entry);
    } on SqliteException catch (e) {
      if (e.message.contains('UNIQUE')) throw StateError('Account "$clean" already exists');
      rethrow;
    }
    return db.getAccount(entry.id.value);
  }

  Future<void> rename(String id, String name) async {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Account name cannot be empty');
    try {
      await (db.update(db.accounts)..where((a) => a.id.equals(id))).write(AccountsCompanion(name: Value(clean)));
    } on SqliteException catch (e) {
      if (e.message.contains('UNIQUE')) throw StateError('Account "$clean" already exists');
      rethrow;
    }
  }

  Future<void> remove(String id) => db.deleteAccount(id);
}
