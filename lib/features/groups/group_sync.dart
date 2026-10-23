/// Optional group sync: a Firestore mirror of group payloads with anonymous
/// Firebase auth. Local Drift stays the source of truth; only group rows are
/// uploaded, and only after the owner opens the Groups tab or taps Sync.
///
/// A group document is keyed by its share code:
/// `groups/{code}` → `{code, ownerUid, memberUids, data, updatedAt}`, where
/// `data` is the same payload [GroupRepository.exportGroup] produces. Reads
/// merge remote rows into local before writes, and writes use a transaction so
/// two phones adding expenses at once keep both rows.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/database.dart';
import 'group_repository.dart';

const _groupsCollection = 'groups';
const _uidSettingKey = 'sync.firebase.uid';

String _ownerSettingKey(String code) => 'sync.firebase.owner.$code';

class GroupSyncUnavailable implements Exception {
  final String message;
  const GroupSyncUnavailable(this.message);

  @override
  String toString() => message;
}

class GroupSyncDisabled implements Exception {
  @override
  String toString() => 'Group sync is off in the demo vault.';
}

class GroupSyncBusy implements Exception {
  @override
  String toString() => 'A sync is already running. Try again in a moment.';
}

class GroupSyncNotFound implements Exception {
  final String message;
  const GroupSyncNotFound(this.message);

  @override
  String toString() => message;
}

class GroupSyncNotMember implements Exception {
  @override
  String toString() => 'This phone has not joined that group yet.';
}

class GroupSyncResult {
  final String? uid;
  final int pulled;
  final int pushed;
  final int localGroups;
  final List<String> errors;

  const GroupSyncResult({
    required this.uid,
    required this.pulled,
    required this.pushed,
    required this.localGroups,
    required this.errors,
  });
}

DateTime? _parseTime(Object? value) {
  if (value is String) return DateTime.tryParse(value);
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

Object? _plain(Object? value) {
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries) '${entry.key}': _plain(entry.value),
    };
  }
  if (value is Iterable) return [for (final item in value) _plain(item)];
  return value;
}

Map<String, dynamic>? _map(Object? value) {
  final plain = _plain(value);
  return plain is Map<String, dynamic> ? plain : null;
}

List<String> _strings(Object? value) {
  if (value is! Iterable) return const [];
  return [for (final item in value) if (item is String) item];
}

String? _string(Object? value) => value is String ? value : null;

DateTime? _payloadTime(Map<String, dynamic> payload) => _parseTime(payload['updatedAt']);

List<String> _mergeNames(Map<String, dynamic> local, Map<String, dynamic> remote) {
  final seen = <String>{};
  final out = <String>[];
  for (final name in [..._strings(local['members']), ..._strings(remote['members'])]) {
    final clean = name.trim();
    final key = clean.toLowerCase();
    if (clean.isEmpty || !seen.add(key)) continue;
    out.add(clean);
  }
  return out;
}

List<Map<String, dynamic>> _mergeRows(Map<String, dynamic> local, Map<String, dynamic> remote, String key) {
  final seen = <String>{};
  final out = <Map<String, dynamic>>[];
  for (final source in [local, remote]) {
    for (final raw in (source[key] as Iterable? ?? const [])) {
      final row = _map(raw);
      if (row == null) continue;
      final id = _string(row['id']);
      if (id == null || !seen.add(id)) continue;
      out.add(row);
    }
  }
  return out;
}

bool _hasRowsMissingFromRemote(Map<String, dynamic> local, Map<String, dynamic> remote) {
  final localMembers = {
    for (final name in _strings(local['members'])) name.trim().toLowerCase(),
  };
  final remoteMembers = {
    for (final name in _strings(remote['members'])) name.trim().toLowerCase(),
  };
  if (!remoteMembers.containsAll(localMembers)) return true;

  for (final key in ['expenses', 'payments']) {
    final remoteIds = {
      for (final row in (remote[key] as Iterable? ?? const []))
        if (_map(row)?['id'] is String) _map(row)!['id'] as String,
    };
    for (final row in (local[key] as Iterable? ?? const [])) {
      final id = _map(row)?['id'];
      if (id is String && !remoteIds.contains(id)) return true;
    }
  }
  return false;
}

