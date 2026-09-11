import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/core/intake/share_parser.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';

void main() {
  group('share parser (pure)', () {
    test('Paid Rs.450 to Swiggy', () {
      final s = parseSharedText('Paid Rs.450 to Swiggy');
      expect(s.amount, 450);
      expect(s.merchant, 'Swiggy');
      expect(s.kindHint, 'out');
    });

    test('symbols, commas, UPI ref, received hint', () {
      final s = parseSharedText('INR 12,500 credited to HDFC\nUPI/431623789012');
      expect(s.amount, 12500);
      expect(s.upiRef, '431623789012');
      expect(s.kindHint, 'in');
      expect(parseSharedText('Refund Rs.200 from Amazon').kindHint, 'in');
    });

    test('OCR dump parses like shared text', () {
      final s = parseOcrText('Payment Successful\n₹1,250\nTo Ravi Kumar\nUPI:987654321098');
      expect(s.amount, 1250);
      expect(s.merchant, isNotNull);
    });

    test('blank text parses to nothing, never throws', () {
      final s = parseSharedText('   ');
      expect(s.amount, isNull);
      expect(s.merchant, isNull);
    });
  });

  group('self-transfer (ATM Bank→Cash, budget-neutral)', () {
    late AppDatabase db;
    late TransactionRepository txns;
    late String bankId;
    late String cashId;

    setUp(() async {
      db = AppDatabase.memory();
      txns = TransactionRepository(db);
      bankId = (await AccountRepository(db).create(name: 'SBI', kind: 'bank')).id;
      cashId = (await AccountRepository(db).create(name: 'Cash', kind: 'cash')).id;
    });

    tearDown(() => db.close());

    test('two rows, shared link, zero budget hit', () async {
      final (out, inn) = await txns.transfer(fromId: bankId, toId: cashId, amount: 10000, at: DateTime(2026, 9, 5));
      expect(out.actual, -10000);
      expect(inn.actual, 10000);
      expect(out.budgetImpact, 0);
      expect(inn.budgetImpact, 0);
      expect(out.linkId, inn.linkId);
      expect(out.linkType, 'transfer');

      final sept = await txns.sumsBetween(DateTime(2026, 9, 1), DateTime(2026, 9, 30, 23, 59));
      expect(sept.outBudget, 0); // months never inflate
      expect(sept.outActual, -10000);
      expect(sept.inActual, 10000);
    });

    test('open 2000, spend 300 → cash holds 1700', () async {
      await txns.transfer(fromId: bankId, toId: cashId, amount: 2000, at: DateTime(2026, 9, 1));
      await txns.add(
        kind: 'out',
        actual: -300,
        budgetImpact: -300,
        dateTime: DateTime(2026, 9, 2),
        categoryRaw: 'food lunch meals',
        accountId: cashId,
      );
      final cashRows = (await txns.all()).where((t) => t.accountId == cashId);
      final cashNet = cashRows.fold<double>(0, (s, t) => s + t.actual);
      expect(cashNet, 1700);
    });

    test('same-account and non-positive transfers rejected', () async {
      expect(() => txns.transfer(fromId: bankId, toId: bankId, amount: 100), throwsArgumentError);
      expect(() => txns.transfer(fromId: bankId, toId: cashId, amount: 0), throwsArgumentError);
    });
  });
}
