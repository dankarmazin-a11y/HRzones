import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/exercise_repository.dart';
import '../../workout/stats.dart';
import '../../workout/workout_session.dart';
import 'active_workout_screen.dart';
import 'workout_editor.dart';
import '../theme/emblems.dart';
import '../theme/app_theme.dart';
import '../exercises/exercise_avatar.dart';
import '../figures/exercise_figure.dart';

String formatDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final t = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]} ${d.year}, $t';
}

class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({super.key, required this.summary, this.justFinished = false});

  final WorkoutSummary summary;
  final bool justFinished;

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete workout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await Services.of(context).workouts.delete(summary.workout.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  /// Starts a new workout now with this one's exercises and values.
  Future<void> _repeat(BuildContext context) async {
    final s = Services.of(context);
    if (s.session.active != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Finish or discard the running workout first.')));
      return;
    }
    if (!await s.session.startFromWorkout(summary.workout.id) || !context.mounted) return;
    await Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen(), fullscreenDialog: true));
  }

  Future<void> _saveAsTemplate(BuildContext context) async {
    final s = Services.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await s.templates.save(name: summary.workout.name, slots: WorkoutSession.slotsFrom(summary.workout));
    messenger.showSnackBar(SnackBar(content: Text('Saved "${summary.workout.name}" as a template')));
  }

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(justFinished ? 'Workout complete' : s.workout.name),
        actions: [
          if (!justFinished) ...[
            IconButton(
              tooltip: 'Edit workout',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => openWorkoutEditor(context, summary.workout.id),
            ),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context)),
          ],
          PopupMenuButton<String>(
            key: const Key('summaryMenu'),
            onSelected: (v) => v == 'repeat' ? _repeat(context) : _saveAsTemplate(context),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'repeat',
                child: ListTile(leading: Icon(Icons.replay), title: Text('Repeat workout now')),
              ),
              PopupMenuItem(
                value: 'template',
                child: ListTile(leading: Icon(Icons.playlist_add), title: Text('Save as template')),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        // Keep cards that load data built off-screen (no jumping while scrolling).
        scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
        padding: const EdgeInsets.all(16),
        children: [
          if (justFinished) Text(s.workout.name, style: text.headlineSmall),
          Text(formatDate(s.workout.startedAt), style: text.bodyMedium),
          const SizedBox(height: 16),
          // owner (19 Nov): a tidy 3 × 3 grid, every tile the same size, numbers centred, grey
          FutureBuilder<double?>(
            key: const Key('summaryCalories'),
            future: Services.of(context).body.latest('weight'),
            builder: (context, snap) {
              final kcal = s.calories(weightKg: snap.data, age: Services.of(context).hr.age);
              final h = s.heaviestSet;
              final tiles = <(String, String)>[
                ('Time', formatDuration(s.duration)),
                (
                  'Volume',
                  '${formatBigWeight(s.volume)}${bigWeightUnit(s.volume).isEmpty ? '' : ' ${bigWeightUnit(s.volume)}'}',
                ),
                ('Sets', '${s.setCount}'),
                (kcal == null ? 'kcal (add weight)' : 'Calories', kcal == null ? '–' : '${kcal.round()}'),
                ('Avg HR', s.avgHr == null ? '–' : '${s.avgHr}'),
                ('Reps', '${s.reps}'),
                ('Working', formatDuration(s.working)),
                ('Resting', formatDuration(s.resting)),
                ('Heaviest', h == null ? '–' : '${formatW(h.weightKg!)}${h.reps != null ? ' × ${h.reps}' : ''}'),
              ];
              return GridView(
                key: const Key('summaryStats'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 74,
                ),
                children: [for (final (label, value) in tiles) _Stat(label: label, value: value)],
              );
            },
          ),
          if (s.records.isNotEmpty) ...[const SizedBox(height: 24), _Records(summary: s)],
          if (s.setsPerMuscle.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Muscles worked', style: text.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final MapEntry(:key, :value) in s.setsPerMuscle.entries)
                  Chip(label: Text('${titleCase(key)} · $value')),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text('Exercises', style: text.titleMedium),
          for (final e in s.workout.exercises)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.exercise.name, style: text.titleSmall),
                    const SizedBox(height: 4),
                    for (final (i, set) in e.sets.indexed)
                      HeartText(
                        '${i + 1}. ${set.subExercise != null ? '${set.subExercise!.name}: ' : ''}'
                        '${_setText(e.exercise.trackingType, set.type, set.weightKg, set.reps, set.durationS, set.distanceM)}'
                        '${set.rpe != null ? ' @ RPE ${formatKg(set.rpe)}' : ''}'
                        '${set.maxHr != null ? '  ♥ ${set.maxHr}' : ''}',
                      ),
                  ],
                ),
              ),
            ),
          if (justFinished) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
          ],
        ],
      ),
    );
  }

  static String _setText(TrackingType t, SetType type, double? w, int? reps, int? secs, [double? metres]) {
    final prefix = switch (type) {
      SetType.warmup => 'Warm-up: ',
      SetType.drop => 'Drop: ',
      SetType.failure => 'Failure: ',
      SetType.normal => '',
    };
    if (t == TrackingType.duration) {
      return (w == null || w == 0) ? '$prefix${secs ?? 0} s' : '$prefix${secs ?? 0} s with +${formatWeight(w)}';
    }
    if (t == TrackingType.distance) {
      return '$prefix${formatKg(metres ?? 0)} m in ${formatDuration(Duration(seconds: secs ?? 0))}';
    }
    if (w == null || w == 0) return '$prefix${reps ?? 0} reps';
    return '$prefix${formatWeight(w)} × ${reps ?? 0}';
  }
}

