import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../data/body_repository.dart';
import '../data/database.dart';
import '../workout/stats.dart';
import 'workout/workout_summary_screen.dart' show formatDate;

/// Latest body measurements with the change since the previous one.
class MeasurementsSection extends StatelessWidget {
  const MeasurementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    return StreamBuilder<List<BodyMeasurement>>(
      stream: s.body.watchAll(),
      builder: (context, snap) {
        final grouped = byKind(snap.data ?? const []);
        final kinds = [
          for (final k in measurementKinds)
            if (grouped.containsKey(k.key)) k,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Body measurements', style: text.titleMedium)),
                TextButton.icon(
                  key: const Key('logMeasurements'),
                  icon: const Icon(Icons.add),
                  label: const Text('Log'),
                  onPressed: () => logMeasurements(context),
                ),
              ],
            ),
            if (kinds.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.straighten),
                  title: const Text('No measurements yet'),
                  subtitle: const Text('Weight, body fat, waist, arms, legs… tap to log'),
                  onTap: () => logMeasurements(context),
                ),
              ),
            for (final k in kinds) _MeasurementTile(kind: k, entries: grouped[k.key]!),
          ],
        );
      },
    );
  }
}

class _MeasurementTile extends StatelessWidget {
  const _MeasurementTile({required this.kind, required this.entries});

  final MeasurementKind kind;
  final List<BodyMeasurement> entries; // newest first

  @override
  Widget build(BuildContext context) {
    final latest = entries.first;
    final prev = entries.length > 1 ? entries[1] : null;
    final diff = prev == null ? null : latest.value - prev.value;
    final good = diff == null || diff == 0 ? null : (diff < 0) == kind.lowerIsBetter;
    return Card(
      child: ListTile(
        title: Text(kind.label),
        subtitle: Text(formatDate(latest.date).split(',').first),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (diff != null && diff != 0)
              Text(
                '${diff > 0 ? '▲' : '▼'} ${formatKg(diff.abs())}',
                style: TextStyle(color: good == true ? Colors.greenAccent : Colors.orangeAccent, fontSize: 12),
              ),
            const SizedBox(width: 8),
            Text('${formatKg(latest.value)} ${kind.unit}', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => MeasurementHistoryScreen(kind: kind))),
      ),
    );
  }
}

/// Sheet with a field per measurement; fills in only what you measured.
Future<void> logMeasurements(BuildContext context) async {
  final body = Services.of(context).body;
  final controllers = {for (final k in measurementKinds) k.key: TextEditingController()};
  final latest = <String, double?>{for (final k in measurementKinds) k.key: await body.latest(k.key)};
  if (!context.mounted) return;
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (c) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Log measurements'),
                subtitle: const Text('Fill in only what you measured today'),
                trailing: FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final k in measurementKinds)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          key: Key('measure-${k.key}'),
                          controller: controllers[k.key],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          decoration: InputDecoration(
                            labelText: k.label,
                            suffixText: k.unit,
                            hintText: latest[k.key] == null ? null : 'last: ${formatKg(latest[k.key])}',
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (saved == true) {
    final now = DateTime.now();
    for (final MapEntry(:key, :value) in controllers.entries) {
      final v = double.tryParse(value.text.replaceAll(',', '.'));
      if (v != null) await body.add(key, v, date: now);
    }
  }
  for (final c in controllers.values) {
    c.dispose();
  }
}

/// Chart + list of one measurement; swipe an entry to delete it.
class MeasurementHistoryScreen extends StatefulWidget {
  const MeasurementHistoryScreen({super.key, required this.kind});

  final MeasurementKind kind;

  @override
  State<MeasurementHistoryScreen> createState() => _MeasurementHistoryScreenState();
}

class _MeasurementHistoryScreenState extends State<MeasurementHistoryScreen> {
  late Future<List<BodyMeasurement>> _entries;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _entries = Services.of(context).body.history(widget.kind.key);
  }

  void _reload() => setState(() => _entries = Services.of(context).body.history(widget.kind.key));

  @override
  Widget build(BuildContext context) {
    final k = widget.kind;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(k.label)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final c = TextEditingController();
          final v = await showDialog<double>(
            context: context,
            builder: (d) => AlertDialog(
              title: Text('${k.label} today'),
              content: TextField(
                controller: c,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(suffixText: k.unit),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(d, double.tryParse(c.text.replaceAll(',', '.'))),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          if (v != null && context.mounted) {
            await Services.of(context).body.add(k.key, v);
            _reload();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<BodyMeasurement>>(
        future: _entries,
        builder: (context, snap) {
          final list = snap.data ?? const [];
          final points = list.reversed.toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (points.length >= 2)
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(),
                        rightTitles: AxisTitles(),
                        bottomTitles: AxisTitles(),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [for (final (i, m) in points.indexed) FlSpot(i.toDouble(), m.value)],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: scheme.primary,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: true, color: scheme.primary.withValues(alpha: 0.15)),
                        ),
                      ],
                    ),
                  ),
                ),
              for (final m in list)
                Dismissible(
                  key: ValueKey(m.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete),
                  ),
                  onDismissed: (_) async {
                    await Services.of(context).body.delete(m.id);
                    _reload();
                  },
                  child: ListTile(title: Text('${formatKg(m.value)} ${k.unit}'), subtitle: Text(formatDate(m.date))),
                ),
            ],
          );
        },
      ),
    );
  }
}
