import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/workout_repository.dart';
import '../../workout/stats.dart';
import '../../workout/workout_session.dart';
import '../workout/workout_summary_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: StreamBuilder<List<WorkoutListItem>>(
        stream: s.workouts.watchFinished(),
        builder: (context, snap) {
          final list = snap.data;
          if (list == null) return const Center(child: CircularProgressIndicator());
          if (list.isEmpty) return const Center(child: Text('No workouts yet'));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) => WorkoutTile(item: list[i]),
          );
        },
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
        title: Text(w.name),
        subtitle: Text(
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
