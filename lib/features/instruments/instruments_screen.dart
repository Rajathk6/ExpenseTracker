/// Instruments vault home: open holdings with manual P/L%, archived history,
/// add/edit/revalue flows, and a simple-interest preview calculator.
/// Tracking-only — nothing here writes ledger transactions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../core/providers.dart';
import 'instrument_logic.dart';
import 'instrument_repository.dart';

class InstrumentsScreen extends ConsumerWidget {
  const InstrumentsScreen({super.key});

  void _refresh(WidgetRef ref) {
    ref
      ..invalidate(openInstrumentsProvider)
      ..invalidate(allInstrumentsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openInstrumentsProvider);
    final all = ref.watch(allInstrumentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Instruments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final done = await showDialog<bool>(
            context: context,
            builder: (_) => const _InstrumentDialog(),
          );
          if (done ?? false) _refresh(ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          open.when(
            data: (list) => _TotalsCard(
              holdings: [for (final i in list) (invested: i.invested, current: i.current)],
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Totals unavailable: $e'),
          ),
          const SizedBox(height: 8),
          const _InterestPreview(),
          const SizedBox(height: 8),
          Text('Open', style: Theme.of(context).textTheme.titleSmall),
          open.when(
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Nothing tracked — tap Add for your first stock / FD / loan / note.'),
                );
              }
              return Column(children: [for (final i in list) _InstrumentCard(item: i, onChanged: () => _refresh(ref))]);
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Could not load: $e'),
          ),
          const SizedBox(height: 8),
          Text('Archived', style: Theme.of(context).textTheme.titleSmall),
          all.when(
            data: (list) {
              final done = list.where((i) => i.status != 'open').toList();
              if (done.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text('No archived entries.'));
              return Column(
                children: [
                  for (final i in done)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.archive_outlined),
                      title: Text(i.name),
                      subtitle: Text('${i.kind} · invested ₹${i.invested.toStringAsFixed(0)}'),
                      trailing: TextButton(
                        onPressed: () async {
                          await ref.read(instrumentRepositoryProvider).unarchive(i.id);
                          _refresh(ref);
                        },
                        child: const Text('Restore'),
                      ),
                    ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Could not load: $e'),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final List<({double invested, double current})> holdings;
  const _TotalsCard({required this.holdings});

  @override
  Widget build(BuildContext context) {
    final t = portfolioTotals(holdings);
    final gain = t.pnl >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat('Invested', '₹${t.invested.toStringAsFixed(0)}'),
            _Stat('Current', '₹${t.current.toStringAsFixed(0)}'),
            _Stat(
              'P/L ${gain ? '+' : ''}${t.pnlPct.toStringAsFixed(1)}%',
              '${gain ? '+' : ''}₹${t.pnl.toStringAsFixed(0)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Offline interest preview: principal × rate × years. Writes nothing.
class _InterestPreview extends StatefulWidget {
  const _InterestPreview();

  @override
  State<_InterestPreview> createState() => _InterestPreviewState();
}

class _InterestPreviewState extends State<_InterestPreview> {
  final _p = TextEditingController(text: '10000');
  final _r = TextEditingController(text: '7');
  final _t = TextEditingController(text: '1');

  @override
  void dispose() {
    _p.dispose();
    _r.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = double.tryParse(_p.text.trim()) ?? 0;
    final r = double.tryParse(_r.text.trim()) ?? 0;
    final t = double.tryParse(_t.text.trim()) ?? 0;
    final si = simpleInterest(principal: p, annualRatePct: r, years: t);
    final mat = maturitySimple(principal: p, annualRatePct: r, years: t);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Interest preview (simple)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _p, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Principal ₹', border: OutlineInputBorder()), onChanged: (_) => setState(() {}))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _r, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rate %/yr', border: OutlineInputBorder()), onChanged: (_) => setState(() {}))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _t, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Years', border: OutlineInputBorder()), onChanged: (_) => setState(() {}))),
              ],
            ),
            const SizedBox(height: 8),
            Text('Interest ₹${si.toStringAsFixed(0)} · Maturity ₹${mat.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _InstrumentCard extends ConsumerWidget {
  final Instrument item;
  final VoidCallback onChanged;
  const _InstrumentCard({required this.item, required this.onChanged});

  Future<void> _revalue(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: item.current.toStringAsFixed(0));
    String? error;
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('Revalue ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Current value ₹', border: OutlineInputBorder())),
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
                  setDialog(() => error = 'Enter a valid non-negative value');
                  return;
                }
                try {
                  await ref.read(instrumentRepositoryProvider).revalue(item.id, v);
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
    if (done ?? false) onChanged();
  }

  Future<void> _confirmArchive(BuildContext context, WidgetRef ref) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Archive ${item.name}?'),
        content: const Text('Totals will exclude it. History stays under Archived.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep')),
          FilledButton.tonal(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Archive')),
        ],
      ),
    );
    if (yes ?? false) {
      await ref.read(instrumentRepositoryProvider).archive(item.id);
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = instrumentPnlPct(invested: item.invested, current: item.current);
    final gain = item.current >= item.invested;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.name, style: Theme.of(context).textTheme.titleSmall),
                ),
                Text(
                  '${gain ? '+' : ''}${pct.toStringAsFixed(1)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: gain ? Colors.green : Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${item.kind} · ₹${item.invested.toStringAsFixed(0)} → ₹${item.current.toStringAsFixed(0)}'
              '${item.note != null && item.note!.isNotEmpty ? '\n${item.note}' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                TextButton.icon(
                  onPressed: () => _revalue(context, ref),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Revalue'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final done = await showDialog<bool>(
                      context: context,
                      builder: (_) => _InstrumentDialog(existing: item),
                    );
                    if (done ?? false) onChanged();
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmArchive(context, ref),
                  icon: const Icon(Icons.archive_outlined, size: 18),
                  label: const Text('Archive'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InstrumentDialog extends ConsumerStatefulWidget {
  final Instrument? existing;
  const _InstrumentDialog({this.existing});

  @override
  ConsumerState<_InstrumentDialog> createState() => _InstrumentDialogState();
}

class _InstrumentDialogState extends ConsumerState<_InstrumentDialog> {
  late final TextEditingController _name;
  late final TextEditingController _kind;
  late final TextEditingController _invested;
  late final TextEditingController _current;
  late final TextEditingController _note;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _kind = TextEditingController(text: e?.kind ?? 'stock');
    _invested = TextEditingController(text: e == null ? '' : e.invested.toStringAsFixed(0));
    _current = TextEditingController(text: e == null ? '' : e.current.toStringAsFixed(0));
    _note = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _kind.dispose();
    _invested.dispose();
    _current.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final invested = double.tryParse(_invested.text.trim()) ?? -1;
    final current = double.tryParse(_current.text.trim()) ?? -1;
    final err = validateInstrument(name: _name.text, invested: invested, current: current);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final repo = ref.read(instrumentRepositoryProvider);
      if (widget.existing == null) {
        await repo.create(name: _name.text, kind: _kind.text, invested: invested, current: current, note: _note.text);
      } else {
        await repo.edit(
          id: widget.existing!.id,
          name: _name.text,
          kind: _kind.text,
          invested: invested,
          current: current,
          note: _note.text,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Invalid argument(s): ', '').replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add instrument' : 'Edit ${widget.existing!.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _name, autofocus: true, decoration: const InputDecoration(labelText: 'Name (e.g. RELIANCE, HDFC-FD, Paper NIFTY)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _kind, decoration: const InputDecoration(labelText: 'Kind (freeform)', helperText: 'stock · mutual · fd · loan · card · paper · plan · note', border: OutlineInputBorder())),
            Wrap(
              spacing: 6,
              children: [
                for (final k in suggestedInstrumentKinds)
                  ActionChip(label: Text(k), onPressed: () => setState(() => _kind.text = k)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _invested, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Invested ₹', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _current, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Current ₹', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 8),
            TextField(controller: _note, decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder())),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save')),
      ],
    );
  }
}
