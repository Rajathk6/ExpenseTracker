/// Writing a month report out as a file: CSV (opens in Excel), real .xlsx,
/// and PDF. All three render the same [ReportMonth] model, all three land in
/// Downloads/ExpenseTracker with the path returned so the app can show it.
///
/// No native dependencies: `pdf`, `csv` and `excel` are pure Dart.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../export/export_paths.dart';
import 'month_report.dart';

enum ReportFormat {
  csv('CSV', 'Opens in Excel / Sheets'),
  xlsx('Excel', 'Real .xlsx workbook'),
  pdf('PDF', 'Printable summary');

  const ReportFormat(this.label, this.hint);
  final String label;
  final String hint;

  String get extension => switch (this) {
        ReportFormat.csv => 'csv',
        ReportFormat.xlsx => 'xlsx',
        ReportFormat.pdf => 'pdf',
      };
}

/// Writes [months] in [format] and returns the file path.
Future<String> writeReport({
  required List<ReportMonth> months,
  required ReportFormat format,
  String? tag,
}) async {
  final paths = await ExportPaths.resolve();
  final name = paths.stamped(
    format.extension,
    tag: tag ?? (months.length == 1 ? months.first.monthKey : '${months.length}months'),
  ).uri.pathSegments.last;
  final bytes = switch (format) {
    ReportFormat.csv => Uint8List.fromList(utf8.encode(renderCsv(months))),
    ReportFormat.xlsx => renderXlsx(months),
    ReportFormat.pdf => await renderPdf(months),
  };
  return ExportPaths.save(name, bytes, paths.directory);
}

String renderCsv(List<ReportMonth> months) {
  final rows = <List<dynamic>>[];
  for (final m in months) {
    rows.add(['MONTH', m.label]);
    rows.add(['In (budget truth)', m.income.toStringAsFixed(2)]);
    rows.add(['Out (budget truth)', m.spend.toStringAsFixed(2)]);
    rows.add(['Net', m.net.toStringAsFixed(2)]);
    rows.add(['Held out of the month — lent', m.neutralOut.toStringAsFixed(2)]);
    rows.add(['Held out of the month — received', m.neutralIn.toStringAsFixed(2)]);
    rows.add(['Budget', m.budgetTotal.toStringAsFixed(2)]);
    if (m.buckets.isNotEmpty) rows.add(['Buckets', m.buckets.join(' / ')]);
    rows.add([]);
    rows.add(ReportRow.headers);
    for (final r in m.rows) {
      rows.add(r.cells);
    }
    rows.add([]);
    rows.add(['Lent']);
    rows.add(['What', 'Who', 'Status', 'Amount', 'Back so far', 'Still open', 'Detail']);
    for (final l in m.lends) {
      rows.add([l.title, l.who, l.status, l.amount.toStringAsFixed(2), l.settled.toStringAsFixed(2), l.open.toStringAsFixed(2), l.detail]);
    }
    rows.add([]);
    rows.add(['Borrowed']);
    rows.add(['What', 'Who', 'Status', 'Amount', 'Back so far', 'Still open', 'Detail']);
    for (final l in m.borrows) {
      rows.add([l.title, l.who, l.status, l.amount.toStringAsFixed(2), l.settled.toStringAsFixed(2), l.open.toStringAsFixed(2), l.detail]);
    }
    rows.add([]);
    rows.add(['Settlements']);
    rows.add(['What', 'Who', 'Status', 'Amount', 'Back', 'Still open', 'Detail']);
    for (final l in m.settlements) {
      rows.add([l.title, l.who, l.status, l.amount.toStringAsFixed(2), l.settled.toStringAsFixed(2), l.open.toStringAsFixed(2), l.detail]);
    }
    rows.add([]);
    rows.add(['Splits']);
    rows.add(['Title', 'People', 'Status', 'I paid', 'Came back', 'Still out', 'Detail']);
    for (final l in m.splits) {
      rows.add([l.title, l.who, l.status, l.amount.toStringAsFixed(2), l.settled.toStringAsFixed(2), l.open.toStringAsFixed(2), l.detail]);
    }
    rows.add([]);
    rows.add([]);
  }
  // `csv` is the package's default codec instance; Excel's quoting rules keep
  // rupee amounts and commas intact when the file is opened.
  return excel.encode(rows);
}

