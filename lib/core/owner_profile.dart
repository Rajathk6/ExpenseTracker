/// Who the owner is, and what they call themselves.
///
/// Asked once, on first run, because every shared thing needs a name for
/// "me": a split says "Me paid ₹900, Ravi owes ₹300", a group says who is
/// in it, and a pay-up says who paid whom. A blank "Me" makes all of that
/// unreadable.
///
/// Stored in the settings table (it is not a secret).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'providers.dart';

const _nameKey = 'owner.name';

/// The owner's name, or null when they have not said yet.
final ownerNameProvider = FutureProvider<String?>((ref) async {
  final name = await ref.watch(databaseProvider).getSetting(_nameKey);
  final clean = name?.trim();
  return (clean == null || clean.isEmpty) ? null : clean;
});

/// The name to use for the owner: their own, or "Me" until they tell us.
final ownerDisplayNameProvider = FutureProvider<String>((ref) async {
  final name = await ref.watch(ownerNameProvider.future);
  return name ?? 'Me';
});

class OwnerProfile {
  final AppDatabase db;
  const OwnerProfile(this.db);

  Future<String?> name() async {
    final raw = await db.getSetting(_nameKey);
    final clean = raw?.trim();
    return (clean == null || clean.isEmpty) ? null : clean;
  }

  Future<void> setName(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) {
      await db.deleteSetting(_nameKey);
      return;
    }
    await db.setSetting(_nameKey, clean);
  }
}

final ownerProfileProvider = Provider((ref) => OwnerProfile(ref.watch(databaseProvider)));
