import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/auth/pin_service.dart';
import 'package:expense_tracker/core/auth/secret_store.dart';
import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/core/providers.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/neutral/debt_repository.dart';
import 'package:expense_tracker/features/settings/lock_screen.dart';

/// The owner's report: "it says enter current pin but there is no option to
/// enter the current pin" — and "I have not even added a pin, what current
/// pin?". Both were the same bug: the gate asked for a current PIN that did
/// not exist yet.
void main() {
  late AppDatabase db;
  late PinService pins;

  setUp(() {
    db = AppDatabase.memory();
    pins = PinService(db, secrets: MemorySecretStore());
  });

  tearDown(() => db.close());

  Future<void> pumpPinScreen(WidgetTester tester) => tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            // The screen reads the PIN from the secure store; the test uses the
            // in-memory one (there is no keychain off-device).
            pinServiceProvider.overrideWithValue(pins),
          ],
          child: const MaterialApp(home: PinSetupScreen()),
        ),
      );

  testWidgets('with no PIN set, the form is shown — no "current PIN" demanded', (tester) async {
    await pumpPinScreen(tester);
    await tester.pumpAndSettle();

    // The new-PIN field is right there, and no identity gate is in the way.
    expect(find.text('New 6-digit PIN'), findsOneWidget);
    expect(find.text('Your current 6-digit PIN'), findsNothing);
  });

  testWidgets('with a PIN set, the gate asks for it — and there is a field for it', (tester) async {
    await pins.setPin('123456');
    await pumpPinScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Your current 6-digit PIN'), findsOneWidget);
    expect(find.text('New 6-digit PIN'), findsNothing);
  });

  testWidgets('the wrong current PIN keeps the gate shut', (tester) async {
    await pins.setPin('123456');
    await pumpPinScreen(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '999999');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Your current 6-digit PIN'), findsOneWidget);
    expect(find.textContaining('not your current PIN'), findsOneWidget);
  });

  testWidgets('the right current PIN opens the new-PIN form', (tester) async {
    await pins.setPin('123456');
    await pumpPinScreen(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('New 6-digit PIN'), findsOneWidget);
  });

  group('the same person is always one contract (#2)', () {
    late DebtRepository debts;

    setUp(() {
      debts = DebtRepository(db);
    });

    test('lend() itself merges — no screen can make a second card', () async {
      await debts.lend(counterparty: 'Karthik', principal: 5000);
      await debts.lend(counterparty: 'karthik', principal: 2500);
      final all = await debts.all();
      expect(all.length, 1);
      expect(all.single.principal, 7500);
    });

    test('borrowing merges the same way', () async {
      await debts.borrow(counterparty: 'Asha', principal: 1000);
      await debts.borrow(counterparty: 'Asha', principal: 500);
      expect((await debts.all()).length, 1);
    });

    test('both amounts are on the one trail', () async {
      final contract = await debts.lend(counterparty: 'Karthik', principal: 5000);
      await debts.lend(counterparty: 'Karthik', principal: 2500);
      final trail = await debts.history(contract.id);
      expect(trail.length, 2);
      expect(trail.map((t) => t.actual).toList(), [-5000, -2500]);
    });

    test('a settled contract does not swallow a new one', () async {
      final contract = await debts.lend(counterparty: 'Karthik', principal: 1000);
      await debts.pay(debtId: contract.id, amount: 1000);
      // The old contract is settled, so a new one is started.
      await debts.lend(counterparty: 'Karthik', principal: 500);
      final all = await debts.all();
      expect(all.length, 2);
      expect(all.where((d) => d.status == 'open').length, 1);
    });
  });

  group('the first-run sheet creates the accounts the owner asked for (#1)', () {
    test('Cash and a bank, with the name kept', () async {
      final accounts = AccountRepository(db);
      await accounts.create(name: 'Cash', kind: 'cash', openingBalance: 1500);
      await accounts.create(name: 'SBI', kind: 'bank', openingBalance: 40000);
      final all = await accounts.list();
      expect([for (final a in all) a.name], ['Cash', 'SBI']);
      expect(all.firstWhere((a) => a.name == 'Cash').openingBalance, 1500);
    });
  });
}
