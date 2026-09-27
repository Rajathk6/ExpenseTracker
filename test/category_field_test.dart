import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/core/providers.dart';
import 'package:expense_tracker/features/transactions/category_field.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';

/// The owner-reported gap: adding a new item offered no past categories, so
/// the whole string had to be retyped. These cover the field that fixes it.
void main() {
  late AppDatabase db;
  late TextEditingController controller;

  Future<void> pumpField(WidgetTester tester) async {
    controller = TextEditingController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: CategoryField(controller: controller, hintText: 'food junk gobi-65'),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// The field's own text is also a RichText, so address rows explicitly.
  Finder rowWith(String value) => find.descendant(
        of: find.byType(CategorySuggestionRow),
        matching: find.textContaining(value, findRichText: true),
      );

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() {
    controller.dispose();
    db.close();
  });

  Future<void> seed(String category) => TransactionRepository(db).add(
        kind: 'out',
        actual: -65,
        budgetImpact: -65,
        dateTime: DateTime(2026, 9, 1),
        categoryRaw: category,
      );

  testWidgets('half a word offers the saved category; tapping fills it', (tester) async {
    await seed('food junk gobi-65');
    await seed('transport auto cab');
    await pumpField(tester);

    await tester.enterText(find.byType(TextField), 'gob');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(rowWith('food junk gobi-65'), findsOneWidget);
    await tester.tap(rowWith('food junk gobi-65'));
    await tester.pumpAndSettle();

    expect(controller.text, 'food junk gobi-65');
    // Picked → the list steps out of the way until the next keystroke.
    expect(find.byType(CategorySuggestionRow), findsNothing);
  });

  testWidgets('a level half word works the same', (tester) async {
    await seed('food junk gobi-65');
    await pumpField(tester);

    await tester.enterText(find.byType(TextField), 'junk');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(rowWith('food junk gobi-65'), findsOneWidget);
  });

  testWidgets('empty field stays quiet, and a brand-new category is never blocked', (tester) async {
    await seed('food junk gobi-65');
    await pumpField(tester);

    expect(find.textContaining('New category', findRichText: true), findsNothing);
    expect(find.byType(CategorySuggestionRow), findsNothing);

    await tester.enterText(find.byType(TextField), 'gym membership');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.textContaining('New category', findRichText: true), findsOneWidget);
    expect(controller.text, 'gym membership');
  });

  testWidgets('the typed text is never shown as its own suggestion', (tester) async {
    await seed('food chai cutting');
    await pumpField(tester);

    await tester.enterText(find.byType(TextField), 'food chai cutting');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.byType(CategorySuggestionRow), findsNothing);
  });
}