/// Grey stat tile: label on top, the number big, both centred.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(letterSpacing: 0.4, color: AppTheme.of(context).muted),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.3)),
          ),
        ],
      ),
    );
  }
}

/// The new records (owner, 19 Nov): at most 5, one per exercise, short; the
/// most important one of the workout is highlighted on top.
class _Records extends StatefulWidget {
  const _Records({required this.summary});

  final WorkoutSummary summary;

  @override
  State<_Records> createState() => _RecordsState();
}

class _RecordsState extends State<_Records> {
  bool _all = false;

  Exercise? _exercise(String id) {
    for (final e in widget.summary.workout.exercises) {
      if (e.exercise.id == id) return e.exercise;
      for (final s in e.sets) {
        if (s.subExercise?.id == id) return s.subExercise;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final text = Theme.of(context).textTheme;
    final t = AppTheme.of(context);
    final top = topRecords(s.records);
    final shown = _all ? s.records : top;
    final more = s.records.length - top.length;
    Widget figure(PersonalRecord r, double size) {
      final e = _exercise(r.exerciseId);
      return e == null
          ? Icon(Icons.emoji_events, color: Colors.amber, size: size)
          : RecordFigure(exercise: e, size: size);
    }

    final best = top.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '🏆 ${s.records.length == 1 ? '1 new record' : '${s.records.length} new records'}',
          style: text.titleMedium,
        ),
        const SizedBox(height: 8),
        // The workout's most important record, highlighted.
        Container(
          key: const Key('topRecord'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.bright.withValues(alpha: 0.12),
            border: Border.all(color: t.bright, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              figure(best, 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BEST OF THE WORKOUT', style: text.labelSmall?.copyWith(color: t.bright, letterSpacing: 0.6)),
                    Text(
                      s.exerciseName(best.exerciseId),
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(best.kind.short, style: text.bodySmall?.copyWith(color: t.muted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRecord(best.kind, best.value),
                    style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    formatRecordGain(best),
                    style: text.labelMedium?.copyWith(color: const Color(0xFF30A46C), fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        for (final r in shown.where((r) => r != best))
          Padding(
            key: Key('record_${r.exerciseId}_${r.kind.name}'),
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                figure(r, 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.exerciseName(r.exerciseId),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(r.kind.short, style: text.bodySmall?.copyWith(color: t.muted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatRecord(r.kind, r.value), style: text.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                    Text(
                      formatRecordGain(r),
                      style: text.labelSmall?.copyWith(color: const Color(0xFF30A46C), fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (more > 0 && !_all)
          TextButton(
            key: const Key('moreRecords'),
            onPressed: () => setState(() => _all = true),
            child: Text('+$more more'),
          ),
      ],
    );
  }
}

/// The exercise's line figure next to a record (owner, 19 Nov), on a soft
/// tile; the photo while an exercise has no approved figure yet.
class RecordFigure extends StatelessWidget {
  const RecordFigure({super.key, required this.exercise, this.size = 40});

  final Exercise exercise;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppTheme.of(context).bright.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(size * 0.25),
    ),
    clipBehavior: Clip.antiAlias,
    child: ExerciseFigure(
      exerciseId: exercise.id,
      size: size,
      fallback: ExerciseAvatar(exercise: exercise, radius: size / 2),
    ),
  );
}
