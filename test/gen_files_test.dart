import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/database.dart';
import 'package:expense_tracker/core/report/month_report.dart';
import 'package:expense_tracker/core/report/report_writer.dart';
import 'package:expense_tracker/features/customization/account_repository.dart';
import 'package:expense_tracker/features/transactions/transaction_repository.dart';

void main() {
  test('write the three files to disk for inspection', () async {
    final db = AppDatabase.memory();
    final cash = (await AccountRepository(db).create(name: 'Cash', kind: 'cash')).id;
    final txns = TransactionRepository(db);
    await txns.add(kind: 'in', actual: 60000, budgetImpact: 60000, dateTime: DateTime(2026, 9, 1), categoryRaw: 'salary', accountId: cash);
    await txns.add(kind: 'out', actual: -450, budgetImpact: -450, dateTime: DateTime(2026, 9, 2), categoryRaw: 'food chai cutting', accountId: cash);
    final months = await MonthReportBuilder(db).build(['2026-09']);
    final out = Directory('/tmp/opencode/exports')..createSync(recursive: true);
    File('${out.path}/r.csv').writeAsStringSync(renderCsv(months));
    File('${out.path}/r.xlsx').writeAsBytesSync(renderXlsx(months));
    File('${out.path}/r.pdf').writeAsBytesSync(await renderPdf(months));
    // ignore: avoid_print
    print('WRITTEN ${out.path}');
    await db.close();
  });
}
