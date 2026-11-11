import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/exercise_repository.dart';
import '../../data/workout_repository.dart';
import '../../run/geo.dart';
import '../../workout/stats.dart';
import '../../workout/training_stats.dart';
import '../body_map.dart';
import '../exercises/exercise_detail_screen.dart';

/// The periods the stats can show.
enum StatsPeriod {
  week(7, '7 days'),
  month(30, '30 days'),
  quarter(90, '90 days');

  const StatsPeriod(this.days, this.label);
  final int days;
  final String label;
}

/// Phase 3 – your training at a glance: totals for a period, time per week
/// (strength + running), which muscles got the work (heat map) and the
/// exercises you did most.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatsPeriod _period = StatsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: StreamBuilder<List<WorkoutListItem>>(
        stream: s.workouts.watchFinished(),
        builder: (context, snap) => StreamBuilder<List<Run>>(
          stream: s.runs.watchFinished(),
          builder: (context, runSnap) {
            final workouts = snap.data, runs = runSnap.data;
            if (workouts == null || runs == null) return const Center(child: CircularProgressIndicator());
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final from = DateTime(today.year, today.month, today.day - (_period.days - 1));
            final totals = periodTotals(workouts: workouts, runs: runs, from: from);
            return ListView(
              key: const Key('statsList'),
              scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: SegmentedButton<StatsPeriod>(
                    key: const Key('statsPeriod'),
                    segments: [
                      for (final p in StatsPeriod.values)
                        ButtonSegment(value: p, label: Text(p.label), tooltip: 'Last ${p.label}'),
                    ],
                    selected: {_period},
                    showSelectedIcon: false,
                    onSelectionChanged: (v) => setState(() => _period = v.first),
                  ),
                ),
                const SizedBox(height: 12),
                _TotalsCard(totals: totals, days: _period.days),
                _WeeksCard(
                  weeks: weeklySummaries(workouts: workouts, runs: runs, now: now),
                ),
                // Rebuilt (and re-read) when the period or the workouts change.
                _MuscleSection(
                  key: ValueKey((_period, workouts.length, workouts.firstOrNull?.workout.id)),
                  from: from,
                  days: _period.days,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.titleMedium),
            if (subtitle != null) Text(subtitle!, style: text.bodySmall),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals, required this.days});

  final PeriodTotals totals;
  final int days;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = totals;
    final perWeek = t.workouts * 7 / days;
    String hours(int min) => min < 60 ? '$min min' : '${min ~/ 60} h ${(min % 60).toString().padLeft(2, '0')}';
    Widget tile(String key, String value, String label) => Expanded(
      child: Column(
        key: Key(key),
        children: [
          FittedBox(
            child: Text(value, style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Text(label, style: text.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
    return _Card(
      key: const Key('statsTotals'),
      title: 'Totals',
      subtitle: days == 7
          ? '${t.strength} strength · ${t.runs} runs'
          : '${t.strength} strength · ${t.runs} runs · ${perWeek.toStringAsFixed(1)} workouts a week',
      child: Column(
        children: [
          Row(
            children: [
              tile('totalWorkouts', '${t.workouts}', 'workouts'),
              tile('totalTime', hours(t.minutes), 'training time'),
              tile('totalKm', formatKm(t.metres), 'km run'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              tile('totalSets', '${t.sets}', 'sets'),
              tile(
                'totalVolume',
                t.volume >= 10000 ? '${(t.volume / 1000).toStringAsFixed(1)} t' : formatKg(t.volume),
                t.volume >= 10000 ? 'lifted' : 'kg lifted',
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}

/// Minutes per week for the last 12 weeks: strength and running stacked.
class _WeeksCard extends StatelessWidget {
  const _WeeksCard({required this.weeks});

  final List<WeekSummary> weeks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final strengthColor = scheme.primary, runColor = Colors.orange;
    final maxMin = weeks.fold(0, (m, w) => w.minutes > m ? w.minutes : m);
    final avg = weeks.take(weeks.length - 1).fold(0, (s, w) => s + w.minutes) / (weeks.length - 1);
    Widget legend(Color c, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: text.labelSmall),
      ],
    );
    return _Card(
      key: const Key('statsWeeks'),
      title: 'Training time per week',
      subtitle: 'Last 12 weeks · average ${avg.round()} min a week',
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                maxY: maxMin <= 0 ? 60 : (maxMin * 1.15).ceilToDouble(),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (g, _, rod, _) {
                      final w = weeks[g.x];
                      return BarTooltipItem(
                        '${w.minutes} min\n${w.strength} strength · ${w.runs} runs',
                        const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, m) => v == m.max
                          ? const SizedBox.shrink()
                          : Text(v.round().toString(), style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        if (i % 2 == 1 || i >= weeks.length) return const SizedBox.shrink();
                        final d = weeks[i].start;
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
                          toY: w.minutes.toDouble(),
                          width: 14,
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.transparent,
                          rodStackItems: [
                            BarChartRodStackItem(0, w.strengthMinutes.toDouble(), strengthColor),
                            BarChartRodStackItem(w.strengthMinutes.toDouble(), w.minutes.toDouble(), runColor),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [legend(strengthColor, 'Strength'), const SizedBox(width: 16), legend(runColor, 'Running')],
          ),
        ],
      ),
    );
  }
}

/// Heat map + sets per muscle + most-done exercises for the period.
class _MuscleSection extends StatefulWidget {
  const _MuscleSection({super.key, required this.from, required this.days});

  final DateTime from;
  final int days;

  @override
  State<_MuscleSection> createState() => _MuscleSectionState();
}

class _MuscleSectionState extends State<_MuscleSection> {
  late final Future<(List<SetStat>, Map<String, Exercise>)> _data = () async {
    final s = Services.of(context);
    final sets = await s.workouts.setsSince(widget.from);
    final all = await s.exercises.all();
    return (sets, {for (final e in all) e.id: e});
  }();
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder(
      future: _data,
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        final (sets, byId) = data;
        final perMuscle = setsPerMuscle(sets, (id) => byId[id]);
        final heat = muscleHeat(perMuscle, days: widget.days);
        final ranked = perMuscle.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final shown = {
          for (final r in [...frontRegions, ...backRegions]) r.muscle,
        };
        final untrained = [
          for (final m in shown)
            if ((perMuscle[m] ?? 0) == 0) m,
        ]..sort();
        final top = topExercises(sets, (id) => byId[id]);
        final maxSets = ranked.isEmpty ? 1.0 : ranked.first.value;
        String setsText(double v) => '${v == v.roundToDouble() ? v.round() : v.toStringAsFixed(1)} sets';
        final sel = _selected;
        return Column(
          children: [
            _Card(
              key: const Key('muscleHeat'),
              title: 'Muscles worked',
              subtitle:
                  'Darker = more sets (about 10 sets a week is a full week of work). A main muscle counts a '
                  'whole set, a helping muscle half.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 260,
                    child: BodyMap(
                      heat: heat,
                      selected: {?sel},
                      onTap: (m) => setState(() => _selected = _selected == m ? null : m),
                    ),
                  ),
                  if (sel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${titleCase(sel)}: ${setsText(perMuscle[sel] ?? 0)}',
                        key: const Key('selectedMuscle'),
                        textAlign: TextAlign.center,
                        style: text.titleMedium,
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (ranked.isEmpty)
                    const Text('No strength sets in this period yet.')
                  else
                    for (final MapEntry(key: m, value: v) in ranked.take(8))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(width: 110, child: Text(titleCase(m), style: text.bodyMedium)),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: v / maxSets,
                                  minHeight: 10,
                                  backgroundColor: scheme.surfaceContainerHighest,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 64,
                              child: Text(setsText(v), textAlign: TextAlign.end, style: text.bodySmall),
                            ),
                          ],
                        ),
                      ),
                  if (ranked.isNotEmpty && untrained.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Not trained in this period', style: text.labelLarge),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final m in untrained)
                          Chip(label: Text(titleCase(m)), visualDensity: VisualDensity.compact),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (top.isNotEmpty)
              _Card(
                key: const Key('topExercises'),
                title: 'Most done exercises',
                child: Column(
                  children: [
                    for (final (id, n) in top)
                      if (byId[id] case final e?)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(e.name),
                          subtitle: Text(titleCase(e.primaryMuscle)),
                          trailing: Text('$n sets', style: text.titleSmall),
                          onTap: () =>
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: e))),
                        ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
