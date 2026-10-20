import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/intake/intake_screen.dart';
import '../features/transactions/transactions_screen.dart';
import '../features/intake/share_target.dart';
import '../features/settings/lock_screen.dart';
import 'auth/lock_service.dart';

/// The app's one router.
///
/// It is created **once** and kept for the app's life: an earlier version
/// rebuilt it whenever the lock state changed, which wiped the navigation
/// stack — a shared message that opened the intake sheet was thrown away
/// again the moment the lock state ticked over. The lock gate is now driven
/// by an explicit `go()` instead.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: ref.read(lockProvider).locked ? '/lock' : '/',
    routes: [
      GoRoute(path: '/lock', builder: (c, s) => const LockScreen()),
      GoRoute(path: '/', builder: (c, s) => const TransactionsScreen()),
      // The shared-message destination. The payload travels as `extra`, so no
      // text ends up in a route string.
      GoRoute(
        path: '/intake',
        builder: (c, s) {
          final payload = s.extra is SharePayload ? s.extra as SharePayload : null;
          return IntakeScreen(
            initialText: payload?.text,
            initialImages: payload?.images ?? const [],
          );
        },
      ),
    ],
    redirect: (context, state) {
      final locked = ref.read(lockProvider).locked;
      if (locked && state.matchedLocation != '/lock') return '/lock';
      if (!locked && state.matchedLocation == '/lock') return '/';
      return null;
    },
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Sends the app to the lock screen (or back out of it).
void syncLockRoute(WidgetRef ref, bool locked) {
  final router = ref.read(routerProvider);
  if (locked) {
    if (router.routerDelegate.currentConfiguration.uri.path != '/lock') router.go('/lock');
  } else {
    if (router.routerDelegate.currentConfiguration.uri.path == '/lock') router.go('/');
  }
}
