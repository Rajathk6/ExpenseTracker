/// Month close-out screen: per-account opening + physically-counted close,
/// expected-vs-counted gap report, planning truth, and links to price
/// memory + net worth. Reads the ledger, never writes it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'networth_screen.dart';
import 'price_screen.dart';
import 'reconcile_logic.dart';
import 'reconcile_repository.dart';

class ReconcileScreen extends ConsumerStatefulWidget {
  const ReconcileScreen({super.key});

  @override
  ConsumerState<ReconcileScreen> createState() => _ReconcileScreenState();
}

class _ReconcileScreenState extends ConsumerState<ReconcileScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final key = monthKey(_month);
    final report = ref.watch(monthReportProvider(key));
    return Scaffold(
      appBar: AppBar(title: const Text('Reconcile')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _month = monthStart(shiftMonthKey(key, -1))),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(key, style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                onPressed: () => setState(() => _month = monthStart(shiftMonthKey(key, 1))),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          report.when(
            data: (r) => _ReportBody(
              report: r,
              onSaved: () => ref.invalidate(monthReportProvider(key)),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Report unavailable: $e'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PriceScreen())),
                  icon: const Icon(Icons.sell_outlined),
                  label: const Text('Price memory'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NetWorthScreen())),
                  icon: const Icon(Icons.show_chart),
                  label: const Text('Net worth'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final MonthReport report;
  final VoidCallback onSaved;
  const _ReportBody({required this.report, required this.onSaved});

  @override
  Widget build(BuildContext context) {
    final r = report;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r.month} · ${r.txnCount} entries', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('Open ₹${r.totalOpen.toStringAsFixed(0)} → expected ₹${r.totalExpected.toStringAsFixed(0)}'),
                Text('True spent (budget) ₹${r.outBudget.toStringAsFixed(0)}'),
                if (r.countedCount > 0)
                  Text(
                    'Counted ₹${r.totalCounted.toStringAsFixed(0)} · gap ${r.totalGap >= 0 ? '+' : ''}₹${r.totalGap.toStringAsFixed(0)} '
                    '(${r.totalGap.abs() <= 0.005 ? 'balanced' : r.totalGap > 0 ? 'short — untracked outflow' : 'excess — untracked inflow'})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: r.totalGap.abs() <= 0.005 ? Colors.green : Colors.red,
                    ),
                  )
                else
                  const Text('No closes counted yet — count each wallet physically, then enter below.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (r.rows.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('No accounts yet — add one from Transactions → Accounts.')))
        else
          for (final row in r.rows) _AccountReconCard(row: row, month: r.month, onSaved: onSaved),
      ],
    );
  }
}

class _AccountReconCard extends ConsumerWidget {
  final AccountRecon row;
  final String month;
  final VoidCallback onSaved;
  const _AccountReconCard({required this.row, required this.month, required this.onSaved});

  Future<void> _edit(BuildContext context, WidgetRef ref, {required bool isOpen}) async {
    final ctrl = TextEditingController(
      text: (isOpen ? row.open : (row.counted ?? row.expected)).toStringAsFixed(0),
    );
    String? error;
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('${isOpen ? 'Opening' : 'Counted close'} — ${row.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isOpen)
                const Text('Count the cash physically. Same formula as bank: open + in − out.'),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount ₹', border: OutlineInputBorder()),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final v = double.tryParse(ctrl.text.trim());
                if (v == null || v < 0) {
                  setDialog(() => error = 'Enter a valid non-negative amount');
                  return;
                }
                try {
                  final repo = ref.read(reconcileRepositoryProvider);
                  if (isOpen) {
                    await repo.setOpen(month: month, accountId: row.accountId, value: v);
                  } else {
                    await repo.setClose(month: month, accountId: row.accountId, value: v);
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                } on Object catch (e) {
                  setDialog(() => error = e.toString().replaceFirst('Invalid argument(s): ', ''));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (done ?? false) onSaved();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCash = row.kind.toLowerCase().contains('cash');
    final gapColor = row.gap == null
        ? null
        : (row.gap!.abs() <= 0.005 ? Colors.green : Colors.red);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('${row.name} · ${row.kind}', style: Theme.of(context).textTheme.titleSmall)),
                if (row.status != null)
                  Chip(
                    label: Text(row.status!),
                    backgroundColor: gapColor?.withValues(alpha: 0.15),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Open ₹${row.open.toStringAsFixed(0)} · in ₹${row.inActual.toStringAsFixed(0)} · out ₹${row.outActual.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Expected ₹${row.expected.toStringAsFixed(0)}'
              '${row.counted != null ? ' · counted ₹${row.counted!.toStringAsFixed(0)} · gap ${row.gap! >= 0 ? '+' : ''}₹${row.gap!.toStringAsFixed(0)}' : ' · not counted'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: row.counted != null ? FontWeight.bold : null,
                    color: gapColor,
                  ),
            ),
            if (isCash)
              Text('Cash: count physically, then enter.', style: Theme.of(context).textTheme.bodySmall),
            if (row.accountId.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => _edit(context, ref, isOpen: true), child: const Text('Set open')),
                  TextButton(onPressed: () => _edit(context, ref, isOpen: false), child: const Text('Count close')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
