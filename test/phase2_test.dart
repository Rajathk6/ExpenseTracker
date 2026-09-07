import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/transactions/entry_logic.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';

void main() {
  group('entry validation', () {
    EntryDraft withArgs({String? kind, String? amount, String? category, String? accountId}) => EntryDraft(
          kind: kind ?? 'out',
          amountText: amount ?? '65',
          categoryRaw: category ?? 'food junk gobi-65',
          accountId: accountId ?? 'a1',
          dateTime: DateTime(2026, 9, 4),
        );

    test('valid draft passes', () {
      expect(validateEntry(withArgs(), hasAccounts: true), isNull);
    });

    test('bad kind / amount rejected', () {
      expect(validateEntry(withArgs(kind: 'x'), hasAccounts: true), isNotNull);
      expect(validateEntry(withArgs(amount: 'abc'), hasAccounts: true), contains('valid amount'));
      expect(validateEntry(withArgs(amount: '0'), hasAccounts: true), contains('above zero'));
      expect(validateEntry(withArgs(amount: '-5'), hasAccounts: true), contains('above zero'));
    });

    test('category required, account required only when accounts exist', () {
      expect(validateEntry(withArgs(category: '  '), hasAccounts: true), contains('category'));
      expect(validateEntry(withArgs(accountId: ''), hasAccounts: true), contains('source'));
      expect(validateEntry(withArgs(accountId: ''), hasAccounts: false), isNull);
    });
  });

  group('monthly sums + suggestions', () {
    late AppDatabase db;
    late TransactionRepository txns;

    setUp(() async {
      db = AppDatabase.memory();
      txns = TransactionRepository(db);
      final acc = await AccountRepository(db).create(name: 'Cash');
      Future<void> add(String kind, double actual, double budget, String cat, DateTime at) =>
          txns.add(kind: kind, actual: actual, budgetImpact: budget, dateTime: at, categoryRaw: cat, accountId: acc.id);
      await add('out', -65, -65, 'food junk gobi-65', DateTime(2026, 9, 1));
      await add('in', 5000, 5000, 'salary monthly pay', DateTime(2026, 9, 2));
      await add('neutral', -2000, 0, 'lend friend ravi-loan', DateTime(2026, 9, 3));
      await add('out', -100, -100, 'food junk gobi-65', DateTime(2026, 8, 20));
    });

    tearDown(() => db.close());

    test('sumsBetween separates statement vs budget truth', () async {
      final s = await txns.sumsBetween(DateTime(2026, 9, 1), DateTime(2026, 9, 30, 23, 59));
      expect(s.count, 3);
      expect(s.inActual, 5000);
      expect(s.outActual, -2065); // bank truth includes the loan
      expect(s.inBudget, 5000);
      expect(s.outBudget, -65); // planning truth excludes the loan
    });

    test('suggestions match past categories', () async {
      expect(await txns.suggestions('gobi'), contains('food junk gobi-65'));
      expect(await txns.suggestions(''), hasLength(3));
      expect(await txns.suggestions('zzz'), isEmpty);
    });
  });
}
