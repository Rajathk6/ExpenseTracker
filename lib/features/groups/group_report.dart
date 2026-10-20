/// A group's own report: what it spent, who spent it, on what, the biggest
/// item, the balances and the settle-up — as a file you can keep or share.
///
/// It is the same numbers as the group's insights card (group_insight.dart),
/// so the screen and the file can never disagree.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart' show csv;

import '../../core/database.dart';
import '../../core/export/export_paths.dart';
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

/// The report as CSV text — one section per part, so a spreadsheet shows it
/// clearly.
String renderGroupCsv(GroupInsightReport report) {
  final rows = <List<dynamic>>[];
  rows.add(['GROUP', report.name]);
  rows.add(['Code', report.code]);
  rows.add(['Month', report.monthKey]);
  rows.add(['Total spent', report.totalSpent.toStringAsFixed(2)]);
  rows.add(['People', report.peopleCount]);
  rows.add([]);
  rows.add(['WHO SPENT WHAT']);
  rows.add(['Who', 'Amount', 'Share of total']);
  final total = report.totalSpent <= 0 ? 1 : report.totalSpent;
  for (final p in report.perPerson) {
    rows.add([p.label, p.amount.toStringAsFixed(2), '${(p.amount / total * 100).toStringAsFixed(1)}%']);
  }
  rows.add([]);
  rows.add(['SPENT ON']);
  rows.add(['What', 'Amount', 'Times']);
  for (final t in report.perTitle) {
    rows.add([t.label, t.amount.toStringAsFixed(2), t.count]);
  }
  rows.add([]);
  rows.add(['BALANCES']);
  rows.add(['Who', 'Owed to them', 'They owe']);
  for (final b in report.balances) {
    rows.add([b.name, b.isOwed ? b.net.toStringAsFixed(2) : '', b.owes ? (-b.net).toStringAsFixed(2) : '']);
  }
  rows.add([]);
  rows.add(['SETTLE UP']);
  for (final move in report.settleUp) {
    rows.add(['${move.from} pays ${move.to}', move.amount.toStringAsFixed(2)]);
  }
  rows.add([]);
  rows.add(['INSIGHTS']);
  for (final line in report.lines) {
    rows.add([line]);
  }
  return csv.encode(rows);
}

/// Writes the group's report to Downloads and returns the path.
Future<String> writeGroupReport(GroupInsightReport report) async {
  final paths = await ExportPaths.resolve();
  final name = paths.stamped('csv', tag: 'group-${report.code}').uri.pathSegments.last;
  final bytes = Uint8List.fromList(utf8.encode(renderGroupCsv(report)));
  return ExportPaths.save(name, bytes, paths.directory);
}
