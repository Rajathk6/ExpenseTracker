/// Instrument repository: vault CRUD + archive. Tracking-only — never writes
/// ledger [Transactions] rows, so budgets and bank truths stay untouched.
/// `kind` is freeform (stock/mutual/fd/loan/card/paper/plan/note/...).
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/database.dart';
import 'instrument_logic.dart';

/// Suggested kinds for the picker. Suggestions only — any string is accepted.
const suggestedInstrumentKinds = ['stock', 'mutual', 'fd', 'loan', 'card', 'paper', 'plan', 'note'];

class InstrumentRepository {
  final AppDatabase db;
  const InstrumentRepository(this.db);

  Future<Instrument> create({
    required String name,
    String kind = 'stock',
    double invested = 0,
    double current = 0,
    String? note,
  }) async {
    final clean = name.trim();
    final err = validateInstrument(name: clean, invested: invested, current: current);
    if (err != null) throw ArgumentError(err);
    final id = const Uuid().v4();
    await db.insertInstrument(
      InstrumentsCompanion(
        id: Value(id),
        name: Value(clean),
        kind: Value(kind.trim().isEmpty ? 'stock' : kind.trim().toLowerCase()),
        invested: Value(invested),
        current: Value(current),
        note: Value(note?.trim().isEmpty ?? true ? null : note!.trim()),
      ),
    );
    return db.getInstrument(id);
  }

  /// Manual mark-to-market update (e.g. after checking prices).
  Future<Instrument> revalue(String id, double current) async {
    if (current < 0) throw ArgumentError('Current value cannot be negative');
    await db.updateInstrument(id, InstrumentsCompanion(current: Value(current)));
    return db.getInstrument(id);
  }

  Future<Instrument> edit({
    required String id,
    String? name,
    String? kind,
    double? invested,
    double? current,
    String? note,
    bool clearNote = false,
  }) async {
    final cur = await db.getInstrument(id);
    final nextName = (name ?? cur.name).trim();
    final nextKind = (kind ?? cur.kind).trim().isEmpty ? cur.kind : kind!.trim().toLowerCase();
    final nextInvested = invested ?? cur.invested;
    final nextCurrent = current ?? cur.current;
    final err = validateInstrument(name: nextName, invested: nextInvested, current: nextCurrent);
    if (err != null) throw ArgumentError(err);
    await db.updateInstrument(
      id,
      InstrumentsCompanion(
        name: Value(nextName),
        kind: Value(nextKind),
        invested: Value(nextInvested),
        current: Value(nextCurrent),
        note: clearNote ? const Value(null) : (note == null ? const Value.absent() : Value(note.trim().isEmpty ? null : note.trim())),
      ),
    );
    return db.getInstrument(id);
  }

  Future<Instrument> archive(String id) async {
    await db.updateInstrument(id, const InstrumentsCompanion(status: Value('archived')));
    return db.getInstrument(id);
  }

  Future<Instrument> unarchive(String id) async {
    await db.updateInstrument(id, const InstrumentsCompanion(status: Value('open')));
    return db.getInstrument(id);
  }

  Future<void> remove(String id) => db.deleteInstrument(id);

  Future<List<Instrument>> open() => db.openInstruments();

  Future<List<Instrument>> all() => db.allInstruments();

  Future<Instrument> get(String id) => db.getInstrument(id);
}
