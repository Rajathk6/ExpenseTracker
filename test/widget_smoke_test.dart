import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/core/providers.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/transactions/transactions_screen.dart';

/// Boot smoke: transactions home renders, first-run banner, FAB.
///
/// Async providers are overridden with deterministic values (hermetic widget
/// test practice). The real async path is covered by repository unit tests.
void main() {
  testWidgets('transactions home renders + first-run banner', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final cash = await AccountRepository(db).create(name: 'Cash');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          recentTransactionsProvider.overrideWith((ref) async => <Transaction>[]),
          accountsProvider.overrideWith((ref) => Stream.value([cash])),
          monthSummaryProvider.overrideWith(
            (ref, _) async => (inActual: 0.0, outActual: 0.0, inBudget: 0.0, outBudget: 0.0, count: 0),
          ),
        ],
        child: const MaterialApp(home: TransactionsScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('No entries this month — tap Add.'), findsOneWidget);
  });
}
