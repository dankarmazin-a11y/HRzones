import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../app_services.dart';
import '../../data/database.dart';
import '../../run/geo.dart';
import '../../workout/streak.dart';

/// Running charts: km per week, pace over time and aerobic fitness (metres
/// per heartbeat).
class RunProgressScreen extends StatelessWidget {
  const RunProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Running progress')),
      body: StreamBuilder<List<Run>>(
        stream: s.runs.watchFinished(),
        builder: (context, snap) {
          final runs = snap.data;
          if (runs == null) return const Center(child: CircularProgressIndicator());
          if (runs.isEmpty) return const Center(child: Text('Run a few times to see your progress here.'));
          return ListView(
            // Keep cards that load data built off-screen (no jumping while scrolling).
            scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
            padding: const EdgeInsets.all(16),
            children: [
              _ChartCard(
                key: const Key('weeklyKmChart'),
                title: 'Km per week',
                subtitle: 'Last 12 weeks',
                child: _WeeklyKm(runs: runs),
              ),
              _ChartCard(
                key: const Key('paceChart'),
                title: 'Average pace',
                subtitle: 'Each outdoor run of 1 km or more – lower is faster',
                child: _RunLine(
                  runs: runs.where((r) => r.kind == RunKind.outdoor && r.distanceM >= 1000).toList(),
                  value: (r) => paceSecPerKm(r.distanceM, r.durationS.toDouble()),
                  label: (v) => formatPace(v),
                ),
              ),
              _ChartCard(
                key: const Key('efficiencyChart'),
                title: 'Metres per heartbeat',
                subtitle:
                    'How far you get for each heartbeat (pace ÷ heart rate). Rising over the weeks means your aerobic '
                    'fitness is improving. Needs runs with heart rate.',
                child: _RunLine(
                  runs: runs.where((r) => r.avgHr != null && r.durationS > 0 && r.distanceM >= 1000).toList(),
                  value: (r) => r.distanceM / (r.durationS / 60) / r.avgHr!,
                  label: (v) => v.toStringAsFixed(2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({super.key, required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.titleMedium),
            Text(subtitle, style: text.bodySmall),
            const SizedBox(height: 12),
            SizedBox(height: 180, child: child),
          ],
        ),
      ),
    );
  }
}

class _WeeklyKm extends StatelessWidget {
  const _WeeklyKm({required this.runs});

  final List<Run> runs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thisWeek = weekStart(DateTime.now());
    final weeks = [for (var i = 11; i >= 0; i--) DateTime(thisWeek.year, thisWeek.month, thisWeek.day - 7 * i)];
    final km = {for (final w in weeks) w: 0.0};
    for (final r in runs) {
      final w = weekStart(r.startedAt);
      if (km.containsKey(w)) km[w] = km[w]! + r.distanceM / 1000;
    }
    final maxKm = km.values.fold(0.0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maxKm <= 0 ? 10 : (maxKm * 1.2).ceilToDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, _, rod, _) => BarTooltipItem('${rod.toY.toStringAsFixed(1)} km', const TextStyle()),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, m) => Text(v.round().toString(), style: const TextStyle(fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (v, m) {
                final i = v.toInt();
                if (i % 2 == 1 || i >= weeks.length) return const SizedBox.shrink();
                final d = weeks[i];
                return Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        barGroups: [
          for (final (i, w) in weeks.indexed)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: double.parse(km[w]!.toStringAsFixed(1)),
                  color: i == weeks.length - 1 ? scheme.primary : scheme.primary.withValues(alpha: 0.55),
                  width: 14,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One value per run, oldest → newest (the last 30).
class _RunLine extends StatelessWidget {
  const _RunLine({required this.runs, required this.value, required this.label});

  final List<Run> runs;
  final double? Function(Run) value;
  final String Function(double) label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = [
      for (final r in runs.reversed)
        if (value(r) case final v?) (r, v),
    ];
    final last = list.length > 30 ? list.sublist(list.length - 30) : list;
    if (last.length < 2) {
      return const Center(child: Text('Needs at least two runs.', textAlign: TextAlign.center));
    }
    final ys = last.map((x) => x.$2);
    final lo = ys.reduce((a, b) => a < b ? a : b), hi = ys.reduce((a, b) => a > b ? a : b);
    final pad = (hi - lo) * 0.15 + (hi == lo ? 1 : 0);
    return LineChart(
      LineChartData(
        minY: lo - pad,
        maxY: hi + pad,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${label(s.y)}\n${last[s.x.toInt()].$1.startedAt.day}/${last[s.x.toInt()].$1.startedAt.month}',
                  const TextStyle(),
                ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, m) => v == m.min || v == m.max
                  ? const SizedBox.shrink()
                  : Text(label(v), style: const TextStyle(fontSize: 10)),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (final (i, x) in last.indexed) FlSpot(i.toDouble(), x.$2)],
            color: scheme.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
