import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../data/body_repository.dart';
import '../data/database.dart';
import '../workout/stats.dart';
import 'workout/workout_summary_screen.dart' show formatDate;
import 'theme/charts.dart';

/// The 5 most common measurements, shown as boxes (others: "More" / Log).
const popularMeasurements = [
  ('weight', 'Weight'),
  ('bodyFat', 'Body fat'),
  ('waist', 'Waist'),
  ('chest', 'Chest'),
  ('bicepR', 'Arm'),
];

/// Body measurements as small boxes: latest value + change since last time.
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
        final others = [
          for (final k in measurementKinds)
            if (grouped.containsKey(k.key) && !popularMeasurements.any((p) => p.$1 == k.key)) k,
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
            LayoutBuilder(
              builder: (context, c) {
                final w = (c.maxWidth - 16) / 3;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (key, label) in popularMeasurements)
                      SizedBox(
                        width: w,
                        child: _MeasureBox(kind: kindOf(key), label: label, entries: grouped[key] ?? const []),
                      ),
                    SizedBox(
                      width: w,
                      child: _Box(
                        key: const Key('moreMeasurements'),
                        label: 'More',
                        value: others.isEmpty ? '+' : '${others.length}',
                        sub: others.isEmpty ? 'neck, hips, legs…' : 'more logged',
                        onTap: () => _showAll(context, grouped),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  static void _showAll(BuildContext context, Map<String, List<BodyMeasurement>> grouped) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.75),
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All measurements'),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(c);
                    logMeasurements(context);
                  },
                  child: const Text('Log'),
                ),
              ),
              for (final k in measurementKinds)
                ListTile(
                  title: Text(k.label),
                  trailing: Text(grouped[k.key] == null ? '—' : '${formatKg(grouped[k.key]!.first.value)} ${k.unit}'),
                  onTap: () {
                    Navigator.pop(c);
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MeasurementHistoryScreen(kind: k)));
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeasureBox extends StatelessWidget {
  const _MeasureBox({required this.kind, required this.label, required this.entries});

  final MeasurementKind kind;
  final String label;
  final List<BodyMeasurement> entries; // newest first

  @override
  Widget build(BuildContext context) {
    final latest = entries.firstOrNull;
    final prev = entries.length > 1 ? entries[1] : null;
    final diff = latest == null || prev == null ? null : latest.value - prev.value;
    final good = diff == null || diff == 0 ? null : (diff < 0) == kind.lowerIsBetter;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final goodColor = dark ? Colors.greenAccent : Colors.green.shade700;
    final badColor = dark ? Colors.orangeAccent : Colors.deepOrange.shade700;
    return _Box(
      label: label,
      value: latest == null ? '—' : '${formatKg(latest.value)}${kind.unit == '%' ? '%' : ''}',
      unit: kind.unit == '%' ? null : kind.unit,
      sub: diff == null || diff == 0
          ? (latest == null ? 'tap to add' : 'no change')
          : '${diff > 0 ? '▲' : '▼'} ${formatKg(diff.abs())}',
      subColor: good == null ? null : (good ? goodColor : badColor),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MeasurementHistoryScreen(kind: kind))),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({super.key, required this.label, required this.value, this.unit, this.sub, this.subColor, this.onTap});

  final String label;
  final String value;
  final String? unit;
  final String? sub;
  final Color? subColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  text: value,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  children: [if (unit != null && value != '—') TextSpan(text: ' $unit', style: text.labelSmall)],
                ),
                maxLines: 1,
              ),
              Text(
                sub ?? '',
                style: text.labelSmall?.copyWith(color: subColor ?? scheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
                      gridData: SoftChart.grid(context),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(),
                        rightTitles: AxisTitles(),
                        bottomTitles: AxisTitles(),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                      ),
                      lineBarsData: [
                        SoftChart.line(context, [for (final (i, m) in points.indexed) FlSpot(i.toDouble(), m.value)]),
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
