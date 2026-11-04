import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/body_repository.dart';
import '../data/database.dart';
import '../data/goal_repository.dart';
import '../data/workout_repository.dart';
import '../workout/stats.dart';
import 'exercises/exercise_library_screen.dart';
import 'number_input.dart';

/// Goals with progress bars. [limit] shows only the first few (Home).
class GoalsSection extends StatelessWidget {
  const GoalsSection({super.key, this.limit, this.onSeeAll});

  final int? limit;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    // Progress depends on workouts and measurements too: rebuild on any change.
    return StreamBuilder<List<WorkoutListItem>>(
      stream: s.workouts.watchFinished(),
      builder: (context, _) => StreamBuilder<List<BodyMeasurement>>(
        stream: s.body.watchAll(),
        builder: (context, _) => StreamBuilder<List<Goal>>(
          stream: s.goals.watchAll(),
          builder: (context, snap) {
            final goals = snap.data ?? const <Goal>[];
            final shown = limit == null ? goals : goals.take(limit!).toList();
            return FutureBuilder<List<GoalProgress>>(
              future: Future.wait(shown.map(s.goals.progress)),
              builder: (context, p) {
                final items = p.data ?? const <GoalProgress>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Goals', style: text.titleMedium)),
                        if (onSeeAll != null && goals.isNotEmpty)
                          TextButton(onPressed: onSeeAll, child: const Text('See all')),
                        if (limit != null && goals.isNotEmpty)
                          IconButton(
                            key: const Key('addGoalHome'),
                            tooltip: 'Add goal',
                            icon: const Icon(Icons.add),
                            onPressed: () => addGoal(context),
                          ),
                        if (limit == null)
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add goal'),
                            onPressed: () => addGoal(context),
                          ),
                      ],
                    ),
                    if (goals.isEmpty)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.flag_outlined),
                          title: const Text('No goals yet'),
                          subtitle: const Text('e.g. Bench 100 kg, or body weight 80 kg'),
                          trailing: const Icon(Icons.add),
                          onTap: () => addGoal(context),
                        ),
                      ),
                    for (final g in items) _GoalTile(progress: g, compact: limit != null),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.progress, required this.compact});

  final GoalProgress progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final g = progress;
    final text = Theme.of(context).textTheme;
    final pct = (g.progress * 100).round();
    final start = g.goal.startValue;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            Icon(g.achieved ? Icons.emoji_events : Icons.flag_outlined, color: g.achieved ? Colors.amber : null),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.title, style: text.titleSmall),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: g.progress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
                  const SizedBox(height: 4),
                  Text(
                    g.achieved
                        ? 'Achieved! 🎉'
                        : [
                            '$pct%',
                            if (g.current != null) 'now ${formatKg(g.current)} ${g.unit}',
                            if (!compact && start != null) 'start ${formatKg(start)} ${g.unit}',
                          ].join(' · '),
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            if (!compact)
              PopupMenuButton<String>(
                onSelected: (_) => Services.of(context).goals.delete(g.goal.id),
                itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete goal'))],
              ),
          ],
        ),
      ),
    );
  }
}

/// Asks what kind of goal, then the details.
Future<void> addGoal(BuildContext context) async {
  final type = await showModalBottomSheet<GoalType>(
    context: context,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('New goal')),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('Lift a weight'),
            subtitle: const Text('e.g. Barbell Bench Press 100 kg'),
            onTap: () => Navigator.pop(c, GoalType.liftWeight),
          ),
          ListTile(
            leading: const Icon(Icons.monitor_weight_outlined),
            title: const Text('Body measurement'),
            subtitle: const Text('e.g. body weight 80 kg, waist 85 cm'),
            onTap: () => Navigator.pop(c, GoalType.measurement),
          ),
          const ListTile(
            enabled: false,
            leading: Icon(Icons.directions_run),
            title: Text('Running goals'),
            subtitle: Text('Coming with run tracking (Phase 2)'),
          ),
        ],
      ),
    ),
  );
  if (type == null || !context.mounted) return;
  final s = Services.of(context);
  switch (type) {
    case GoalType.liftWeight:
      final picked = await ExerciseLibraryScreen.pick(context);
      final ex = picked?.firstOrNull;
      if (ex == null || !context.mounted) return;
      final best = await s.goals.bestWeight(ex.id);
      if (!context.mounted) return;
      final target = await promptNumber(
        context,
        title: '${ex.name}: target (kg)',
        initial: best == null ? 60 : best + 5,
        decimal: true,
        min: 1,
        max: 1000,
        suffix: 'kg',
      );
      if (target != null) await s.goals.addLift(ex.id, target.toDouble());
    case GoalType.measurement:
      final kind = await showModalBottomSheet<MeasurementKind>(
        context: context,
        isScrollControlled: true,
        builder: (c) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.7),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final k in measurementKinds)
                  ListTile(title: Text(k.label), trailing: Text(k.unit), onTap: () => Navigator.pop(c, k)),
              ],
            ),
          ),
        ),
      );
      if (kind == null || !context.mounted) return;
      final latest = await s.body.latest(kind.key);
      if (!context.mounted) return;
      final target = await promptNumber(
        context,
        title: '${kind.label}: target (${kind.unit})',
        initial: latest ?? 0,
        decimal: true,
        max: 1000,
        suffix: kind.unit,
      );
      if (target != null) await s.goals.addMeasurement(kind.key, target.toDouble());
    case GoalType.workoutsPerWeek:
      break;
  }
}
