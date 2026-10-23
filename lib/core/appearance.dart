/// Appearance: system / light / dark, persisted in the settings table so the
/// whole app opens in the owner's choice.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'providers.dart';

const themeModeSettingKey = 'appearance.themeMode';

ThemeMode themeModeFromSetting(String? raw) => switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

String themeModeToSetting(ThemeMode mode) => switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

String themeModeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System default',
    };

/// Emits again whenever the setting changes, so MaterialApp flips live.
final themeModeProvider = StreamProvider<ThemeMode>((ref) {
  return ref
      .watch(databaseProvider)
      .watchSetting(themeModeSettingKey)
      .map(themeModeFromSetting);
});

class AppearanceController {
  final AppDatabase db;
  const AppearanceController(this.db);

  Future<void> setThemeMode(ThemeMode mode) =>
      db.setSetting(themeModeSettingKey, themeModeToSetting(mode));
}

final appearanceControllerProvider =
    Provider((ref) => AppearanceController(ref.watch(databaseProvider)));
