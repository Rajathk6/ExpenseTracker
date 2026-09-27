import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/core/providers.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/intake/intake_screen.dart';
import 'package:expense_tracker/features/intake/ocr_reader.dart';

/// The screenshot path, with the ML Kit call faked: what is under test is
/// "recognised text lands in the same box a shared SMS uses, behind the same
/// confirm screen" — never the model itself.
class _FakeReader implements TextReader {
  _FakeReader(this.text);
  final String text;
  final List<String> asked = [];

  @override
  Future<String> read(String imagePath) async {
    asked.add(imagePath);
    if (text == 'BOOM') throw StateError('unreadable');
    return text;
  }
}

/// Never called — used where the file is missing.
class _Unreadable implements TextReader {
  const _Unreadable();
  @override
  Future<String> read(String imagePath) async => throw StateError('should not be called');
}

void main() {
  late AppDatabase db;
  late Account cash;
  late String screenshot;
  late String blank;

  setUp(() async {
    db = AppDatabase.memory();
    cash = await AccountRepository(db).create(name: 'Cash');
    // Real files, written outside testWidgets: inside its fake-async zone a
    // real I/O completion never arrives and the test deadlocks.
    final dir = Directory.systemTemp.createTempSync('intake-test');
    screenshot = await _write(dir, 'pay.png');
    blank = await _write(dir, 'blank.png');
  });

  tearDown(() => db.close());

  Future<void> pumpIntake(WidgetTester tester, {TextReader reader = const _Unreadable(), List<String>? images}) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            // Override the account stream like widget_smoke_test does: a live
            // drift stream leaves a zero-duration timer behind at teardown.
            accountsProvider.overrideWith((ref) => Stream.value([cash])),
          ],
          child: MaterialApp(
            home: IntakeScreen(
              initialImages: images ?? const ['/data/does-not-exist.png'],
              reader: reader,
            ),
          ),
        ),
      );

  testWidgets('a screenshot is read on-device and pre-fills the confirm sheet', (tester) async {
    final reader = _FakeReader('Payment Successful\nRs.1,250\nTo Ravi Kumar\nUPI:987654321098');
    await pumpIntake(tester, reader: reader, images: [screenshot]);
    await tester.pumpAndSettle();

    expect(reader.asked, [screenshot]);
    expect(find.text('Amount: 1250'), findsOneWidget);
    expect(await db.allTransactions(), isEmpty, reason: 'the confirm screen must never auto-save');
  });

  testWidgets('an unreadable screenshot falls back to "paste the text"', (tester) async {
    await pumpIntake(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be opened'), findsOneWidget);
  });

  testWidgets('a screenshot with no text says so instead of opening blank', (tester) async {
    await pumpIntake(tester, reader: _FakeReader('   '), images: [screenshot]);
    await tester.pumpAndSettle();
    expect(find.textContaining('No text found'), findsOneWidget);
  });

  testWidgets('a broken reader is reported, not thrown', (tester) async {
    await pumpIntake(tester, reader: _FakeReader('BOOM'), images: [screenshot, blank]);
    await tester.pumpAndSettle();
    expect(find.textContaining('No text found'), findsOneWidget);
  });

  testWidgets('confirming saves the OCR-read entry against the account', (tester) async {
    // A phone-shaped surface so the whole confirm sheet is laid out (a lazy
    // ListView never builds the button in the default 800x600 test viewport).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpIntake(tester, reader: _FakeReader('Paid Rs.450 to Swiggy'), images: [screenshot]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm & save offline'));
    await tester.pumpAndSettle();

    final rows = await db.allTransactions();
    expect(rows, hasLength(1));
    expect(rows.single.actual, -450);
    expect(rows.single.budgetImpact, -450);
    expect(rows.single.categoryRaw, contains('swiggy'));
    expect(rows.single.accountId, cash.id);
  });
}

Future<String> _write(Directory dir, String name) async {
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(const [0x89, 0x50, 0x4E, 0x47]);
  return file.path;
}
