/// Month report — one plain data model that every output format renders.
///
/// The owner asked for a downloadable report "with all that month details
/// including the in and out splits lends and borrow settled network", across
/// more than one month. So the model is: a list of [ReportMonth] blocks, each
/// with its own totals, budget, splits, lends/borrows and settlements, and
/// every renderer (screen, CSV, Excel, PDF) reads exactly this.
library;

import 'dart:convert';

import 'package:intl/intl.dart';

import '../database.dart';

final _money = NumberFormat('#,##0.##', 'en_IN');

/// One table row, with a stable column set so CSV and Excel line up.
class ReportRow {
  final String section;
  final String date;
  final String description;
  final String category;
  final String bucket;
  final String person;
  final String account;
  final String kind;
  final double actual;
  final double budgetImpact;
  final bool absorbed;
  final bool neutral;

  const ReportRow({
    required this.section,
    required this.date,
    required this.description,
    required this.category,
    required this.bucket,
    required this.person,
    required this.account,
    required this.kind,
    required this.actual,
    required this.budgetImpact,
    this.absorbed = false,
    this.neutral = false,
  });

  /// Statement truth: what actually moved in the account.
  String get inAmount => actual > 0 ? _money.format(actual) : '';
  String get outAmount => actual < 0 ? _money.format(actual.abs()) : '';
  String get budgetAmount => budgetImpact == 0 ? '' : _money.format(budgetImpact.abs());

  List<String> get cells => [
        date,
        description,
        category,
        bucket,
        person,
        account,
        kind,
        inAmount,
        outAmount,
        budgetAmount,
        neutral ? (absorbed ? 'absorbed' : 'held out') : '',
      ];

  static const headers = [
    'Date',
    'Description',
    'Category',
    'Bucket',
    'Person',
    'Account',
    'Kind',
    'In',
    'Out',
    'Budget hit',
    'Neutral',
  ];

  Map<String, dynamic> toMap() => {
        'Date': date,
        'Description': description,
        'Category': category,
        'Bucket': bucket,
        'Person': person,
        'Account': account,
        'Kind': kind,
        'In': inAmount,
        'Out': outAmount,
        'Budget hit': budgetAmount,
        'Neutral': neutral ? (absorbed ? 'absorbed' : 'held out') : '',
      };
}

class ReportMonth {
  final String monthKey;
  final double income;
  final double spend;
  final double neutralOut;
  final double neutralIn;
  final double budgetTotal;
  final List<String> buckets;
  final List<ReportRow> rows;
  final List<ReportLine> lends;
  final List<ReportLine> borrows;
  final List<ReportLine> settlements;
  final List<ReportLine> splits;

  const ReportMonth({
    required this.monthKey,
    required this.income,
    required this.spend,
    required this.neutralOut,
    required this.neutralIn,
    required this.budgetTotal,
    required this.buckets,
    required this.rows,
    required this.lends,
    required this.borrows,
    required this.settlements,
    required this.splits,
  });

  double get net => income - spend;
  String get label => MonthReportBuilder.monthName(monthKey);
}

/// One line of a lend/borrow/split/settlement, flattened for display.
class ReportLine {
  final String title;
  final String who;
  final String status;
  final double amount;
  final double settled;
  final String detail;

  const ReportLine({
    required this.title,
    required this.who,
    required this.status,
    required this.amount,
    required this.settled,
    required this.detail,
  });

  double get open => (amount - settled).clamp(0, double.infinity);
}

class MonthReportBuilder {
  final AppDatabase db;
  const MonthReportBuilder(this.db);

