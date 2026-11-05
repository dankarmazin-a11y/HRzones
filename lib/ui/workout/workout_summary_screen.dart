import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/exercise_repository.dart';
import '../../workout/stats.dart';
import '../../workout/workout_session.dart';
import 'active_workout_screen.dart';
import 'workout_editor.dart';

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
        padding: const EdgeInsets.all(16),
        children: [
          if (justFinished) Text(s.workout.name, style: text.headlineSmall),
          Text(formatDate(s.workout.startedAt), style: text.bodyMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Stat(label: 'Duration', value: formatDuration(s.duration)),
              _Stat(label: 'Volume', value: '${formatKg(s.volume)} kg'),
              _Stat(label: 'Sets', value: '${s.setCount}'),
              if (s.avgHr != null) _Stat(label: 'Avg HR', value: '${s.avgHr}'),
              if (s.maxHr != null) _Stat(label: 'Max HR', value: '${s.maxHr}'),
            ],
          ),
          if (s.records.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('🏆 New personal records', style: text.titleMedium),
            for (final r in s.records)
              ListTile(
                dense: true,
                leading: const Icon(Icons.emoji_events, color: Colors.amber),
                title: Text('${s.exerciseName(r.exerciseId)} – ${r.kind.label}'),
                subtitle: Text('${formatRecord(r.kind, r.value)} (was ${formatRecord(r.kind, r.previous)})'),
              ),
          ],
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
                      Text(
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
      return (w == null || w == 0) ? '$prefix${secs ?? 0} s' : '$prefix${secs ?? 0} s with +${formatKg(w)} kg';
    }
    if (t == TrackingType.distance) {
      return '$prefix${formatKg(metres ?? 0)} m in ${formatDuration(Duration(seconds: secs ?? 0))}';
    }
    if (w == null || w == 0) return '$prefix${reps ?? 0} reps';
    return '$prefix${formatKg(w)} kg × ${reps ?? 0}';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: 104,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall),
          Text(value, style: text.titleMedium),
        ],
      ),
    );
  }
}
