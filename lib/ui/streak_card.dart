import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/database.dart';
import '../data/workout_repository.dart';
import '../workout/streak.dart';
import 'number_input.dart';

/// Weekly streak: weeks in a row with at least the target number of workouts,
/// plus this week's days.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key, this.editable = false});

  /// Show the "workouts per week" setting.
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<List<WorkoutListItem>>(
      stream: s.workouts.watchFinished(),
      builder: (context, snap) => StreamBuilder<List<Run>>(
        // Runs count as workouts too.
        stream: s.runs.watchFinished(),
        builder: (context, runSnap) => ValueListenableBuilder<int>(
          valueListenable: s.weeklyTarget,
          builder: (context, target, _) {
            final info = weeklyStreak([
              ...(snap.data ?? const []).map((w) => w.workout.startedAt),
              ...(runSnap.data ?? const <Run>[]).map((r) => r.startedAt),
            ], target: target);
            final today = dayIndex(DateTime.now().weekday);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: info.weeks > 0 ? Colors.orange : scheme.onSurfaceVariant,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                info.weeks == 1 ? '1-week streak' : '${info.weeks}-week streak',
                                style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                info.thisWeekDone
                                    ? 'This week done: ${info.thisWeek}/$target workouts 💪'
                                    : '${info.thisWeek}/$target workouts this week',
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final (i, d) in weekLetters.indexed)
                          Column(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: info.daysThisWeek[i] ? scheme.primary : null,
                                  border: Border.all(
                                    color: i == today ? scheme.primary : scheme.outlineVariant,
                                    width: i == today ? 2 : 1,
                                  ),
                                ),
                                child: info.daysThisWeek[i]
                                    ? Icon(Icons.check, size: 16, color: scheme.onPrimary)
                                    : null,
                              ),
                              const SizedBox(height: 2),
                              Text(d, style: text.labelSmall),
                            ],
                          ),
                      ],
                    ),
                    if (editable) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Weekly goal: '),
                          EditableNumber(
                            value: target,
                            title: 'Workouts per week',
                            min: 1,
                            max: 14,
                            display: '$target workouts',
                            onChanged: (v) => s.setWeeklyTarget(v.round()),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: target > 1 ? () => s.setWeeklyTarget(target - 1) : null,
                            icon: const Icon(Icons.remove),
                          ),
                          IconButton(onPressed: () => s.setWeeklyTarget(target + 1), icon: const Icon(Icons.add)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
