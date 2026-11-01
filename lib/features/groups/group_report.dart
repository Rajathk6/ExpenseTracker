/// A group's own report: what it spent, who spent it, on what, the biggest
/// item, the category split, the daily trend, the balances, the settle-up and
/// the settlements — as a file you can keep or share.
///
/// It is the same numbers as the group's insights card and dashboard
/// (group_insight.dart), so the screen and every file format agree.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart' show csv;
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/database.dart';
import '../../core/export/export_paths.dart';
import '../../core/report/report_writer.dart' show ReportFormat;
import 'group_insight.dart';
import 'group_repository.dart';

/// Builds the report for one group.
Future<GroupInsightReport> buildGroupReport(
  GroupRepository repo,
  Group group,
) async {
  return buildGroupInsight(
    name: group.name,
    code: group.code,
    monthKey: group.monthKey,
    members: await repo.people(group.id),
    expenses: await repo.expenses(group.id),
    payments: await repo.payments(group.id),
  );
}

typedef _ReportRow = ({List<dynamic> cells, bool header});

String _money(double value) => value.toStringAsFixed(2);

String _day(DateTime at) =>
    '${at.year.toString().padLeft(4, '0')}-${at.month.toString().padLeft(2, '0')}-${at.day.toString().padLeft(2, '0')}';

List<_ReportRow> _rows(GroupInsightReport report) {
  final rows = <_ReportRow>[];
  void add(List<dynamic> cells, {bool header = false}) => rows.add((cells: cells, header: header));

  add(['GROUP'], header: true);
  add(['Name', report.name]);
  add(['Code', report.code]);
  add(['Month', report.monthKey]);
  add(['Total spent', _money(report.totalSpent)]);
  add(['Entries', report.expenseCount]);
  add(['People', report.peopleCount]);
  add(['Average entry', _money(report.averageEntry)]);
  add(['Settled', _money(report.settledAmount)]);
  add(['Settlements recorded', report.settlementCount]);
  add([]);

  final total = report.totalSpent <= 0 ? 1 : report.totalSpent;
  add(['CATEGORIES'], header: true);
  add(['Category', 'Amount', 'Entries', 'Share of total'], header: true);
  for (final c in report.perCategory) {
    add([c.label, _money(c.amount), c.count, '${(c.amount / total * 100).toStringAsFixed(1)}%']);
  }
  add([]);

  add(['WHO SPENT WHAT'], header: true);
  add(['Who', 'Amount', 'Share of total'], header: true);
  for (final p in report.perPerson) {
    add([p.label, _money(p.amount), '${(p.amount / total * 100).toStringAsFixed(1)}%']);
  }
  add([]);

  add(['SPENT ON'], header: true);
  add(['What', 'Amount', 'Times'], header: true);
  for (final t in report.perTitle) {
    add([t.label, _money(t.amount), t.count]);
  }
  add([]);

  add(['DAILY SPEND'], header: true);
  add(['Date', 'Amount', 'Entries'], header: true);
  for (final d in report.daily) {
    add([_day(d.date), _money(d.amount), d.count]);
  }
  add([]);

  add(['BALANCES'], header: true);
  add(['Who', 'Gets back', 'Owes'], header: true);
  for (final b in report.balances) {
    add([b.name, b.isOwed ? _money(b.net) : '', b.owes ? _money(-b.net) : '']);
  }
  add([]);

  add(['SETTLE UP'], header: true);
  add(['From', 'To', 'Amount'], header: true);
  for (final move in report.settleUp) {
    add([move.from, move.to, _money(move.amount)]);
  }
  add([]);

  add(['SETTLEMENTS'], header: true);
  add(['Date', 'From', 'To', 'Amount', 'Note'], header: true);
  for (final p in report.payments) {
    add([_day(p.occurredAt), p.paidBy, p.paidTo, _money(p.amount), p.note ?? '']);
  }
  add([]);

  add(['EXPENSES'], header: true);
  add(['Date', 'Title', 'Category', 'Amount', 'Paid by', 'Shared with', 'Note'], header: true);
  for (final e in report.expenses) {
    final shared = sharedWithOf(e);
    add([
      _day(e.occurredAt),
      e.title,
      e.category?.trim().isNotEmpty == true ? e.category : 'Uncategorised',
      _money(e.amount),
      e.paidBy.isEmpty ? 'Nobody (split evenly)' : e.paidBy,
      shared.isEmpty ? 'Everyone' : shared.join(', '),
      e.note ?? '',
    ]);
  }
  add([]);

  add(['INSIGHTS'], header: true);
  for (final line in report.lines) {
    add([line]);
  }
  return rows;
}

/// The report as CSV text — one section per part, so a spreadsheet shows it
/// clearly.
String renderGroupCsv(GroupInsightReport report) =>
    csv.encode([for (final row in _rows(report)) row.cells]);

/// The report as a real .xlsx workbook.
Uint8List renderGroupXlsx(GroupInsightReport report) {
  final book = Excel.createExcel();
  final sheet = book['Group'];
  for (final row in _rows(report)) {
    sheet.appendRow([
      for (final cell in row.cells)
        cell is num ? DoubleCellValue(cell.toDouble()) : TextCellValue(cell.toString()),
    ]);
    if (row.header) {
      for (final cell in sheet.rows.last) {
        cell?.cellStyle = CellStyle(bold: true, verticalAlign: VerticalAlign.Center);
      }
    }
  }
  return Uint8List.fromList(book.encode() ?? const <int>[]);
}

