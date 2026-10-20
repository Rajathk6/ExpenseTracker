/// Groups: the Splitwise-style contract the owner asked for — a name, the
/// month it covers, the people in it and a short code they can read out.
///
/// Every phone that enters the same code gets the same [groupId], which is
/// what makes "add or track the same" work. **Honest limitation:** rows
/// themselves stay on the phone that created them. Two devices only see each
/// other's data once a server is involved, which is out of scope for an
/// offline-first app — see ARCHITECTURE.md. The seam for that is
/// [GroupRepository.exportGroup] / [importGroup], which produce and consume
/// exactly the payload a sync service would send.
library;

import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/database.dart';

/// Net position per participant. Positive = the group owes them, negative =
/// they owe the group. Everyone sums to zero (rounding aside).
class Balance {
  final String name;
  final double net;
  const Balance(this.name, this.net);
  bool get isOwed => net > 0.005;
  bool get owes => net < -0.005;
}

class GroupBalances {
  final String groupId;
  final String name;
  final String code;
  final String monthKey;
  final List<Balance> balances;
  final double totalSpent;

  const GroupBalances({
    required this.groupId,
    required this.name,
    required this.code,
    required this.monthKey,
    required this.balances,
    required this.totalSpent,
  });

  /// "Ravi pays Me ₹240" — the minimum set of transfers to settle up.
  List<({String from, String to, double amount})> get settleUp {
    final debtors = [
      for (final b in balances)
        if (b.owes) (name: b.name, amount: -b.net),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    final creditors = [
      for (final b in balances)
        if (b.isOwed) (name: b.name, amount: b.net),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    final out = <({String from, String to, double amount})>[];
    var i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      final pay = debtors[i].amount < creditors[j].amount ? debtors[i].amount : creditors[j].amount;
      out.add((from: debtors[i].name, to: creditors[j].name, amount: (pay * 100).round() / 100));
      debtors[i] = (name: debtors[i].name, amount: debtors[i].amount - pay);
      creditors[j] = (name: creditors[j].name, amount: creditors[j].amount - pay);
      if (debtors[i].amount <= 0.005) i++;
      if (creditors[j].amount <= 0.005) j++;
    }
    return out;
  }
}

final _monthRe = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');

class GroupRepository {
  final AppDatabase db;
  const GroupRepository(this.db);

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Creates a group. [people] must be non-empty: an unnamed group has no
  /// balances to show (#14).
  Future<Group> create({
    required String name,
    required String monthKey,
    required List<String> people,
    String? note,
    String? code,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Give the group a name');
    if (!_monthRe.hasMatch(monthKey)) {
      throw ArgumentError('Month must be YYYY-MM (got "$monthKey")');
    }
    final names = [for (final p in people) p.trim()].where((p) => p.isNotEmpty).toList();
    if (names.isEmpty) throw ArgumentError('Add at least one person');
    if (<String>{for (final n in names) n.toLowerCase()}.length != names.length) {
      throw ArgumentError('The same name is listed twice');
    }
    final random = Random.secure();
    String newCode() => 'ET-${List.generate(4, (_) => _alphabet[random.nextInt(_alphabet.length)]).join()}';
    final wanted = code?.trim().toUpperCase();
    if (wanted != null && wanted.isNotEmpty && await db.groupByCode(wanted) != null) {
      throw ArgumentError('That code $wanted is already used by another group');
    }
    final id = const Uuid().v4();
    await db.upsertGroup(
      GroupsCompanion(
        id: Value(id),
        name: Value(clean),
        code: Value(wanted == null || wanted.isEmpty ? newCode() : wanted),
        monthKey: Value(monthKey),
        note: Value(note != null && note.trim().isNotEmpty ? note.trim() : null),
      ),
    );
    for (final person in names) {
      await db.insertMember(
        GroupMembersCompanion(id: Value(const Uuid().v4()), groupId: Value(id), name: Value(person)),
      );
    }
    return (await db.getGroup(id))!;
  }

  /// Joins an existing group with its share code: same id, same people, same
  /// balances — the part of Splitwise that works without a server.
  Future<Group> join({required String code, required List<String> people, String? name, String? monthKey}) async {
    final found = await db.groupByCode(code);
    if (found == null) throw ArgumentError('No group with code $code on this phone yet');
    final existing = <String>{for (final m in await db.membersOf(found.id)) m.name.toLowerCase()};
    for (final person in people.where((p) => p.trim().isNotEmpty)) {
      final clean = person.trim();
      if (existing.add(clean.toLowerCase())) {
        await db.insertMember(
          GroupMembersCompanion(id: Value(const Uuid().v4()), groupId: Value(found.id), name: Value(clean)),
        );
      }
    }
    return found;
  }

  Future<List<Group>> all() => db.allGroups();

  Future<Group?> byCode(String code) => db.groupByCode(code);

  Future<List<GroupMember>> people(String groupId) => db.membersOf(groupId);

  Future<List<GroupExpense>> expenses(String groupId) => db.expensesOf(groupId);

  Future<List<GroupPayment>> payments(String groupId) => db.paymentsOf(groupId);

  /// Renames a group, moves it to another month and fixes the people in it.
  Future<void> update({
    required String groupId,
    required String name,
    required String monthKey,
    required List<String> people,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Give the group a name');
    if (!_monthRe.hasMatch(monthKey)) {
      throw ArgumentError('Month must be YYYY-MM (got "$monthKey")');
    }
    final names = [for (final p in people) p.trim()].where((p) => p.isNotEmpty).toList();
    if (names.isEmpty) throw ArgumentError('A group needs at least one person');
    await db.upsertGroup(
      GroupsCompanion(
        id: Value(groupId),
        name: Value(clean),
        monthKey: Value(monthKey),
      ),
    );
    final existing = [for (final m in await db.membersOf(groupId)) m.name];
    for (final person in names) {
      if (!existing.contains(person)) {
        await db.insertMember(
          GroupMembersCompanion(id: Value(const Uuid().v4()), groupId: Value(groupId), name: Value(person)),
        );
      }
    }
    for (final member in await db.membersOf(groupId)) {
      if (!names.contains(member.name)) {
        await db.deleteMember(member.id);
      }
    }
  }

  Future<void> close(String groupId) => db.upsertGroup(
        GroupsCompanion(id: Value(groupId), status: const Value('closed')),
      );

  /// Adds something the group spent. When [paidBy] is left empty the money is
  /// split evenly between everybody, which is the common case.
  Future<GroupExpense> addExpense({
    required String groupId,
    required String title,
    required double amount,
    String? paidBy,
    DateTime? at,
    String? note,
  }) async {
    if (amount <= 0) throw ArgumentError('Amount must be above zero');
    final members = [for (final m in await db.membersOf(groupId)) m.name];
    if (members.isEmpty) throw ArgumentError('Add people to the group first');
    final payer = (paidBy == null || paidBy.trim().isEmpty) ? '' : paidBy.trim();
    if (payer.isNotEmpty && !members.contains(payer)) {
      throw ArgumentError('$payer is not in this group');
    }
    final id = const Uuid().v4();
    await db.insertGroupExpense(
      GroupExpensesCompanion(
        id: Value(id),
        groupId: Value(groupId),
        title: Value(title.trim().isEmpty ? 'Expense' : title.trim()),
        amount: Value(amount),
        paidBy: Value(payer),
        occurredAt: Value(at ?? DateTime.now()),
        note: Value(note != null && note.trim().isNotEmpty ? note.trim() : null),
      ),
    );
    return (await db.expensesOf(groupId)).firstWhere((e) => e.id == id);
  }

  /// Records a pay-up between two members. Recorded on both sides' books the
  /// same way, which is what makes a settlement visible to everyone in the
  /// group rather than only to the phone that typed it.
  Future<GroupPayment> addPayment({
    required String groupId,
    required String paidBy,
    required String paidTo,
    required double amount,
    DateTime? at,
    String? note,
  }) async {
    if (amount <= 0) throw ArgumentError('Amount must be above zero');
    final members = {for (final m in await db.membersOf(groupId)) m.name};
    if (!members.contains(paidBy.trim())) throw ArgumentError('$paidBy is not in this group');
    if (!members.contains(paidTo.trim())) throw ArgumentError('$paidTo is not in this group');
    // A pay-up to yourself moves nothing (#8).
    if (paidBy.trim().toLowerCase() == paidTo.trim().toLowerCase()) {
      throw ArgumentError('That would be paying yourself');
    }
    final id = const Uuid().v4();
    await db.insertGroupPayment(
      GroupPaymentsCompanion(
        id: Value(id),
        groupId: Value(groupId),
        paidBy: Value(paidBy.trim()),
        paidTo: Value(paidTo.trim()),
        amount: Value(amount),
        occurredAt: Value(at ?? DateTime.now()),
        note: Value(note?.trim().isEmpty ?? true ? null : note!.trim()),
      ),
    );
    return (await db.paymentsOf(groupId)).firstWhere((p) => p.id == id);
  }

  /// Who owes whom, right now. Even splits by default; an expense paid by
  /// someone is credited to them.
  Future<GroupBalances> balances(String groupId) async {
    final group = (await db.getGroup(groupId))!;
    final members = [for (final m in await db.membersOf(groupId)) m.name];
    final net = <String, double>{for (final m in members) m: 0};
    var total = 0.0;

    for (final expense in await db.expensesOf(groupId)) {
      total += expense.amount;
      // An expense with nobody recorded as paying is shared cost only: it moves
      // nobody's position, so balances stay even. Recording a payer credits
      // them the whole amount and gives everyone else their share back.
      if (expense.paidBy.isEmpty) continue;
      final share = expense.amount / members.length;
      for (final m in members) {
        net[m] = net[m]! - share;
      }
      net[expense.paidBy] = net[expense.paidBy]! + expense.amount;
    }
    for (final payment in await db.paymentsOf(groupId)) {
      net[payment.paidBy] = net[payment.paidBy]! + payment.amount;
      net[payment.paidTo] = net[payment.paidTo]! - payment.amount;
    }
    return GroupBalances(
      groupId: groupId,
      name: group.name,
      code: group.code,
      monthKey: group.monthKey,
      balances: [for (final m in members) Balance(m, (net[m]! * 100).round() / 100)],
      totalSpent: total,
    );
  }

  /// The payload a sync service would carry. Complete for one group, so a
  /// future backend (or a second phone via a file) has everything it needs.
  Future<Map<String, dynamic>> exportGroup(String groupId) async {
    final group = (await db.getGroup(groupId))!;
    return {
      'id': group.id,
      'name': group.name,
      'code': group.code,
      'month': group.monthKey,
      'note': group.note,
      'status': group.status,
      'members': [for (final m in await db.membersOf(groupId)) m.name],
      'expenses': [
        for (final e in await db.expensesOf(groupId))
          {
            'id': e.id,
            'title': e.title,
            'amount': e.amount,
            'paidBy': e.paidBy,
            'at': e.occurredAt.toIso8601String(),
            'note': e.note,
          },
      ],
      'payments': [
        for (final p in await db.paymentsOf(groupId))
          {
            'id': p.id,
            'paidBy': p.paidBy,
            'paidTo': p.paidTo,
            'amount': p.amount,
            'at': p.occurredAt.toIso8601String(),
            'note': p.note,
          },
      ],
    };
  }

  /// Merges an exported group in, keeping the code (so both phones agree on
  /// identity) and not duplicating rows that are already there.
  Future<Group?> importGroup(Map<String, dynamic> json) async {
    final id = json['id'];
    final code = json['code'];
    final name = json['name'];
    final month = json['month'];
    if (id is! String || code is! String || name is! String || month is! String) {
      throw ArgumentError('That file is not a group export');
    }
    final existing = await db.getGroup(id) ?? await db.groupByCode(code);
    final groupId = existing?.id ?? id;
    await db.upsertGroup(
      GroupsCompanion(
        id: Value(groupId),
        name: Value(name),
        code: Value(code),
        monthKey: Value(month),
        note: Value(json['note'] as String?),
        status: Value((json['status'] as String?) ?? 'open'),
      ),
    );
    final members = await db.membersOf(groupId);
    final have = {for (final m in members) m.name.toLowerCase()};
    for (final person in (json['members'] as List? ?? const []).cast<String>()) {
      if (have.add(person.trim().toLowerCase())) {
        await db.insertMember(
          GroupMembersCompanion(id: Value(const Uuid().v4()), groupId: Value(groupId), name: Value(person.trim())),
        );
      }
    }
    final expenseIds = {for (final e in await db.expensesOf(groupId)) e.id};
    for (final raw in (json['expenses'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final expenseId = raw['id'] as String;
      if (!expenseIds.add(expenseId)) continue;
      await db.insertGroupExpense(
        GroupExpensesCompanion(
          id: Value(expenseId),
          groupId: Value(groupId),
          title: Value(raw['title'] as String? ?? 'Expense'),
          amount: Value((raw['amount'] as num).toDouble()),
          paidBy: Value(raw['paidBy'] as String? ?? ''),
          occurredAt: Value(DateTime.tryParse(raw['at'] as String? ?? '') ?? DateTime.now()),
          note: Value(raw['note'] as String?),
        ),
      );
    }
    final paymentIds = {for (final p in await db.paymentsOf(groupId)) p.id};
    for (final raw in (json['payments'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final paymentId = raw['id'] as String;
      if (!paymentIds.add(paymentId)) continue;
      await db.insertGroupPayment(
        GroupPaymentsCompanion(
          id: Value(paymentId),
          groupId: Value(groupId),
          paidBy: Value(raw['paidBy'] as String? ?? ''),
          paidTo: Value(raw['paidTo'] as String? ?? ''),
          amount: Value((raw['amount'] as num).toDouble()),
          occurredAt: Value(DateTime.tryParse(raw['at'] as String? ?? '') ?? DateTime.now()),
          note: Value(raw['note'] as String?),
        ),
      );
    }
    return db.getGroup(groupId);
  }

  /// The same payload as text — for a share sheet, a file or a future API call.
  Future<String> encodeGroup(String groupId) async => jsonEncode(await exportGroup(groupId));

  Future<Group?> decodeGroup(String raw) async => importGroup(jsonDecode(raw) as Map<String, dynamic>);
}