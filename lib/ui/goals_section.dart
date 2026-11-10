import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/body_repository.dart';
import '../data/database.dart';
import '../data/goal_repository.dart';
import '../data/workout_repository.dart';
import '../run/best_efforts.dart';
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
      builder: (context, _) => StreamBuilder<List<Run>>(
        stream: s.runs.watchFinished(),
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
                            subtitle: const Text('e.g. Bench 100 kg, body weight 80 kg, or 5 km under 25 min'),
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
      ),
    );
  }
}

/// Home: the goal you're closest to (not achieved yet), big, live.
class ClosestGoalCard extends StatelessWidget {
  const ClosestGoalCard({super.key});

  /// The unfinished goal with the most progress (null when there is none).
  static GoalProgress? pick(List<GoalProgress> all) {
    GoalProgress? best;
    for (final g in all) {
      if (g.achieved) continue;
      if (best == null || g.progress > best.progress) best = g;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    // Re-read when anything a goal depends on changes.
    return StreamBuilder<List<WorkoutListItem>>(
      stream: s.workouts.watchFinished(),
      builder: (context, _) => StreamBuilder<List<Run>>(
        stream: s.runs.watchFinished(),
        builder: (context, _) => StreamBuilder<List<BodyMeasurement>>(
          stream: s.body.watchAll(),
          builder: (context, _) => StreamBuilder<List<Goal>>(
            stream: s.goals.watchAll(),
            builder: (context, snap) => FutureBuilder<List<GoalProgress>>(
              future: Future.wait((snap.data ?? const <Goal>[]).map(s.goals.progress)),
              builder: (context, p) {
                final g = pick(p.data ?? const []);
                if (g == null) return const SizedBox.shrink();
                return _ClosestGoal(progress: g);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ClosestGoal extends StatelessWidget {
  const _ClosestGoal({required this.progress});

  final GoalProgress progress;

  @override
  Widget build(BuildContext context) {
    final g = progress;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final pct = (g.progress * 100).round();
    return Card(
      key: const Key('closestGoal'),
      color: scheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => editGoal(context, g),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, size: 18, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 6),
                  Text('Closest goal', style: text.labelLarge?.copyWith(color: scheme.onPrimaryContainer)),
                  const Spacer(),
                  Text(
                    '$pct%',
                    style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: scheme.onPrimaryContainer),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(g.title, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: g.progress, minHeight: 12, borderRadius: BorderRadius.circular(6)),
              const SizedBox(height: 6),
              Text(
                [
                  if (g.current != null) 'Now ${_value(g, g.current!)}',
                  'Target ${_value(g, g.goal.target)}',
                ].join(' · '),
                style: text.bodyMedium,
              ),
            ],
          ),
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('goal-${g.goal.id}'),
        onTap: () => editGoal(context, g),
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
                          ? 'Achieved!'
                          : [
                              '$pct%',
                              if (g.current != null) 'now ${_value(g, g.current!)}',
                              if (!compact && start != null) 'start ${_value(g, start)}',
                            ].join(' · '),
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!compact)
                PopupMenuButton<String>(
                  onSelected: (v) => v == 'edit' ? editGoal(context, g) : Services.of(context).goals.delete(g.goal.id),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit goal')),
                    PopupMenuItem(value: 'delete', child: Text('Delete goal')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Edit a goal: change the target or the deadline, or delete it.
Future<void> editGoal(BuildContext context, GoalProgress g) async {
  final s = Services.of(context);
  var target = g.goal.target;
  DateTime? deadline = g.goal.deadline;
  final result = await showDialog<String>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => AlertDialog(
        title: Text(g.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Target: '),
                EditableNumber(
                  value: target,
                  title: 'Target (${g.unit})',
                  decimal: true,
                  min: 0,
                  max: 1000,
                  suffix: g.unit,
                  display: '${formatKg(target)} ${g.unit}',
                  onChanged: (v) => setState(() => target = v.toDouble()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Deadline: '),
                TextButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final d = await showDatePicker(
                      context: c,
                      initialDate: deadline ?? now.add(const Duration(days: 56)),
                      firstDate: now.subtract(const Duration(days: 365)),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (d != null) setState(() => deadline = d);
                  },
                  child: Text(deadline == null ? 'none' : '${deadline!.day}.${deadline!.month}.${deadline!.year}'),
                ),
                if (deadline != null)
                  IconButton(
                    tooltip: 'No deadline',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => deadline = null),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(c).colorScheme.error),
            onPressed: () => Navigator.pop(c, 'delete'),
            child: const Text('Delete'),
          ),
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            key: const Key('saveGoal'),
            onPressed: () => Navigator.pop(c, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  if (result == 'save') await s.goals.updateGoal(g.goal.id, target: target, deadline: deadline);
  if (result == 'delete') await s.goals.delete(g.goal.id);
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
          ListTile(
            key: const Key('goalRunWeek'),
            leading: const Icon(Icons.directions_run),
            title: const Text('Run km per week'),
            subtitle: const Text('e.g. 20 km every week'),
            onTap: () => Navigator.pop(c, GoalType.runKmPerWeek),
          ),
          ListTile(
            key: const Key('goalRunDistance'),
            leading: const Icon(Icons.route),
            title: const Text('Run a distance'),
            subtitle: const Text('e.g. 10 km in one run'),
            onTap: () => Navigator.pop(c, GoalType.runDistance),
          ),
          ListTile(
            key: const Key('goalRunTime'),
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Run faster'),
            subtitle: const Text('e.g. 5 km under 25 minutes'),
            onTap: () => Navigator.pop(c, GoalType.runTime),
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
    case GoalType.runKmPerWeek:
      final target = await promptNumber(
        context,
        title: 'Km per week',
        initial: 20,
        decimal: true,
        min: 1,
        max: 500,
        suffix: 'km',
      );
      if (target != null) await s.goals.addRun(GoalType.runKmPerWeek, target.toDouble());
    case GoalType.runDistance:
      final target = await promptNumber(
        context,
        title: 'Distance in one run',
        initial: 10,
        decimal: true,
        min: 1,
        max: 200,
        suffix: 'km',
      );
      if (target != null) await s.goals.addRun(GoalType.runDistance, target.toDouble());
    case GoalType.runTime:
      final d = await showModalBottomSheet<int>(
        context: context,
        builder: (c) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Which distance?')),
              for (final e in recordDistances.entries)
                ListTile(key: Key('goalDistance_${e.key}'), title: Text(e.value), onTap: () => Navigator.pop(c, e.key)),
            ],
          ),
        ),
      );
      if (d == null || !context.mounted) return;
      final best = (await s.runs.records()).fastest[d]?.value;
      if (!context.mounted) return;
      final target = await promptNumber(
        context,
        title: '${recordDistances[d]}: target time (minutes)',
        initial: best == null ? (d / 1000 * 6).roundToDouble() : (best / 60 * 0.95).floorToDouble(),
        decimal: true,
        min: 1,
        max: 600,
        suffix: 'min',
      );
      if (target != null) await s.goals.addRun(GoalType.runTime, target.toDouble(), distanceM: d.toDouble());
    case GoalType.workoutsPerWeek:
      break;
  }
}

/// "26:30" for run times, "12.4 km", "82.5 kg"…
String _value(GoalProgress g, double v) => g.goal.type == GoalType.runTime
    ? minutesText(v)
    : '${g.goal.type == GoalType.runKmPerWeek || g.goal.type == GoalType.runDistance ? v.toStringAsFixed(1) : formatKg(v)} ${g.unit}';