  /// Builds every month in [months] (oldest first). Pure apart from the reads,
  /// so the same call feeds the screen and every file format.
  Future<List<ReportMonth>> build(List<String> months) async {
    final accounts = await db.allAccounts();
    final accountName = {for (final a in accounts) a.id: a.name};
    final debts = await db.allDebts();
    final splits = await db.allSplits();
    final budgetRows = await db.allBudgets();
    final all = await db.allTransactions();

    String monthOf(DateTime at) => '${at.year}-${at.month.toString().padLeft(2, '0')}';
    String dateOf(DateTime at) => DateFormat('d MMM yyyy HH:mm').format(at);

    final out = <ReportMonth>[];
    for (final month in months) {
      final rows = <ReportRow>[];
      final lends = <ReportLine>[];
      final borrows = <ReportLine>[];
      final settlements = <ReportLine>[];
      final splitLines = <ReportLine>[];
      var income = 0.0, spend = 0.0, neutralOut = 0.0, neutralIn = 0.0;

      final monthRows = [for (final t in all) if (monthOf(t.occurredAt) == month) t];
      for (final t in monthRows) {
        final neutral = t.kind == 'lend' || t.kind == 'borrow' || t.linkType == 'debt';
        final budget = t.absorbed == 1 ? t.actual : t.budgetImpact;
        if (neutral && t.absorbed == 0) {
          if (t.actual < 0) {
            neutralOut += t.actual.abs();
          } else {
            neutralIn += t.actual;
          }
        } else if (budget < 0) {
          spend += budget.abs();
        } else {
          income += budget;
        }
        rows.add(
          ReportRow(
            section: neutral ? 'Lending' : 'Entries',
            date: dateOf(t.occurredAt),
            description: t.note ?? '',
            category: t.categoryRaw,
            bucket: t.bucket ?? '',
            person: t.person ?? '',
            account: accountName[t.accountId] ?? '',
            kind: t.kind,
            actual: t.actual,
            budgetImpact: budget,
            absorbed: t.absorbed == 1,
            neutral: neutral,
          ),
        );
      }

      for (final d in debts.where((d) => monthOf(d.createdAt) == month)) {
        final line = ReportLine(
          title: d.note?.isNotEmpty == true ? d.note! : (d.direction == 'lent' ? 'Lent' : 'Borrowed'),
          who: d.counterparty,
          status: d.status,
          amount: d.principal,
          settled: d.paid,
          detail: d.dueDate == null ? '' : 'due ${DateFormat('d MMM yyyy').format(d.dueDate!)}',
        );
        (d.direction == 'lent' ? lends : borrows).add(line);
        settlements.add(
          ReportLine(
            title: '${d.direction == 'lent' ? 'Lent' : 'Borrowed'} · ${d.counterparty}',
            who: d.counterparty,
            status: d.status,
            amount: d.principal,
            settled: d.paid,
            detail: d.paid <= 0 ? 'nothing returned yet' : 'partly back',
          ),
        );
      }

      for (final s in splits) {
        final front = monthRows.where((t) => t.linkType == 'split' && t.linkId == s.id).firstOrNull;
        if (front == null) continue;
        final members = (jsonDecode(s.membersJson) as List).map((e) => e.toString()).toList();
        splitLines.add(
          ReportLine(
            title: s.title,
            who: members.isEmpty ? '(no names recorded)' : members.join(', '),
            status: s.status,
            amount: s.totalPaid,
            settled: s.received + s.absorbed,
            detail: 'my share ₹${s.myShare.round()}',
          ),
        );
      }

      final budget = budgetRows.where((b) => b.month == month).firstOrNull;
      out.add(
        ReportMonth(
          monthKey: month,
          income: income,
          spend: spend,
          neutralOut: neutralOut,
          neutralIn: neutralIn,
          budgetTotal: budget?.total ?? 0,
          buckets: budget == null ? const [] : [for (final m in jsonDecode(budget.bucketsJson) as List) (m as Map)['name'].toString()],
          rows: rows,
          lends: lends,
          borrows: borrows,
          settlements: settlements,
          splits: splitLines,
        ),
      );
    }
    return out;
  }

  /// "2026-09" -> "September 2026".
  static String monthName(String key) {
    final parts = key.split('-');
    return DateFormat('MMMM yyyy').format(DateTime(int.parse(parts[0]), int.parse(parts[1])));
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}