import 'package:go_router/go_router.dart';

import '../features/transactions/transactions_screen.dart';
import '../features/settings/lock_screen.dart';

/// Single router factory so lock-gating stays in one place.
GoRouter buildRouter({required bool locked}) {
  return GoRouter(
    initialLocation: locked ? '/lock' : '/',
    routes: [
      GoRoute(path: '/lock', builder: (c, s) => const LockScreen()),
      GoRoute(path: '/', builder: (c, s) => const TransactionsScreen()),
    ],
    redirect: (context, state) {
      if (locked && state.matchedLocation != '/lock') return '/lock';
      if (!locked && state.matchedLocation == '/lock') return '/';
      return null;
    },
  );
}
