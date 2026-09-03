import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/lock_service.dart';
import 'core/router.dart';

/// Entry point. No business logic here — just providers + lock gate + router.
/// See ARCHITECTURE.md for module map.
void main() {
  runApp(const ProviderScope(child: ExpenseTrackerApp()));
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
