import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/lock_service.dart';
import 'core/db_open.dart';
import 'core/providers.dart';
import 'core/router.dart';

/// Entry point. Opens the real + demo file DBs once, then gates everything
/// behind AppLock. The decoy PIN swaps the whole DB handle (see
/// providers.dart), so the demo vault never touches real rows.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final realDb = await openFileDatabase();
  final demoDb = await openDemoDatabase();
  runApp(
    ProviderScope(
      overrides: [
        realDatabaseProvider.overrideWithValue(realDb),
        demoDatabaseProvider.overrideWithValue(demoDb),
      ],
      child: const ExpenseTrackerApp(),
    ),
  );
}

class ExpenseTrackerApp extends ConsumerStatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  ConsumerState<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends ConsumerState<ExpenseTrackerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back refreshes the auto-lock countdown; the timer itself
    // fires while away, so the gate is shut after the chosen idle window.
    if (state == AppLifecycleState.resumed) {
      ref.read(lockProvider.notifier).noteActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(lockProvider);
    return MaterialApp.router(
      title: 'ExpenseTracker',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      routerConfig: buildRouter(locked: lockState.locked),
    );
  }
}
