import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/groups/group_repository.dart';
import 'package:expense_tracker/features/groups/group_sync.dart';

Map<String, dynamic> _payload({
  required String id,
  required String code,
  required String name,
  required String updatedAt,
  List<String> members = const ['Me'],
  List<Map<String, dynamic>> expenses = const [],
  List<Map<String, dynamic>> payments = const [],
}) =>
    <String, dynamic>{
      'id': id,
      'code': code,
      'name': name,
      'month': '2026-10',
      'note': null,
      'status': 'open',
      'updatedAt': updatedAt,
      'members': members,
      'expenses': expenses,
      'payments': payments,
    };

void main() {
  test('the merge keeps both phones\' expenses and the newest metadata', () {
    final local = _payload(
      id: 'g1',
      code: 'ET-ABCD1234',
      name: 'Flat (old name)',
      updatedAt: '2026-10-01T10:00:00.000Z',
      members: const ['Me', 'Ravi'],
      expenses: [
        {'id': 'e1', 'title': 'Milk', 'amount': 40, 'paidBy': 'Me', 'sharedWith': <String>[], 'at': '2026-10-01'},
      ],
    );
    final remote = _payload(
      id: 'g1',
      code: 'ET-ABCD1234',
      name: 'Flat',
      updatedAt: '2026-10-02T10:00:00.000Z',
      members: const ['Me', 'Asha'],
      expenses: [
        {'id': 'e2', 'title': 'Bread', 'amount': 50, 'paidBy': 'Asha', 'sharedWith': <String>[], 'at': '2026-10-02'},
      ],
      payments: [
        {'id': 'p1', 'paidBy': 'Ravi', 'paidTo': 'Me', 'amount': 20, 'at': '2026-10-02'},
      ],
    );

    final merged = mergeGroupPayloads(local: local, remote: remote);
    expect(merged['name'], 'Flat', reason: 'newer remote metadata wins');
    expect((merged['members'] as List).toSet(), {'Me', 'Ravi', 'Asha'});
    expect([for (final e in merged['expenses'] as List) e['id']], ['e1', 'e2']);
    expect((merged['payments'] as List).single['id'], 'p1');
    expect(merged['updatedAt'], '2026-10-02T10:00:00.000Z');
  });

  test('a newer local rename beats older remote metadata without dropping remote rows', () {
    final local = _payload(
      id: 'g1',
      code: 'ET-ABCD1234',
      name: 'Trip',
      updatedAt: '2026-10-03T10:00:00.000Z',
      expenses: [
        {'id': 'e1', 'title': 'Taxi', 'amount': 200, 'paidBy': 'Me', 'sharedWith': <String>[], 'at': '2026-10-03'},
      ],
    );
    final remote = _payload(
      id: 'g1',
      code: 'ET-ABCD1234',
      name: 'Old trip',
      updatedAt: '2026-10-02T10:00:00.000Z',
      expenses: [
        {'id': 'e2', 'title': 'Coffee', 'amount': 80, 'paidBy': 'Ravi', 'sharedWith': <String>[], 'at': '2026-10-02'},
      ],
    );

    final merged = mergeGroupPayloads(local: local, remote: remote);
    expect(merged['name'], 'Trip');
    expect([for (final e in merged['expenses'] as List) e['id']], ['e1', 'e2']);
  });

  test('missing Firebase is reported instead of crashing the app', () async {
    if (Firebase.apps.isNotEmpty) return;
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final service = GroupSyncService(db, GroupRepository(db));
    await expectLater(service.sync(), throwsA(isA<GroupSyncUnavailable>()));
  });

  test('the demo vault cannot sync', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final service = GroupSyncService(db, GroupRepository(db), enabled: false);
    await expectLater(service.sync(), throwsA(isA<GroupSyncDisabled>()));
  });

  test('new group codes are long enough to act as an invite secret', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final group = await GroupRepository(db).create(
      name: 'Flat',
      monthKey: '2026-10',
      people: const ['Me'],
    );
    expect(group.code, startsWith('ET-'));
    expect(group.code.length, 11);
  });
}
