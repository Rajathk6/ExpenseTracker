import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/core/intake/share_parser.dart';
import 'package:expense_tracker/features/intake/share_target.dart';
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

    test('a UTR is never read as the amount', () {
      final s = parseSharedText('Paid to SWIGGY\nUTR 431623789012\nAmount 450');
      expect(s.amount, 450);
    });

    test('a currency-marked amount beats a reference number', () {
      final s = parseSharedText('Paid Rs.450 to Swiggy\nUPI:987654321098');
      expect(s.amount, 450);
    });

    test('a screenshot full of numbers still finds the money', () {
      final s = parseOcrText(
        'PhonePe\nPaid to SWIGGY\n12/09/2026 14:35\nRs 450.00\nUTR 431623789012\nBalance 12000.00',
      );
      expect(s.amount, 450);
    });

    test('a long digit string with no amount is not an amount', () {
      final s = parseSharedText('UPI 431623789012');
      expect(s.amount, isNull);
    });

    test('a date is not an amount', () {
      final s = parseSharedText('12/09/2026');
      expect(s.amount, isNull);
    });

    test('the last four digits of a phone number are not the amount', () {
      // A real payment screenshot: the number the app shows is the phone tail.
      final s = parseOcrText(
        'Paid to Ravi Kumar\nXXXXXXXX3210\nAmount\n450.00\nUPI:431623789012',
      );
      expect(s.amount, 450);
    });

    test('a phone number written in groups is not the amount', () {
      final s = parseOcrText('To: 98765 43210\n₹450\nPaid successfully');
      expect(s.amount, 450);
    });

    test('a masked number on its own is not the amount', () {
      final s = parseOcrText('XXXXXXXX3210');
      expect(s.amount, isNull);
    });

    test('an amount alone on its line wins over a phone number above it', () {
      final s = parseOcrText('9876543210\n450');
      expect(s.amount, 450);
    });

    test('a decimal amount beats a plain number next to it', () {
      final s = parseOcrText('450.00\n1200');
      expect(s.amount, 450);
    });

    test('a rupee-marked amount always wins', () {
      final s = parseOcrText('1200\nRs 450');
      expect(s.amount, 450);
    });

    test('the phone tail never beats a rupee amount', () {
      final s = parseOcrText('XXXXXXXX3210\nRs 450');
      expect(s.amount, 450);
    });

    test('the shop name is not a label, a date or a money line', () {
      // A label line is not a shop.
      expect(parseOcrText('Amount 450\nPaid to SWIGGY').merchant, 'SWIGGY');
      // A date is not a shop.
      expect(parseOcrText('12/09/2026 14:35\n₹450').merchant, isNull);
      // A plain number line is not a shop.
      expect(parseOcrText('450.00\nPaid to Ravi').merchant, 'Ravi');
    });

    test('blank text parses to nothing, never throws', () {
      final s = parseSharedText('   ');
      expect(s.amount, isNull);
      expect(s.merchant, isNull);
    });
  });

  group('share target payload (pure)', () {
    test('a shared SMS hands its text to the confirm sheet', () {
      final payload = SharePayload.from({'text': 'Paid Rs.450 to Swiggy', 'images': <String>[]});
      expect(payload!.text, 'Paid Rs.450 to Swiggy');
      expect(payload.images, isEmpty);
      expect(payload.isScreenshotOnly, false);
    });

    test('a shared screenshot carries file paths, no text', () {
      final payload = SharePayload.from({
        'text': null,
        'images': ['/data/user/0/dev.rajath.expense_tracker/cache/share-1.jpg'],
      });
      expect(payload!.text, isNull);
      expect(payload.images, hasLength(1));
      expect(payload.isScreenshotOnly, true);
    });

    test('a blank or malformed share never opens a half-empty sheet', () {
      expect(SharePayload.from({'text': '   ', 'images': <String>[]}), isNull);
      expect(SharePayload.from({'text': null, 'images': <String>[]}), isNull);
      expect(SharePayload.from(null), isNull);
      expect(SharePayload.from('just a string'), isNull);
      expect(SharePayload.from({'images': ['', 7]}), isNull);
    });

    test('text and images can arrive together, junk entries are dropped', () {
      final payload = SharePayload.from({
        'text': ' Refund Rs.200 from Amazon ',
        'images': ['/cache/a.png', '', '/cache/b.png', 42],
      });
      expect(payload!.text, 'Refund Rs.200 from Amazon');
      expect(payload.images, ['/cache/a.png', '/cache/b.png']);
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
