import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/lock_service.dart';
import 'core/db_open.dart';
import 'core/providers.dart';
import 'core/router.dart';

/// Entry point. Opens the file DB once, then gates everything behind AppLock.
/// See ARCHITECTURE.md for module map.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openFileDatabase();
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const ExpenseTrackerApp(),
    ),
  );
}

class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(lockProvider);
    return MaterialApp.router(
      title: 'ExpenseTracker',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      routerConfig: buildRouter(locked: lockState.locked),
    );
  }
}