/// Union-merge two exported group payloads. Metadata comes from the side with
/// the newer `updatedAt`; members, expenses and payments are unioned by name/id.
Map<String, dynamic> mergeGroupPayloads({
  required Map<String, dynamic> local,
  required Map<String, dynamic> remote,
}) {
  final localTime = _payloadTime(local);
  final remoteTime = _payloadTime(remote);
  final localIsNewer = localTime != null && (remoteTime == null || localTime.isAfter(remoteTime));
  final base = localIsNewer ? local : remote;
  final maxTime = [localTime, remoteTime].whereType<DateTime>().fold<DateTime?>(
        null,
        (latest, value) => latest == null || value.isAfter(latest) ? value : latest,
      );
  return <String, dynamic>{
    'id': _string(base['id']) ?? _string(local['id']) ?? _string(remote['id']),
    'code': _string(base['code']) ?? _string(local['code']) ?? _string(remote['code']),
    'name': _string(base['name']) ?? _string(local['name']) ?? _string(remote['name']),
    'month': _string(base['month']) ?? _string(local['month']) ?? _string(remote['month']),
    'note': base['note'],
    'status': _string(base['status']) ?? 'open',
    'updatedAt': (maxTime ?? DateTime.now()).toIso8601String(),
    'members': _mergeNames(local, remote),
    'expenses': _mergeRows(local, remote, 'expenses'),
    'payments': _mergeRows(local, remote, 'payments'),
  };
}

String groupSyncErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    if (error.code == 'operation-not-allowed' || error.code == 'admin-restricted-operation') {
      return 'Anonymous sign-in is disabled in Firebase. Enable Authentication → Anonymous.';
    }
    return 'Firebase sign-in failed: ${error.message ?? error.code}';
  }
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Firestore rejected the group data. Deploy firestore.rules from the repo.';
    }
    if (error.code == 'unavailable') return 'Firebase is unreachable. The group stayed on this phone.';
    if (error.code == 'failed-precondition') return 'Firestore is not ready: ${error.message ?? error.code}';
    return 'Firebase ${error.code}: ${error.message ?? 'unknown error'}';
  }
  return error.toString();
}

class GroupSyncService {
  final AppDatabase db;
  final GroupRepository groups;
  final bool enabled;
  final void Function()? onChanged;
  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _storeOverride;

  bool _started = false;
  bool _busy = false;
  bool _applyingRemote = false;
  bool _pushPending = false;
  String? _lastError;
  Timer? _pushTimer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteSub;
  StreamSubscription<dynamic>? _localSub;

  GroupSyncService(
    this.db,
    this.groups, {
    this.enabled = true,
    this.onChanged,
    FirebaseAuth? auth,
    FirebaseFirestore? store,
  })  : _authOverride = auth,
        _storeOverride = store;

  String? get lastError => _lastError;
  bool get running => _started;

  void _ensureFirebase() {
    if (_authOverride != null && _storeOverride != null) return;
    if (Firebase.apps.isEmpty) {
      throw const GroupSyncUnavailable(
        'Firebase is not initialized. Rebuild the app after adding firebase_options.dart.',
      );
    }
  }

  FirebaseAuth get _auth {
    _ensureFirebase();
    return _authOverride ?? FirebaseAuth.instance;
  }

  FirebaseFirestore get _store {
    _ensureFirebase();
    return _storeOverride ?? FirebaseFirestore.instance;
  }

  void _requireEnabled() {
    if (!enabled) throw GroupSyncDisabled();
  }

  Future<User> _ensureUser() async {
    _requireEnabled();
    final auth = _auth;
    final existing = auth.currentUser;
    if (existing != null) {
      await db.setSetting(_uidSettingKey, existing.uid);
      return existing;
    }
    try {
      final credential = await auth.signInAnonymously();
      final user = credential.user;
      if (user == null) throw const GroupSyncUnavailable('Firebase did not return an anonymous user.');
      await db.setSetting(_uidSettingKey, user.uid);
      return user;
    } on FirebaseAuthException catch (error) {
      throw GroupSyncUnavailable(groupSyncErrorMessage(error));
    }
  }

  Future<String?> connectedUid() async {
    if (!enabled) return null;
    try {
      _ensureFirebase();
      return _auth.currentUser?.uid ?? await db.getSetting(_uidSettingKey);
    } on GroupSyncUnavailable {
      return null;
    }
  }

  Query<Map<String, dynamic>> _memberQuery(String uid) =>
      _store.collection(_groupsCollection).where('memberUids', arrayContains: uid);