/// The report as a printable PDF.
Future<Uint8List> renderGroupPdf(GroupInsightReport report) async {
  final doc = pw.Document();
  // The built-in PDF font has no rupee glyph, so the PDF says "Rs".
  String money(double v) => 'Rs ${v.abs().round()}';

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => [
        pw.Text('ExpenseTracker - ${report.name}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(
          'Group ${report.code} · ${report.monthKey} · generated ${DateTime.now().toIso8601String().substring(0, 16)}',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 10),
        _totals(report, money),
        pw.SizedBox(height: 12),
        _section('Categories'),
        _table(
          ['Category', 'Amount', 'Entries', 'Share'],
          [
            for (final c in report.perCategory)
              [
                _clip(c.label, 28),
                money(c.amount),
                '${c.count}',
                '${(c.amount / (report.totalSpent <= 0 ? 1 : report.totalSpent) * 100).toStringAsFixed(1)}%',
              ],
          ],
        ),
        if (report.daily.isNotEmpty) ...[
          _section('Daily spend'),
          _table(
            ['Date', 'Amount', 'Entries'],
            [for (final d in report.daily) [_day(d.date), money(d.amount), '${d.count}']],
          ),
        ],
        if (report.perPerson.isNotEmpty) ...[
          _section('Who spent'),
          _table(
            ['Who', 'Amount', 'Share'],
            [
              for (final p in report.perPerson)
                [
                  _clip(p.label, 28),
                  money(p.amount),
                  '${(p.amount / (report.totalSpent <= 0 ? 1 : report.totalSpent) * 100).toStringAsFixed(1)}%',
                ],
            ],
          ),
        ],
        _section('Balances'),
        _table(
          ['Who', 'Gets back', 'Owes'],
          [
            for (final b in report.balances)
              [_clip(b.name, 28), b.isOwed ? money(b.net) : '', b.owes ? money(-b.net) : ''],
          ],
        ),
        _section('Settle up'),
        _table(
          ['From', 'To', 'Amount'],
          [for (final move in report.settleUp) [_clip(move.from, 24), _clip(move.to, 24), money(move.amount)]],
        ),
        if (report.payments.isNotEmpty) ...[
          _section('Settlements'),
          _table(
            ['Date', 'From', 'To', 'Amount', 'Note'],
            [
              for (final p in report.payments)
                [_day(p.occurredAt), _clip(p.paidBy, 18), _clip(p.paidTo, 18), money(p.amount), _clip(p.note ?? '', 24)],
            ],
          ),
        ],
        if (report.expenses.isNotEmpty) ...[
          _section('Expenses'),
          _table(
            ['Date', 'Title', 'Category', 'Amount', 'Paid by'],
            [
              for (final e in report.expenses)
                [
                  _day(e.occurredAt),
                  _clip(e.title, 24),
                  _clip(e.category?.trim().isNotEmpty == true ? e.category! : 'Uncategorised', 18),
                  money(e.amount),
                  _clip(e.paidBy.isEmpty ? 'Nobody' : e.paidBy, 18),
                ],
            ],
          ),
        ],
        _section('Insights'),
        for (final line in report.lines)
          pw.Bullet(
            text: line.replaceAll('₹', 'Rs ').replaceAll('—', '-'),
            style: const pw.TextStyle(fontSize: 9),
          ),
      ],
    ),
  );
  return doc.save();
}

/// Writes the group's report to Downloads and returns the path.
Future<String> writeGroupReport(
  GroupInsightReport report, {
  ReportFormat format = ReportFormat.csv,
}) async {
  final paths = await ExportPaths.resolve();
  final name = paths.stamped(format.extension, tag: 'group-${report.code}').uri.pathSegments.last;
  final bytes = switch (format) {
    ReportFormat.csv => Uint8List.fromList(utf8.encode(renderGroupCsv(report))),
    ReportFormat.xlsx => renderGroupXlsx(report),
    ReportFormat.pdf => await renderGroupPdf(report),
  };
  if (bytes.isEmpty) {
    throw StateError('The file was written empty — nothing to open');
  }
  return ExportPaths.save(name, bytes, paths.directory);
}

pw.Widget _totals(GroupInsightReport report, String Function(double) money) => pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Wrap(
        spacing: 22,
        runSpacing: 6,
        children: [
          _total('Spent', money(report.totalSpent)),
          _total('Entries', '${report.expenseCount}'),
          _total('People', '${report.peopleCount}'),
          _total('Average', money(report.averageEntry)),
          _total('Settled', money(report.settledAmount)),
          _total('Settlements', '${report.settlementCount}'),
        ],
      ),
    );

pw.Widget _total(String label, String value) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );

pw.Widget _section(String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14, bottom: 4),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
    );

pw.Widget _table(List<String> headers, List<List<String>> rows) {
  if (rows.isEmpty) return pw.Text('Nothing recorded.', style: const pw.TextStyle(fontSize: 9));
  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
    cellStyle: const pw.TextStyle(fontSize: 8),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
  );
}

String _clip(String value, int max) => value.length <= max ? value : '${value.substring(0, max - 3)}...';
