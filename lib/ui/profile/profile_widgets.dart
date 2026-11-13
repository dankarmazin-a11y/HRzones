import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/workout_repository.dart';
import '../../workout/stats.dart';
import '../../workout/streak.dart';
import '../theme/app_theme.dart';
import '../../units/units.dart';

/// Strength workouts and runs together, for the Profile cards.
class TrainingData {
  const TrainingData(this.workouts, this.runs);

  final List<WorkoutListItem> workouts;
  final List<Run> runs;

  int get count => workouts.length + runs.length;
  double get metres => runs.fold(0.0, (v, r) => v + r.distanceM);
  double get volume => workouts.fold(0.0, (v, w) => v + w.volume);
  int get minutes =>
      workouts.fold(
        0,
        (v, w) => v + (w.workout.endedAt ?? w.workout.startedAt).difference(w.workout.startedAt).inMinutes,
      ) +
      runs.fold(0, (v, r) => v + r.durationS ~/ 60);

  DateTime? get first {
    final all = [...workouts.map((w) => w.workout.startedAt), ...runs.map((r) => r.startedAt)];
    if (all.isEmpty) return null;
    return all.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// 0 nothing, 1 strength, 2 run, 3 both – per day of [month].
  Map<int, int> daysIn(DateTime month) {
    final out = <int, int>{};
    for (final w in workouts) {
      final d = w.workout.startedAt;
      if (d.year == month.year && d.month == month.month) out[d.day] = (out[d.day] ?? 0) | 1;
    }
    for (final r in runs) {
      final d = r.startedAt;
      if (d.year == month.year && d.month == month.month) out[d.day] = (out[d.day] ?? 0) | 2;
    }
    return out;
  }

  TrainingData within(DateTime from, DateTime to) => TrainingData(
    workouts.where((w) => !w.workout.startedAt.isBefore(from) && w.workout.startedAt.isBefore(to)).toList(),
    runs.where((r) => !r.startedAt.isBefore(from) && r.startedAt.isBefore(to)).toList(),
  );
}

/// Rebuilds with all finished workouts and runs.
class TrainingDataBuilder extends StatelessWidget {
  const TrainingDataBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, TrainingData data) builder;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return StreamBuilder<List<WorkoutListItem>>(
      stream: s.workouts.watchFinished(),
      builder: (context, w) => StreamBuilder<List<Run>>(
        stream: s.runs.watchFinished(),
        builder: (context, r) => builder(context, TrainingData(w.data ?? const [], r.data ?? const [])),
      ),
    );
  }
}

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String monthName(DateTime d) => _months[d.month - 1];

/// A number with a small label under it (Profile cards).
class NumberTile extends StatelessWidget {
  const NumberTile(this.value, this.label, {super.key, this.divider = true});

  final String value;
  final String label;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: EdgeInsets.only(left: divider ? 10 : 0),
        decoration: divider
            ? BoxDecoration(
                border: Border(left: BorderSide(color: t.track)),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              child: Text(
                value,
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Text(label, style: text.labelMedium),
          ],
        ),
      ),
    );
  }
}

/// All time: workouts, km run, tonnes lifted, hours trained.
class AllTimeCard extends StatelessWidget {
  const AllTimeCard({super.key});

