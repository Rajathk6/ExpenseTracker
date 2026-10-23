/// User-created category shortcuts.
///
/// A category is still freeform text on a transaction. Saving a shortcut only
/// adds a button under the category field in the Add form; renaming or
/// deleting it never rewrites history.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/database.dart';

class CategoryRepository {
  final AppDatabase db;
  const CategoryRepository(this.db);

  Future<List<Category>> list() => db.allCategories();

  Stream<List<Category>> watch() => db.watchCategories();

  Future<Category> create(String name) async {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) throw ArgumentError('Category name cannot be empty');
    final existing = await db.allCategories();
    if (existing.any((c) => c.name.toLowerCase() == clean.toLowerCase())) {
      throw StateError('Category "$clean" already exists');
    }
    final id = const Uuid().v4();
    await db.upsertCategory(
      CategoriesCompanion(id: Value(id), name: Value(clean)),
    );
    return (await db.allCategories()).firstWhere((c) => c.id == id);
  }

  Future<void> rename(String id, String name) async {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) throw ArgumentError('Category name cannot be empty');
    final existing = await db.allCategories();
    if (existing.any(
      (c) => c.id != id && c.name.toLowerCase() == clean.toLowerCase(),
    )) {
      throw StateError('Category "$clean" already exists');
    }
    await (db.update(db.categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(name: Value(clean)));
  }

  /// Removes the shortcut only. Transactions that used the name are untouched.
  Future<void> remove(String id) => db.deleteCategory(id);
}