Uint8List renderXlsx(List<ReportMonth> months) {
  final book = Excel.createExcel();
  for (final m in months) {
    final name = m.label.length > 28 ? m.monthKey : m.label;
    void row(List<dynamic> cells, {bool header = false}) {
      book[name].appendRow([
        for (final c in cells)
          c is num ? DoubleCellValue(c.toDouble()) : TextCellValue(c.toString()),
      ]);
      if (header) {
        final sheet = book[name];
        final last = sheet.rows.last;
        for (final cell in last) {
          cell?.cellStyle = CellStyle(bold: true, verticalAlign: VerticalAlign.Center);
        }
      }
    }

    row([name], header: true);
    row(['In (budget truth)', m.income]);
    row(['Out (budget truth)', m.spend]);
    row(['Net', m.net]);
    row(['Held out — lent', m.neutralOut]);
    row(['Held out — received', m.neutralIn]);
    row(['Budget', m.budgetTotal]);
    if (m.buckets.isNotEmpty) row(['Buckets', m.buckets.join(' / ')]);
    row([]);
    row(ReportRow.headers, header: true);
    for (final r in m.rows) {
      row(r.cells);
    }
    row([]);
    row(['Lent'], header: true);
    row(['What', 'Who', 'Status', 'Amount', 'Back', 'Still open', 'Detail']);
    for (final l in m.lends) {
      row([l.title, l.who, l.status, l.amount, l.settled, l.open, l.detail]);
    }
    row([]);
    row(['Borrowed'], header: true);
    row(['What', 'Who', 'Status', 'Amount', 'Back', 'Still open', 'Detail']);
    for (final l in m.borrows) {
      row([l.title, l.who, l.status, l.amount, l.settled, l.open, l.detail]);
    }
    row([]);
    row(['Settlements'], header: true);
    row(['What', 'Who', 'Status', 'Amount', 'Back', 'Still open', 'Detail']);
    for (final l in m.settlements) {
      row([l.title, l.who, l.status, l.amount, l.settled, l.open, l.detail]);
    }
    row([]);
    row(['Splits'], header: true);
    row(['Title', 'People', 'Status', 'I paid', 'Came back', 'Still out', 'Detail']);
    for (final l in m.splits) {
      row([l.title, l.who, l.status, l.amount, l.settled, l.open, l.detail]);
    }
  }
  return Uint8List.fromList(book.encode() ?? const <int>[]);
}

Future<Uint8List> renderPdf(List<ReportMonth> months) async {
  final doc = pw.Document();
  String money(double v) => '₹${v.abs().round()}';

  for (final m in months) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text('ExpenseTracker — ${m.label}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Offline report · budget truth shown as In/Out · generated '
            '${DateTime.now().toIso8601String().substring(0, 16)}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 12),
          _pdfTotals(m, money),
          pw.SizedBox(height: 12),
          pw.Text('Entries', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _pdfTable(
            ['Date', 'Description', 'Category', 'In', 'Out'],
            [for (final r in m.rows) [r.date, _clip(r.description, 24), _clip(r.category, 22), r.inAmount, r.outAmount]],
            widths: {0: const pw.FixedColumnWidth(72), 1: const pw.FlexColumnWidth(3), 2: const pw.FlexColumnWidth(3), 3: const pw.FixedColumnWidth(52), 4: const pw.FixedColumnWidth(52)},
          ),
          if (m.lends.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text('Lent', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            _pdfTable(
              ['Who', 'Status', 'Amount', 'Back', 'Still open'],
              [for (final l in m.lends) [l.who, l.status, money(l.amount), money(l.settled), money(l.open)]],
            ),
          ],
          if (m.borrows.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text('Borrowed', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            _pdfTable(
              ['Who', 'Status', 'Amount', 'Back', 'Still open'],
              [for (final l in m.borrows) [l.who, l.status, money(l.amount), money(l.settled), money(l.open)]],
            ),
          ],
          if (m.settlements.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text('Settlements', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            _pdfTable(
              ['Who', 'Status', 'Amount', 'Back', 'Still open'],
              [for (final l in m.settlements) [l.who, l.status, money(l.amount), money(l.settled), money(l.open)]],
            ),
          ],
          if (m.splits.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text('Splits', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            _pdfTable(
              ['Title', 'People', 'I paid', 'Came back', 'Still out'],
              [for (final l in m.splits) [l.title, _clip(l.who, 26), money(l.amount), money(l.settled), money(l.open)]],
            ),
          ],
        ],
      ),
    );
  }
  return doc.save();
}

pw.Widget _pdfTotals(ReportMonth m, String Function(double) money) => pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Wrap(
        spacing: 24,
        runSpacing: 6,
        children: [
          _total('In', money(m.income)),
          _total('Out', money(m.spend)),
          _total('Net', money(m.net)),
          _total('Budget', money(m.budgetTotal)),
          _total('Held out (lent)', money(m.neutralOut)),
          _total('Held out (received)', money(m.neutralIn)),
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

pw.Widget _pdfTable(List<String> headers, List<List<String>> rows, {Map<int, pw.TableColumnWidth> widths = const {}}) =>
    pw.TableHelper.fromTextArray(
      headers: headers,
      data: [for (final r in rows) r],
      headerCount: 1,
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellPadding: const pw.EdgeInsets.all(3),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
      columnWidths: widths.isEmpty ? null : Map<int, pw.TableColumnWidth>.from(widths),
    );

String _clip(String value, int max) => value.length <= max ? value : '${value.substring(0, max - 1)}…';