  @override
  Widget build(BuildContext context) => TrainingDataBuilder(
    builder: (context, d) => Card(
      key: const Key('allTime'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All time',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.of(context).muted),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                NumberTile('${d.count}', 'workouts', divider: false),
                NumberTile(Units.toD(d.metres).toStringAsFixed(0), '${Units.d} run'),
                NumberTile(
                  formatBigWeight(d.volume, decimals: Units.toW(d.volume) >= 100000 ? 0 : 1),
                  '${bigWeightUnit(d.volume)} lifted'.trim(),
                ),
                NumberTile('${d.minutes ~/ 60} h', 'trained'),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// The month as a calendar with day numbers; training days tinted
/// (strength / run / both), today outlined. ‹ › change the month.
class MonthCalendarCard extends StatefulWidget {
  const MonthCalendarCard({super.key});

  @override
  State<MonthCalendarCard> createState() => _MonthCalendarCardState();
}

class _MonthCalendarCardState extends State<MonthCalendarCard> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    return TrainingDataBuilder(
      builder: (context, d) {
        final days = d.daysIn(_month);
        final first = DateTime(_month.year, _month.month);
        final lead = dayIndex(first.weekday); // weeks start on Sunday
        final count = DateTime(_month.year, _month.month + 1, 0).day;
        final isThisMonth = _month.year == now.year && _month.month == now.month;
        Color? tint(int v) => switch (v) {
          1 => Color.lerp(t.card, t.second, 0.32),
          2 => Color.lerp(t.card, t.bright, 0.28),
          _ => null,
        };
        Widget day(int n) {
          final v = days[n] ?? 0;
          final future = isThisMonth && n > now.day;
          final today = isThisMonth && n == now.day;
          return Container(
            key: Key('calDay_$n'),
            decoration: BoxDecoration(
              // Only training days are tinted; empty days stay plain (grey looked like data).
              color: v == 0 || v == 3 ? null : tint(v),
              gradient: v == 3
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.5, 0.5],
                      colors: [tint(1)!, tint(2)!],
                    )
                  : null,
              borderRadius: BorderRadius.circular(7),
              border: today ? Border.all(color: t.ink, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$n',
                  style: text.labelLarge?.copyWith(
                    fontSize: 12,
                    color: future ? t.muted : t.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
        }

        Widget legend(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 4),
            Text(label, style: text.labelSmall),
          ],
        );
        return Card(
          key: const Key('monthCalendar'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('${monthName(_month)} ${_month.year}', style: text.titleMedium)),
                    IconButton(
                      key: const Key('calPrev'),
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                    ),
                    IconButton(
                      key: const Key('calNext'),
                      icon: const Icon(Icons.chevron_right),
                      onPressed: isThisMonth
                          ? null
                          : () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    children: [
                      for (final l in weekLetters) Center(child: Text(l, style: text.labelSmall)),
                      for (var i = 0; i < lead; i++) const SizedBox.shrink(),
                      for (var n = 1; n <= count; n++) day(n),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    legend(t.second, 'Strength'),
                    const SizedBox(width: 10),
                    legend(t.bright, 'Run'),
                    const SizedBox(width: 10),
                    legend(t.ink, 'Both'),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text('${days.length} day${days.length == 1 ? '' : 's'}', style: text.labelLarge),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Last month in one line: workouts, km, sets.
class MonthlyRecapCard extends StatelessWidget {
  const MonthlyRecapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - 1);
    final to = DateTime(now.year, now.month);
    return TrainingDataBuilder(
      builder: (context, all) {
        final d = all.within(from, to);
        if (d.count == 0) return const SizedBox.shrink();
        final sets = d.workouts.fold(0, (v, w) => v + w.setCount);
        return Container(
          key: const Key('monthlyRecap'),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(10),
            boxShadow: t.cardShadow,
            border: Border(left: BorderSide(color: t.bright, width: 4)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${monthName(from)} recap', style: text.labelMedium),
              Text(
                '${d.count} workout${d.count == 1 ? '' : 's'} · ${Units.toD(d.metres).toStringAsFixed(0)} ${Units.d} · $sets sets',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text('${d.minutes ~/ 60} h ${d.minutes % 60} min of training', style: text.bodySmall),
            ],
          ),
        );
      },
    );
  }
}

/// A small box: label, big value, detail (records shelf).
class RecordBox extends StatelessWidget {
  const RecordBox({super.key, required this.label, required this.value, required this.detail});

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(10), boxShadow: t.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.labelMedium),
          FittedBox(
            child: Text(
              value,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.labelSmall),
        ],
      ),
    );
  }
}

String shortDate(DateTime d) => '${_months[d.month - 1].substring(0, 3)} ${d.day}';

/// Best lifts (estimated one-rep max) with their dates.
class StrengthRecordsCard extends StatelessWidget {
  const StrengthRecordsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    return TrainingDataBuilder(
      // Re-read when workouts change.
      builder: (context, d) => FutureBuilder<List<(LiftRecord, String)>>(
        future: () async {
          final lifts = await s.workouts.bestLifts();
          return [for (final l in lifts) (l, (await s.exercises.byId(l.exerciseId))?.name ?? l.exerciseId)];
        }(),
        builder: (context, snap) {
          final list = snap.data ?? const [];
          return Column(
            key: const Key('strengthRecords'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Strength records', style: text.titleMedium),
              const SizedBox(height: 6),
              if (list.isEmpty)
                Text('Your best lifts show up here after your first workout.', style: text.bodySmall)
              else
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.35,
                  children: [
                    for (final (l, name) in list)
                      RecordBox(
                        label: name,
                        value: formatWeight(l.estimated1Rm),
                        detail: 'est. 1RM · ${shortDate(l.date)}',
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A quiet badge (no confetti): earned ones bright, the next ones faded.
class Milestone {
  const Milestone(this.top, this.bottom, this.earned);

  final String top;
  final String bottom;
  final bool earned;
}

List<Milestone> milestones(TrainingData d) {
  final longest = d.runs.fold(0.0, (v, r) => r.distanceM > v ? r.distanceM : v);
  // Distance milestones count in the chosen unit (100 km or 100 miles…);
  // race distances keep their names.
  final run = Units.toD(d.metres);
  return [
    for (final n in const [10, 50, 100, 250, 500]) Milestone('$n', 'workouts', d.count >= n),
    for (final (m, label) in const [(5000.0, '5 km'), (10000.0, '10 km'), (21097.0, 'half')])
      Milestone('1st', label, longest >= m),
    for (final n in const [100, 500, 1000]) Milestone('$n', '${Units.d} run', run >= n),
  ];
}

class MilestonesCard extends StatelessWidget {
  const MilestonesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    return TrainingDataBuilder(
      builder: (context, d) {
        final all = milestones(d);
        // Earned ones, then the next two to aim for.
        final shown = [...all.where((m) => m.earned), ...all.where((m) => !m.earned).take(2)];
        return Column(
          key: const Key('milestones'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Milestones', style: text.titleMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in shown)
                  Opacity(
                    opacity: m.earned ? 1 : 0.45,
                    child: Container(
                      width: 72,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: t.card,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: m.earned ? t.cardShadow : null,
                        border: Border(top: BorderSide(color: m.earned ? t.bright : t.track, width: 3)),
                      ),
                      child: Column(
                        children: [
                          Text(m.top, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                          Text(m.bottom, style: text.labelSmall),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
