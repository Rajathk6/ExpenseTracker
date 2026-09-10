import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/splits/split_logic.dart';
import 'package:expense_tracker/features/splits/split_repository.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';

void main() {
  group('split math (pure)', () {
    test('1000 split by 10: my 100, receivable 900', () {
      expect(equalShare(1000, 10), 100);
      expect(splitRemaining(1000, 100, 0, 0), 900);
      expect(validateSplit(total: 1000, myShare: 100), isNull);
      expect(validateSplit(total: 1000, myShare: 1200), contains('exceed'));
      expect(validateSplit(total: 0, myShare: 0), contains('above zero'));
    });

    test('over-settle rejected', () {
      expect(
        validateSettlement(amount: 250, totalPaid: 1000, myShare: 100, received: 800, absorbed: 0),
        contains('Over-settle'),
      );
      expect(
        validateSettlement(amount: 100, totalPaid: 1000, myShare: 100, received: 800, absorbed: 0),
        isNull,
      );
      // Others never owed my share: 1000/100 caps recovery at 900.
      expect(
        validateSettlement(amount: 950, totalPaid: 1000, myShare: 100, received: 0, absorbed: 0),
        contains('Over-settle'),
      );
    });

    test('settle-up optimizer minimizes transfers', () {
      // I fronted 900 for Ravi(+300 owed to me?) — net: Ravi -300, Asha -100, Me +400.
      final plan = settleUp({'Me': 400, 'Ravi': -300, 'Asha': -100});
      expect(plan, hasLength(2));
      expect(plan.fold<double>(0, (s, t) => s + t.amount), 400);
      expect(plan.every((t) => t.to == 'Me'), isTrue);
      expect(settleUp({'A': 0, 'B': 0}), isEmpty);
    });
  });

  group('split lifecycle (front 1000, mine 100)', () {
    late AppDatabase db;
    late SplitRepository splits;
    late TransactionRepository txns;
    late String cashId;

    setUp(() async {
      db = AppDatabase.memory();
      splits = SplitRepository(db);
      txns = TransactionRepository(db);
      cashId = (await AccountRepository(db).create(name: 'Cash')).id;
    });

    tearDown(() => db.close());

    test('create → partial settles → absorb rest → closed + honest budget', () async {
      final s0 = await splits.create(
        title: 'Dinner',
        total: 1000,
        myShare: 100,
        accountId: cashId,
        at: DateTime(2026, 9, 1),
      );
      expect(s0.status, 'open');

      // Month sees bank -1000 but budget -100.
      final sums = await txns.sumsBetween(DateTime(2026, 9, 1), DateTime(2026, 9, 30, 23, 59));
      expect(sums.outActual, -1000);
      expect(sums.outBudget, -100);

      // Two friends pay 300 each (reconciles to bank as +600 in).
      var s = await splits.settle(splitId: s0.id, amount: 300, who: 'Ravi', accountId: cashId, at: DateTime(2026, 9, 5));
      s = await splits.settle(splitId: s.id, amount: 300, who: 'Asha', accountId: cashId, at: DateTime(2026, 9, 6));
      expect(s.received, 600);
      expect(s.status, 'open');
      expect(splitRemaining(s.totalPaid, s.myShare, s.received, s.absorbed), 300);
      expect(() => splits.settle(splitId: s.id, amount: 500), throwsArgumentError);

      // Last 300 never comes: absorb → budget takes the hit, bank untouched.
      s = await splits.absorb(splitId: s.id, amount: 300, note: 'Kiran defaulted', at: DateTime(2026, 9, 20));
      expect(s.status, 'closed');
      expect(s.absorbed, 300);

      final after = await txns.sumsBetween(DateTime(2026, 9, 1), DateTime(2026, 9, 30, 23, 59));
      expect(after.outActual, -1000); // the original payment
      expect(after.inActual, 600); // friends paid back (reconciles to bank)
      expect(after.inActual + after.outActual, -400); // net bank impact
      expect(after.outBudget, -400); // -100 share, -300 absorbed default
      expect(() => splits.settle(splitId: s.id, amount: 10), throwsStateError);

      final trail = await splits.history(s0.id);
      expect(trail.map((t) => t.kind), ['split', 'settle', 'settle', 'absorb']);
    });

    test('full recovery closes with budget = my share only', () async {
      final s0 = await splits.create(title: 'Trip', total: 1000, myShare: 100, accountId: cashId, at: DateTime(2026, 9, 1));
      final s = await splits.settle(splitId: s0.id, amount: 900, accountId: cashId, at: DateTime(2026, 9, 2));
      expect(s.status, 'closed');
      final sums = await txns.sumsBetween(DateTime(2026, 9, 1), DateTime(2026, 9, 30, 23, 59));
      expect(sums.inActual + sums.outActual, -100); // net: only my share left the bank
      expect(sums.outBudget, -100);
    });
  });
}
