/// Home-screen quick-add tile: shows this month's budget spend and opens the
/// 2-tap cash sheet.
///
/// Data is pushed from Dart (offline, from the same local DB the app reads);
/// the tap comes back through home_widget's launch intent, so the tile needs
/// no background service and works with the app closed. Android's
/// `QuickAddWidget` provider renders the layout and owns the tap target.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/months.dart';
import '../../core/providers.dart';

const quickAddTileName = 'QuickAddWidget';
const quickAddAndroidName = 'dev.rajath.expense_tracker.QuickAddWidget';

/// The action the tile's tap sends back to the app.
const quickAddAction = 'quickadd';

class HomeTileService {
  const HomeTileService();

  /// Writes the tile's numbers and asks Android to redraw it. Never throws —
  /// a launcher that refuses the broadcast must not break the app.
  Future<void> pushMonth({required double outBudget, required double total}) async {
    final key = monthKey(DateTime.now());
    try {
      await HomeWidget.saveWidgetData('title', 'Expense Tracker');
      await HomeWidget.saveWidgetData('spend', 'Spent ${_rupees(outBudget)} · $key');
      await HomeWidget.saveWidgetData('budget', total > 0 ? 'of ${_rupees(total)} budgeted' : 'no budget set');
      await HomeWidget.saveWidgetData('hint', 'Tap to log a cash spend');
      await HomeWidget.updateWidget(
        name: quickAddTileName,
        androidName: quickAddAndroidName,
        qualifiedAndroidName: quickAddAndroidName,
      );
    } on Object {
      // No launcher support, or the provider is not on the home screen yet.
    }
  }

  /// The action the app was launched with from the tile, if any.
  static Future<String?> initialAction() async {
    try {
      return (await HomeWidget.initiallyLaunchedFromHomeWidget())?.queryParameters['action'];
    } on Object {
      return null;
    }
  }

  /// Taps on the tile while the app is already running.
  static Stream<String?> get clicks =>
      HomeWidget.widgetClicked.map((uri) => uri?.queryParameters['action']);

  static String _rupees(double v) => '₹${v.abs().round()}';
}

/// Watching this provider is what keeps the home tile current: every ledger or
/// budget change re-pushes the numbers. Invalidating the two providers it reads
/// is enough to refresh it (main.dart does that on resume).
final homeTileRefreshProvider = Provider<HomeTileService>((ref) {
  const tile = HomeTileService();
  final key = monthKey(DateTime.now());
  ref.listen(monthSummaryProvider(key), (_, __) => _refresh(ref, tile), fireImmediately: true);
  ref.listen(effectiveBudgetProvider(key), (_, __) => _refresh(ref, tile));
  return tile;
});

Future<void> _refresh(Ref ref, HomeTileService tile) async {
  final key = monthKey(DateTime.now());
  final sums = await ref.read(monthSummaryProvider(key).future);
  final budget = await ref.read(effectiveBudgetProvider(key).future);
  await tile.pushMonth(outBudget: sums.outBudget, total: budget?.total ?? 0);
}
