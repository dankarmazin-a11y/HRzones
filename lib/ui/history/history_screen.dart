import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/workout_repository.dart';
import '../run/edit_run_screen.dart';
import '../screens/run_screen.dart';
import '../../workout/stats.dart';
import '../../workout/workout_session.dart';
import '../workout/workout_editor.dart';
import '../workout/workout_summary_screen.dart';
import '../theme/emblems.dart';

enum _Show { all, strength, run }

/// Every finished workout – strength and runs – newest first.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _Show _show = _Show.all;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.edit_calendar),
        label: const Text('Log past workout'),
        onPressed: () async {
          final kind = await showModalBottomSheet<String>(
            context: context,
            builder: (c) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Emblem(EmblemKind.dumbbell),
                    title: const Text('Strength workout'),
                    onTap: () => Navigator.pop(c, 'strength'),
                  ),
                  ListTile(
                    key: const Key('logPastRun'),
                    leading: const Emblem(EmblemKind.run),
                    title: const Text('Run'),
                    onTap: () => Navigator.pop(c, 'run'),
                  ),
                ],
              ),
            ),
          );
          if (!context.mounted) return;
          if (kind == 'strength') return logPastWorkout(context);
          if (kind == 'run') {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditRunScreen()));
          }
        },
      ),
      body: StreamBuilder<List<WorkoutListItem>>(
        stream: s.workouts.watchFinished(),
        builder: (context, snap) => StreamBuilder<List<Run>>(
          stream: s.runs.watchFinished(),
          builder: (context, runSnap) {
            final list = snap.data;
            final runs = runSnap.data;
            if (list == null || runs == null) return const Center(child: CircularProgressIndicator());
            final items = <(DateTime, Widget)>[
              if (_show != _Show.run)
                for (final w in list) (w.workout.startedAt, WorkoutTile(item: w)),
              if (_show != _Show.strength)
                for (final r in runs)
                  (
                    r.startedAt,
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: RunTile(run: r),
                      ),
                    ),
                  ),
            ]..sort((a, b) => b.$1.compareTo(a.$1));
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: SegmentedButton<_Show>(
                    showSelectedIcon: false,
                    key: const Key('historyFilter'),
                    segments: const [
                      ButtonSegment(value: _Show.all, label: Text('All')),
                      ButtonSegment(value: _Show.strength, label: Text('Strength'), icon: Icon(Icons.fitness_center)),
                      ButtonSegment(value: _Show.run, label: Text('Run'), icon: Icon(Icons.directions_run)),
                    ],
                    selected: {_show},
                    onSelectionChanged: (v) => setState(() => _show = v.first),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('No workouts yet'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: items.length,
                          itemBuilder: (context, i) => items[i].$2,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class WorkoutTile extends StatelessWidget {
  const WorkoutTile({super.key, required this.item});

  final WorkoutListItem item;

  @override
  Widget build(BuildContext context) {
    final w = item.workout;
    final duration = w.endedAt == null ? Duration.zero : w.endedAt!.difference(w.startedAt);
    return Card(
      child: ListTile(
        leading: const Emblem(EmblemKind.dumbbell),
        title: Text(w.name),
        subtitle: HeartText(
          '${formatDate(w.startedAt)}\n'
          '${formatDuration(duration)} · ${item.setCount} sets · ${formatKg(item.volume)} kg'
          '${w.avgHr != null ? ' · ♥ ${w.avgHr}' : ''}\n'
          '${item.exerciseNames.join(', ')}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        onTap: () => openWorkoutSummary(context, w.id),
      ),
    );
  }
}

Future<void> openWorkoutSummary(BuildContext context, String workoutId) async {
  final repo = Services.of(context).workouts;
  final row = await repo.workoutRow(workoutId);
  final w = await repo.loadById(workoutId);
  if (row == null || w == null || !context.mounted) return;
  final summary = await WorkoutSummary.build(repo, w, row.endedAt ?? row.startedAt, avgHr: row.avgHr, maxHr: row.maxHr);
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkoutSummaryScreen(summary: summary)));
}
