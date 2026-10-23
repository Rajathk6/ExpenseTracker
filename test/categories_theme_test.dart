import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/appearance.dart';
import 'package:expense_tracker/core/backup/backup_service.dart';
import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/transactions/category_repository.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository categories;

  setUp(() {
    db = AppDatabase.memory();
    categories = CategoryRepository(db);
  });

  tearDown(() => db.close());

  test(
      'saved categories can be created, renamed and removed without touching history',
      () async {
    final food = await categories.create('  Food   out  ');
    expect(food.name, 'Food out');
    expect((await categories.list()).single.name, 'Food out');

    await categories.rename(food.id, 'Eating out');
    expect((await categories.list()).single.name, 'Eating out');

    await categories.remove(food.id);
    expect(await categories.list(), isEmpty);
    expect(await db.allTransactions(), isEmpty);
  });

  test('a saved category is unique case-insensitively', () async {
    await categories.create('Food');
    expect(() => categories.create(' food '), throwsStateError);
  });

  test('categories survive the encrypted backup payload', () async {
    await categories.create('Travel');
    final service = BackupService(db);
    final dumped = await service.dumpTables();
    expect(dumped['categories'], hasLength(1));
    expect(backupTables, contains('categories'));

    await categories.remove((await categories.list()).single.id);
    expect(await categories.list(), isEmpty);

    final counts = await service.restoreTables(dumped);
    expect(counts['categories'], 1);
    expect((await categories.list()).single.name, 'Travel');
  });

  test('theme mode round-trips and unknown values fall back to system', () {
    for (final mode in ThemeMode.values) {
      expect(themeModeFromSetting(themeModeToSetting(mode)), mode);
    }
    expect(themeModeFromSetting(null), ThemeMode.system);
    expect(themeModeFromSetting('sepia'), ThemeMode.system);
    expect(themeModeLabel(ThemeMode.system), 'System default');
  });
}