  Future<void> start() async {
    if (_started) return;
    if (!enabled) return;
    _started = true;
    _applyingRemote = true;
    try {
      final user = await _ensureUser();
      onChanged?.call();
      final pulled = await _pullAll(user.uid);
      _remoteSub = _memberQuery(user.uid).snapshots().listen(
        (snapshot) => unawaited(_onRemoteSnapshot(snapshot)),
        onError: (Object error) => _lastError = groupSyncErrorMessage(error),
      );
      _localSub = db
          .tableUpdates(TableUpdateQuery.onAllTables([
            db.groups,
            db.groupMembers,
            db.groupExpenses,
            db.groupPayments,
          ]))
          .listen((_) => _schedulePush());
      final pushed = await _pushAll(user.uid);
      if (pulled.pulled > 0 || pushed.pushed > 0) onChanged?.call();
    } on Object catch (error) {
      _lastError = groupSyncErrorMessage(error);
      _started = false;
      onChanged?.call();
    } finally {
      _endApplying();
    }
  }

  Future<void> stop() async {
    _started = false;
    _pushPending = false;
    _pushTimer?.cancel();
    _pushTimer = null;
    await _remoteSub?.cancel();
    await _localSub?.cancel();
    _remoteSub = null;
    _localSub = null;
  }

  void _schedulePush() {
    if (!_started) return;
    if (_busy || _applyingRemote) {
      _pushPending = true;
      return;
    }
    _pushPending = false;
    _pushTimer?.cancel();
    _pushTimer = Timer(const Duration(milliseconds: 1200), () => unawaited(_autoPush()));
  }

  void _endApplying() {
    _applyingRemote = false;
    if (_pushPending) _schedulePush();
  }

  Future<void> _autoPush() async {
    if (!_started || _busy || _applyingRemote) return;
    _busy = true;
    _applyingRemote = true;
    try {
      final user = await _ensureUser();
      final pulled = await _pullAll(user.uid);
      final pushed = await _pushAll(user.uid);
      if (pulled.pulled > 0 || pushed.pushed > 0 || pulled.errors.isNotEmpty || pushed.errors.isNotEmpty) {
        onChanged?.call();
      }
    } on Object catch (error) {
      _lastError = groupSyncErrorMessage(error);
    } finally {
      _busy = false;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _endApplying();
    }
  }

