/// Account repository: user-defined money sources/dests (banks, cash, cards...).
/// `kind` is freeform text — the DB never constrains it, UI only suggests.
library;

import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:uuid/uuid.dart';

import '../../core/database.dart';

/// Suggested kinds for the picker. Suggestions only — any string is accepted.
const suggestedAccountKinds = ['bank', 'cash', 'card', 'wallet', 'upi'];

/// An account with the money that is actually in it.
class AccountWithBalance {
  final Account account;

  /// What was there when the account was created.
  final double opening;

  /// Everything that has moved through it since (spending, income, transfers).
  final double moved;

  /// What is in it now.
  final double balance;

  const AccountWithBalance({
    required this.account,
    required this.opening,
    required this.moved,
    required this.balance,
  });

  String get name => account.name;
  String get kind => account.kind;
}

class AccountRepository {
  final AppDatabase db;
  const AccountRepository(this.db);

  Future<List<Account>> list() => db.allAccounts();

  Stream<List<Account>> watch() => db.watchAccounts();

  /// Every account with its **real** balance: the opening amount plus every
  /// movement that has passed through it. An account that only shows a name
  /// and a kind is a label, not a wallet — this is what makes the number on
  /// the net-worth screen and the money in the account the same number.
  Future<List<AccountWithBalance>> balances() async {
    final accounts = await db.allAccounts();
    final rows = await db.allTransactions();
    final moved = <String, double>{};
    for (final t in rows) {
      final id = t.accountId;
      if (id == null) continue;
      moved[id] = (moved[id] ?? 0) + t.actual;
    }
    return [
      for (final a in accounts)
        AccountWithBalance(
          account: a,
          opening: a.openingBalance,
          moved: moved[a.id] ?? 0,
          balance: a.openingBalance + (moved[a.id] ?? 0),
        ),
    ];
  }

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

  /// Changes the opening balance — the "money I had in this account when I
  /// started using it". Editing the amount is how a balance gets corrected.
  Future<void> setOpeningBalance(String id, double amount) async {
    await (db.update(db.accounts)..where((a) => a.id.equals(id)))
        .write(AccountsCompanion(openingBalance: Value(amount)));
  }

  Future<void> remove(String id) => db.deleteAccount(id);
}
