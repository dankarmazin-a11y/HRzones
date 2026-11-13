import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/workout_repository.dart';
import '../../workout/stats.dart';
import '../theme/charts.dart';
import '../../units/units.dart';

/// Records, a progress chart and the history of one exercise.
class ExerciseProgressSection extends StatelessWidget {
  const ExerciseProgressSection({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExerciseSession>>(
      future: Services.of(context).workouts.exerciseHistory(exercise.id),
      builder: (context, snap) {
        final sessions = snap.data;
        if (sessions == null) return const SizedBox.shrink();
        final text = Theme.of(context).textTheme;
        if (sessions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No history yet – your progress shows up here after a workout.', style: text.bodySmall),
          );
        }
        final metric = metricFor(exercise.trackingType);
        final allSets = [for (final s in sessions) ...s.sets.map(SetStat.fromRow)];
        final bests = ExerciseBests.fromSets(allSets)[exercise.id]?.values ?? const {};
        // Oldest → newest for the chart.
        final points = <(DateTime, double)>[
          for (final s in sessions.reversed)
            if (sessionValue(metric, s.sets.map(SetStat.fromRow)) case final v?)
              (s.workout.startedAt, metric == ProgressMetric.est1RM ? Units.toW(v) : v), // kg or lb
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            if (bests.isNotEmpty) ...[
              Text('Personal records', style: text.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final MapEntry(:key, :value) in bests.entries)
                    Chip(
                      avatar: const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                      label: Text('${key.label}: ${formatRecord(key, value)}'),
                    ),
                ],
              ),
            ],
            if (points.length >= 2) ...[
              const SizedBox(height: 16),
              Text(metric.label, style: text.titleMedium),
              const SizedBox(height: 8),
              SizedBox(height: 180, child: _ProgressChart(points: points)),
            ],
            const SizedBox(height: 16),
            Text('History', style: text.titleMedium),
            for (final s in sessions.take(20))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(_date(s.workout.startedAt)),
                subtitle: Text(
                  [
                    s.sets.map((x) => _setText(exercise.trackingType, x)).join('   '),
                    if (s.notes.isNotEmpty) '📝 ${s.notes}',
                  ].join('\n'),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _date(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  static String _setText(TrackingType t, WorkoutSet s) {
    final w = s.weightKg;
    if (t == TrackingType.duration) {
      return (w ?? 0) > 0 ? '${s.durationS ?? 0}s +${formatWeight(w)}' : '${s.durationS ?? 0}s';
    }
    return (w ?? 0) > 0 ? '${formatW(w)}×${s.reps ?? 0}' : '${s.reps ?? 0} reps';
  }
}

class _ProgressChart extends StatelessWidget {
  const _ProgressChart({required this.points});

  final List<(DateTime, double)> points;

  @override
  Widget build(BuildContext context) {
    final ys = points.map((p) => p.$2);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.15).clamp(1, double.infinity);
    return LineChart(
      LineChartData(
        minY: (minY - pad).floorToDouble().clamp(0, double.infinity),
        maxY: (maxY + pad).ceilToDouble(),
        gridData: SoftChart.grid(context),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, m) => v == m.min || v == m.max
                  ? const SizedBox.shrink()
                  : Text(m.formattedValue, style: SoftChart.axis(context)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (points.length / 4).ceilToDouble().clamp(1, double.infinity),
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i < 0 || i >= points.length || v != i) return const SizedBox.shrink();
                final d = points[i].$1;
                return SideTitleWidget(
                  meta: meta,
                  child: Text('${d.day}/${d.month}', style: SoftChart.axis(context)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          SoftChart.line(context, [
            for (final (i, p) in points.indexed) FlSpot(i.toDouble(), double.parse(p.$2.toStringAsFixed(1))),
          ]),
        ],
      ),
    );
  }
}