  Future<void> _onRemoteSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) async {
    if (!_started || _busy || _applyingRemote) return;
    _applyingRemote = true;
    var changed = false;
    try {
      for (final doc in snapshot.docs) {
        changed = await _importDoc(doc) || changed;
      }
      if (changed) onChanged?.call();
    } on Object catch (error) {
      _lastError = groupSyncErrorMessage(error);
    } finally {
      _endApplying();
    }
  }

  Future<GroupSyncResult> sync() async {
    _requireEnabled();
    if (_busy) throw GroupSyncBusy();
    _busy = true;
    _applyingRemote = true;
    try {
      final user = await _ensureUser();
      final pulled = await _pullAll(user.uid);
      final pushed = await _pushAll(user.uid);
      final localGroups = (await groups.all()).length;
      if (pulled.pulled > 0 || pushed.pushed > 0) onChanged?.call();
      _lastError = null;
      return GroupSyncResult(
        uid: user.uid,
        pulled: pulled.pulled,
        pushed: pushed.pushed,
        localGroups: localGroups,
        errors: [...pulled.errors, ...pushed.errors],
      );
    } on Object catch (error) {
      _lastError = groupSyncErrorMessage(error);
      rethrow;
    } finally {
      _busy = false;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _endApplying();
    }
  }

  Future<({int pulled, List<String> errors})> _pullAll(String uid) async {
    final snapshot = await _memberQuery(uid).get();
    var pulled = 0;
    final errors = <String>[];
    for (final doc in snapshot.docs) {
      try {
        if (await _importDoc(doc)) pulled++;
      } on Object catch (error) {
        errors.add('${doc.id}: ${groupSyncErrorMessage(error)}');
      }
    }
    return (pulled: pulled, errors: errors);
  }

  Future<bool> _importDoc(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final raw = doc.data();
    if (raw == null) return false;
    final payload = _map(raw['data']);
    if (payload == null) return false;
    final code = _string(payload['code']) ?? doc.id;
    final ownerUid = _string(raw['ownerUid']);
    if (ownerUid != null) await db.setSetting(_ownerSettingKey(code), ownerUid);

    final local = await groups.byCode(code);
    final remoteTime = _payloadTime(payload) ?? _parseTime(
      raw['updatedAt'] is Timestamp ? (raw['updatedAt'] as Timestamp).toDate() : raw['updatedAt'],
    );
    final localTime = local == null ? null : (local.updatedAt ?? local.createdAt);
    if (local != null && (remoteTime == null || (localTime != null && !remoteTime.isAfter(localTime)))) {
      return false;
    }
    await groups.importGroup(payload);
    return true;
  }

  Future<({int pushed, List<String> errors})> _pushAll(String uid) async {
    var pushed = 0;
    final errors = <String>[];
    for (final group in await groups.all()) {
      try {
        if (await _pushGroup(group, uid)) pushed++;
      } on Object catch (error) {
        errors.add('${group.code}: ${groupSyncErrorMessage(error)}');
      }
    }
    return (pushed: pushed, errors: errors);
  }

  Future<bool> _pushGroup(Group group, String uid) async {
    final code = group.code.trim().toUpperCase();
    final localPayload = await groups.exportGroup(group.id);
    final knownOwner = await db.getSetting(_ownerSettingKey(code));
    final docRef = _store.collection(_groupsCollection).doc(code);

    final outcome = await _store.runTransaction<({Map<String, dynamic>? payload, String? ownerUid})>((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists) {
        if (knownOwner != null && knownOwner != uid) {
          return (payload: null, ownerUid: knownOwner);
        }
        tx.set(docRef, _document(ownerUid: uid, memberUids: [uid], payload: localPayload));
        return (payload: localPayload, ownerUid: uid);
      }

      final current = snapshot.data()!;
      final memberUids = _strings(current['memberUids']).toList();
      if (!memberUids.contains(uid)) throw GroupSyncNotMember();
      final ownerUid = _string(current['ownerUid']) ?? uid;
      final remotePayload = _map(current['data']) ?? <String, dynamic>{};
      final localTime = _payloadTime(localPayload);
      final remoteTime = _payloadTime(remotePayload);
      final newerLocal = localTime != null && (remoteTime == null || localTime.isAfter(remoteTime));
      if (!newerLocal && !_hasRowsMissingFromRemote(localPayload, remotePayload)) {
        return (payload: null, ownerUid: ownerUid);
      }
      final merged = mergeGroupPayloads(local: localPayload, remote: remotePayload);
      tx.set(docRef, _document(ownerUid: ownerUid, memberUids: memberUids, payload: merged));
      return (payload: merged, ownerUid: ownerUid);
    });

    final ownerUid = outcome.ownerUid;
    if (ownerUid != null) await db.setSetting(_ownerSettingKey(code), ownerUid);
    final merged = outcome.payload;
    if (merged == null) return false;
    await groups.importGroup(merged);
    return true;
  }

  Map<String, dynamic> _document({
    required String ownerUid,
    required List<String> memberUids,
    required Map<String, dynamic> payload,
  }) =>
      <String, dynamic>{
        'code': _string(payload['code']) ?? '',
        'ownerUid': ownerUid,
        'memberUids': memberUids,
        'data': payload,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Future<Group> joinGroup({required String code, required List<String> people}) async {
    _requireEnabled();
    final clean = code.trim().toUpperCase();
    final local = await groups.byCode(clean);
    if (clean.isEmpty) throw const GroupSyncNotFound('Type the code someone shared with you.');

    try {
      final user = await _ensureUser();
      final docRef = _store.collection(_groupsCollection).doc(clean);
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        if (local == null) {
          throw GroupSyncNotFound('No shared group has code $clean yet. Ask the creator to tap Sync first.');
        }
        final joined = await groups.join(code: clean, people: people);
        await _pushGroup(joined, user.uid);
        onChanged?.call();
        return joined;
      }

      final current = snapshot.data()!;
      final remotePayload = _map(current['data']);
      if (remotePayload == null) throw const GroupSyncNotFound('That group has no readable data.');
      final ownerUid = _string(current['ownerUid']) ?? user.uid;
      await db.setSetting(_ownerSettingKey(clean), ownerUid);
      await groups.importGroup(remotePayload);
      final joined = await groups.join(code: clean, people: people);
      final localPayload = await groups.exportGroup(joined.id);

      final merged = await _store.runTransaction<Map<String, dynamic>>((tx) async {
        final fresh = await tx.get(docRef);
        final raw = fresh.data() ?? current;
        final uids = _strings(raw['memberUids']).toList();
        if (!uids.contains(user.uid)) uids.add(user.uid);
        final merged = mergeGroupPayloads(
          local: localPayload,
          remote: _map(raw['data']) ?? remotePayload,
        );
        tx.set(docRef, _document(
          ownerUid: _string(raw['ownerUid']) ?? ownerUid,
          memberUids: uids,
          payload: merged,
        ));
        return merged;
      });
      await groups.importGroup(merged);
      onChanged?.call();
      return (await groups.byCode(clean))!;
    } on GroupSyncUnavailable {
      if (local != null) return groups.join(code: clean, people: people);
      rethrow;
    } on FirebaseException catch (error) {
      if (local != null) return groups.join(code: clean, people: people);
      throw GroupSyncUnavailable(groupSyncErrorMessage(error));
    }
  }
}
