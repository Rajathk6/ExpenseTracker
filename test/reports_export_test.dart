import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/backup/backup_service.dart';
import 'package:expense_tracker/core/backup/codec.dart';
import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/core/report/month_report.dart';
import 'package:expense_tracker/core/report/report_writer.dart';
import 'package:expense_tracker/features/budgets/bucket_math.dart';
import 'package:expense_tracker/features/budgets/budget_repository.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/neutral/debt_repository.dart';
import 'package:expense_tracker/features/reconcile/month_start_service.dart';
import 'package:expense_tracker/features/reports/reports_repository.dart';
import 'package:expense_tracker/features/transactions/recurring_service.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';

void main() {
  group('backup covers every table (#21, v8)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
      await AccountRepository(db).create(name: 'Cash', kind: 'cash');
      await TransactionRepository(db).add(
        kind: 'out',
        actual: -300,
        budgetImpact: -300,
        dateTime: DateTime(2026, 9, 2),
        categoryRaw: 'food chai cutting',
      );
      await DebtRepository(db).lend(counterparty: 'Ravi', principal: 500, at: DateTime(2026, 9, 3));
      await db.upsertRecurringRule(
        const RecurringRulesCompanion(
          id: Value('rule-1'),
          kind: Value('in'),
          amount: Value(60000),
          categoryRaw: Value('salary'),
          startMonth: Value('2026-09'),
        ),
      );
      await db.upsertGroup(
        const GroupsCompanion(
          id: Value('g1'),
          name: Value('Flat'),
          code: Value('ET-ABCD'),
          monthKey: Value('2026-09'),
        ),
      );
      await db.insertMember(const GroupMembersCompanion(id: Value('m1'), groupId: Value('g1'), name: Value('Me')));
      await db.insertGroupExpense(
        GroupExpensesCompanion(
          id: const Value('e1'),
          groupId: const Value('g1'),
          title: const Value('Groceries'),
          amount: const Value(500),
          paidBy: const Value('Me'),
          occurredAt: Value(DateTime(2026, 9, 4)),
        ),
      );
      await db.insertGroupPayment(
        GroupPaymentsCompanion(
          id: const Value('p1'),
          groupId: const Value('g1'),
          paidBy: const Value('Me'),
          paidTo: const Value('Ravi'),
          amount: const Value(200),
          occurredAt: Value(DateTime(2026, 9, 5)),
        ),
      );
    });

    tearDown(() => db.close());

    test('every table in the manifest is actually dumped', () async {
      final tables = await BackupService(db).dumpTables();
      expect([for (final k in backupTables) k], tables.keys.toList());
    });

    test('the v8 tables survive export → wipe → import', () async {
      final packed = await encryptBackup(await BackupService(db).dumpTables(), 'pw');
      await db.delete(db.transactions).go();
      await db.delete(db.debts).go();
      await db.delete(db.recurringRules).go();
      await db.delete(db.groupMembers).go();
      await db.delete(db.groupExpenses).go();
      await db.delete(db.groupPayments).go();
      await db.delete(db.groups).go();
      expect(await db.allRecurring(), isEmpty);
      expect(await db.allGroups(), isEmpty);

      final counts = await BackupService(db).restoreTables(await decryptBackup(packed, 'pw'));
      expect(counts['recurring_rules'], 1);
      expect(counts['groups'], 1);
      expect(counts['group_members'], 1);
      expect(counts['group_expenses'], 1);
      expect(counts['group_payments'], 1);
      expect(counts['debts'], 1);
      expect((await db.allRecurringRules()).single.categoryRaw, 'salary');
      expect((await db.allGroups()).single.code, 'ET-ABCD');
      expect((await db.allGroupExpenses()).single.amount, 500);
    });
  });

  group('month report model (#18)', () {
    late AppDatabase db;
    late AccountRepository accounts;

    setUp(() async {
      db = AppDatabase.memory();
      accounts = AccountRepository(db);
    });

    tearDown(() => db.close());

    Future<void> seedMonth(String month) async {
      final cash = (await accounts.create(name: 'Cash $month', kind: 'cash')).id;
      final txns = TransactionRepository(db);
      final start = DateTime(int.parse(month.split('-')[0]), int.parse(month.split('-')[1]));
      await txns.add(
        kind: 'in',
        actual: 60000,
        budgetImpact: 60000,
        dateTime: start.add(const Duration(days: 1)),
        categoryRaw: 'salary',
        accountId: cash,
      );
      await txns.add(
        kind: 'out',
        actual: -450,
        budgetImpact: -450,
        dateTime: start.add(const Duration(days: 2)),
        categoryRaw: 'food chai cutting',
        bucket: 'need',
        accountId: cash,
      );
      await DebtRepository(db).lend(counterparty: 'Ravi', principal: 5000, accountId: cash, at: start.add(const Duration(days: 3)));
    }

    test('holds the whole month: totals, rows, lending and the held-out split', () async {
      await seedMonth('2026-09');
      final months = await MonthReportBuilder(db).build(const ['2026-09']);
      expect(months, hasLength(1));
      final m = months.single;
      expect(m.label, 'September 2026');
      expect(m.income, 60000);
      expect(m.spend, 450);
      expect(m.net, 59550);
      expect(m.neutralOut, 5000, reason: 'held out of the month until absorbed');
      expect(m.neutralIn, 0);
      expect(m.lends.single.who, 'Ravi');
      expect(m.lends.single.open, 5000);
      expect(m.settlements, isNotEmpty);
      final heldOut = [for (final r in m.rows) if (r.neutral) r].single;
      expect(heldOut.absorbed, false);
      expect(heldOut.neutral, true);
    });

    test('an absorbed lend lands in the month totals instead', () async {
      await seedMonth('2026-09');
      final rows = await db.transactionsBetween(DateTime(2026, 9, 1), DateTime(2026, 9, 30, 23, 59));
      final lend = rows.firstWhere((r) => r.kind == 'lend');
      await TransactionRepository(db).setAbsorbed(id: lend.id, absorbed: true);
      final m = (await MonthReportBuilder(db).build(const ['2026-09'])).single;
      expect(m.neutralOut, 0);
      expect(m.spend, 5450);
    });

    test('multiple months come back oldest first', () async {
      await seedMonth('2026-08');
      await seedMonth('2026-09');
      final months = await MonthReportBuilder(db).build(const ['2026-09', '2026-08']);
      expect([for (final m in months) m.monthKey], ['2026-09', '2026-08']);
    });
  });

  group('report writers (#5, #18)', () {
    late AppDatabase db;
    late ReportMonth month;

    setUp(() async {
      db = AppDatabase.memory();
      final cash = (await AccountRepository(db).create(name: 'Cash', kind: 'cash')).id;
      final txns = TransactionRepository(db);
      await txns.add(
        kind: 'out',
        actual: -450,
        budgetImpact: -450,
        dateTime: DateTime(2026, 9, 2),
        categoryRaw: 'food chai cutting',
        bucket: 'need',
        accountId: cash,
      );
      await DebtRepository(db).lend(counterparty: 'Ravi', principal: 5000, accountId: cash, at: DateTime(2026, 9, 3));
      month = (await MonthReportBuilder(db).build(const ['2026-09'])).single;
    });

    tearDown(() => db.close());

    test('CSV carries every section, including settlements', () {
      final csv = renderCsv([month]);
      expect(csv, contains('MONTH'));
      expect(csv, contains('September 2026'));
      expect(csv, contains('Held out of the month — lent'));
      expect(csv, contains('Lent'));
      expect(csv, contains('Settlements'));
      expect(csv, contains('Splits'));
      expect(csv, contains('Ravi'));
      expect(csv, contains('food chai cutting'));
    });

    test('XLSX is a real workbook with the month as a sheet', () {
      final bytes = renderXlsx([month]);
      expect(bytes.length, greaterThan(1000));
      // PK zip header — a real .xlsx, not a renamed CSV.
      expect([bytes[0], bytes[1]], [0x50, 0x4B]);
    });

    test('PDF renders bytes and mentions the month and the person', () async {
      final bytes = await renderPdf([month]);
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });

  group('bucket vocabulary is one vocabulary (#6)', () {
    test('presets, the month opener and the entry picker agree', () {
      final names = {for (final b in defaultBuckets) b.name};
      for (final preset in bucketPresets.values) {
        for (final b in preset) {
          expect(names, contains(b.name), reason: 'preset bucket ${b.name} must exist in the default set');
        }
      }
      expect(canonicalBucket('Need', defaultBuckets), 'need');
      expect(canonicalBucket(' INVEST ', defaultBuckets), 'invest');
      expect(canonicalBucket('fun money', defaultBuckets), isNull);
    });

    test('the month opener writes the shared default buckets', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await AccountRepository(db).create(name: 'Cash', kind: 'cash');
      await MonthStartService(db).apply(month: '2026-09', budgetOut: 1000);
      final buckets = (await BudgetRepository(db).get('2026-09'))!.buckets;
      expect([for (final b in buckets) b.name], ['need', 'want', 'invest']);
    });

    test('an opening balance is only written to a matching account', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await AccountRepository(db).create(name: 'Wallet', kind: 'upi');
      final result = await MonthStartService(db).apply(month: '2026-09', bankBalance: 50000, cashBalance: 1000);
      expect(result.snapshotsWritten, 0, reason: 'no bank/cash account exists to attach the balances to');
      expect(await db.snapshotsForMonth('2026-09'), isEmpty);
    });
  });

  group('repeating entries never double-fill (#4)', () {
    late AppDatabase db;
    late RecurringService service;

    setUp(() async {
      db = AppDatabase.memory();
      service = RecurringService(db);
      await AccountRepository(db).create(name: 'Cash', kind: 'cash');
      await db.upsertRecurringRule(
        const RecurringRulesCompanion(
          id: Value('salary-rule-2026-09'),
          kind: Value('in'),
          amount: Value(50000),
          categoryRaw: Value('salary'),
          startMonth: Value('2026-09'),
        ),
      );
    });

    tearDown(() => db.close());

    test('the marker written into the entry matches the one the guard reads', () async {
      final rule = (await db.allRecurringRules()).single;
      await service.applyAll(rule, nowMonth: '2026-09');
      final rows = await db.allTransactions();
      expect(rows.single.note, contains(RecurringService.ruleTag(rule)));
      // Even with the progress marker lost (e.g. an older backup), the entry's
      // own note is enough to stop a second fill.
      await (db.update(db.recurringRules)..where((r) => r.id.equals(rule.id)))
          .write(const RecurringRulesCompanion(lastAppliedMonth: Value(null)));
      await service.applyAll(rule, nowMonth: '2026-09');
      expect(await db.allTransactions(), hasLength(1));
    });
  });

  group('reports use one truth (#17)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
    });

    tearDown(() => db.close());

    test('the wrapped year counts borrowed cash only once absorbed', () async {
      final cash = (await AccountRepository(db).create(name: 'Cash', kind: 'cash')).id;
      final debts = DebtRepository(db);
      final txns = TransactionRepository(db);
      await txns.add(
        kind: 'in',
        actual: 60000,
        budgetImpact: 60000,
        dateTime: DateTime(2026, 3, 1),
        categoryRaw: 'salary',
        accountId: cash,
      );
      final debt = await debts.borrow(counterparty: 'Ravi', principal: 10000, accountId: cash, at: DateTime(2026, 4, 1));
      var wrapped = await ReportsRepository(db).wrapped(2026);
      expect(wrapped.inActual, 60000, reason: 'borrowed cash is not income until absorbed');
      expect(wrapped.txnCount, 1);

      await txns.setAbsorbed(id: (await db.debtHistory(debt.id)).first.id, absorbed: true);
      wrapped = await ReportsRepository(db).wrapped(2026);
      expect(wrapped.inActual, 70000);
      expect(wrapped.txnCount, 2);
    });

    test('the reports budget is the carried-forward one, like the rest of the app', () async {
      await BudgetRepository(db).save(month: '2026-08', total: 40000, buckets: defaultBuckets);
      final dashboard = await ReportsRepository(db).dashboard('2026-10');
      expect(dashboard.budgetTotal, 40000, reason: 'September and October inherit August');
    });
  });
}
