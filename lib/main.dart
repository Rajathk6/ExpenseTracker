import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/lock_service.dart' show lockProvider;
import 'core/db_open.dart';
import 'core/months.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'features/cash/home_tile.dart';
import 'features/cash/quickadd_sheet.dart';
import 'features/intake/share_target.dart';

/// Entry point. Opens the real + demo file DBs once, then gates everything
/// behind AppLock. The decoy PIN swaps the whole DB handle (see
/// providers.dart), so the demo vault never touches real rows.
///
/// Hardening (Phase 11): framework errors render a plain fallback card
/// instead of a grey screen, and fatal async errors are funneled to
/// FlutterError so `flutter run --release` logs stay actionable.
Future<void> main() async {
  ErrorWidget.builder = (details) => Material(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Something broke rendering this screen. Your data is safe — restart the app.\n\n${details.exceptionAsString()}',
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      );
  FlutterError.onError = (details) => FlutterError.presentError(details);
  await runZonedGuarded(
    () async {
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
    },
    (error, stack) => FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack, library: 'zone'),
    ),
  );
}

class ExpenseTrackerApp extends ConsumerStatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  ConsumerState<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends ConsumerState<ExpenseTrackerApp> with WidgetsBindingObserver {
  StreamSubscription<String?>? _tileClicks;
  bool _openingQuickAdd = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Watching the tile provider is what pushes this month's numbers to the
    // home screen; without a listener it would never run.
    ref.read(homeTileRefreshProvider);
    _tileClicks = HomeTileService.clicks.listen(_onTileAction);
    unawaited(HomeTileService.initialAction().then(_onTileAction));
  }

  @override
  void dispose() {
    _tileClicks?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back refreshes the auto-lock countdown; the timer itself
    // fires while away, so the gate is shut after the chosen idle window.
    if (state == AppLifecycleState.resumed) {
      ref.read(lockProvider.notifier).noteActivity();
      // Entries may have been made from a share or the tile while we were away.
      final key = monthKey(DateTime.now());
      ref
        ..invalidate(monthSummaryProvider(key))
        ..invalidate(effectiveBudgetProvider(key));
    }
  }

  /// The home tile asked for quick-add. Held if the vault is still locked —
  /// the tile must never be a way around the lock gate.
  Future<void> _onTileAction(String? action) async {
    if (action != quickAddAction) return;
    if (ref.read(lockProvider).locked) return;
    await _openQuickAdd();
  }

  Future<void> _openQuickAdd() async {
    if (_openingQuickAdd || !mounted) return;
    _openingQuickAdd = true;
    try {
      await openQuickAdd(context);
      final key = monthKey(DateTime.now());
      ref
        ..invalidate(monthSummaryProvider(key))
        ..invalidate(recentTransactionsProvider);
    } finally {
      _openingQuickAdd = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(lockProvider);
    // A tile tap that arrived while locked opens the sheet as soon as the
    // PIN/biometric gate lets us through.
    ref.listen(lockProvider, (_, next) {
      if (!next.locked) unawaited(_openQuickAdd());
    });
    return MaterialApp.router(
      title: 'ExpenseTracker',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      routerConfig: buildRouter(locked: lockState.locked),
      // Inside MaterialApp so a Navigator exists for the share sheet and the
      // quick-add sheet to push onto.
      builder: (context, child) => ShareTargetListener(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
