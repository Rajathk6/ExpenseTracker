/// Split repository: group expenses I fronted.
/// Initial entry: actual=-total (bank truth), budgetImpact=-myShare.
/// Settlements: actual=+amount, budget 0. Absorb (default): actual 0,
/// budgetImpact=-amount — unpaid money becomes my expense, honestly.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/database.dart';
import 'split_logic.dart';

class SplitRepository {
  final AppDatabase db;
  const SplitRepository(this.db);

  Future<Split> create({
    required String title,
    required double total,
    required double myShare,
    List<String> members = const [],
    String? accountId,
    DateTime? at,
    String? note,
    String? categoryRaw,
  }) async {
    final clean = title.trim();
    if (clean.isEmpty) throw ArgumentError('Title cannot be empty');
    final err = validateSplit(total: total, myShare: myShare);
    if (err != null) throw ArgumentError(err);
    final id = const Uuid().v4();
    await db.insertSplit(
      SplitsCompanion(
        id: Value(id),
        title: Value(clean),
        totalPaid: Value(total),
        myShare: Value(myShare),
        membersJson: Value(jsonEncode(members.map((m) => m.trim()).where((m) => m.isNotEmpty).toList())),
      ),
    );
    if (note != null && note.trim().isNotEmpty) {
      await db.updateSplit(id, SplitsCompanion(note: Value(note.trim())));
    }
    await db.insertTransaction(
      TransactionsCompanion(
        id: Value(const Uuid().v4()),
        kind: const Value('split'),
        actual: Value(-total),
        budgetImpact: Value(-myShare),
        occurredAt: Value(at ?? DateTime.now()),
        categoryRaw: Value(categoryRaw ?? 'split $clean'),
        level0: const Value('split'),
        level1: Value(clean.toLowerCase()),
        note: Value(note),
        accountId: Value(accountId),
        linkId: Value(id),
        linkType: const Value('split'),
      ),
    );
    return db.getSplit(id);
  }

  /// Records money coming back from the group.
  Future<Split> settle({required String splitId, required double amount, String? who, String? accountId, DateTime? at}) async {
    final split = await db.getSplit(splitId);
    if (split.status != 'open') throw StateError('Split is already closed');
    final err = validateSettlement(
      amount: amount,
      totalPaid: split.totalPaid,
      myShare: split.myShare,
      received: split.received,
      absorbed: split.absorbed,
    );
    if (err != null) throw ArgumentError(err);
    await db.insertTransaction(
      TransactionsCompanion(
        id: Value(const Uuid().v4()),
        kind: const Value('settle'),
        actual: Value(amount),
        budgetImpact: const Value(0),
        occurredAt: Value(at ?? DateTime.now()),
        categoryRaw: Value('split ${split.title}'),
        level0: const Value('split'),
        level1: Value(split.title.toLowerCase()),
        note: Value(who == null || who.trim().isEmpty ? null : 'from ${who.trim()}'),
        accountId: Value(accountId),
        linkId: Value(splitId),
        linkType: const Value('split'),
      ),
    );
    return _bump(splitId, received: split.received + amount, absorbed: split.absorbed);
  }

  /// Writes off unpaid money as my own expense (budgetImpact only).
  /// Use when someone will never pay: honest books, closed contract.
  Future<Split> absorb({required String splitId, required double amount, String? note, DateTime? at}) async {
    final split = await db.getSplit(splitId);
    if (split.status != 'open') throw StateError('Split is already closed');
    if (amount <= 0) throw ArgumentError('Amount must be above zero');
    if (amount > splitRemaining(split.totalPaid, split.myShare, split.received, split.absorbed) + 0.005) {
      throw ArgumentError('Cannot absorb more than the outstanding amount');
    }
    await db.insertTransaction(
      TransactionsCompanion(
        id: Value(const Uuid().v4()),
        kind: const Value('absorb'),
        actual: const Value(0),
        budgetImpact: Value(-amount),
        occurredAt: Value(at ?? DateTime.now()),
        categoryRaw: Value('split ${split.title}'),
        level0: const Value('split'),
        level1: Value(split.title.toLowerCase()),
        note: Value(note ?? 'absorbed default'),
        linkId: Value(splitId),
        linkType: const Value('split'),
      ),
    );
    return _bump(splitId, received: split.received, absorbed: split.absorbed + amount);
  }

  Future<Split> _bump(String splitId, {required double received, required double absorbed}) async {
    final split = await db.getSplit(splitId);
    final closed = splitRemaining(split.totalPaid, split.myShare, received, absorbed) <= 0.005;
    await db.updateSplit(
      splitId,
      SplitsCompanion(
        received: Value(received),
        absorbed: Value(absorbed),
        status: Value(closed ? 'closed' : 'open'),
      ),
    );
    return db.getSplit(splitId);
  }

  Future<List<Split>> open() => db.openSplits();
  Future<List<Split>> all() => db.allSplits();
  Future<List<Transaction>> history(String splitId) => db.splitHistory(splitId);

  List<String> membersOf(Split split) =>
      (jsonDecode(split.membersJson) as List).map((e) => e.toString()).toList();
}
