import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../app_services.dart';
import '../../app_shell.dart';
import '../../data/workout_repository.dart';
import '../../workout/stats.dart';
import '../../workout/streak.dart';
import '../backup_section.dart';
import '../goals_section.dart';
import '../history/history_screen.dart';
import '../streak_card.dart';
import '../run/run_start.dart';
import '../../data/database.dart';
import '../../run/geo.dart';
import 'run_screen.dart';
import 'workouts_screen.dart';

/// Dashboard: streak, quick start (strength / run / zones), goals, this week.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String _greeting() {
    final h = DateTime.now().hour;
    return h < 5 ? 'Good night' : (h < 12 ? 'Good morning' : (h < 18 ? 'Good afternoon' : 'Good evening'));
  }

  @override
  Widget build(BuildContext context) {
    final shell = AppShell.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(_greeting())),
      body: ListView(
        // Keep cards that load data built off-screen (no jumping while scrolling).
        scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
        padding: const EdgeInsets.all(16),
        children: [
          const BackupReminder(),
          const StreakCard(),
          const SizedBox(height: 8),
          Text('Start', style: text.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              _StartTile(
                key: const Key('startStrength'),
                icon: Icons.fitness_center,
                label: 'Strength',
                onTap: () => startEmptyWorkout(context),
              ),
              const SizedBox(width: 8),
              _StartTile(
                key: const Key('startRunHome'),
                icon: Icons.directions_run,
                label: 'Run',
                onTap: () => startRun(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GoalsSection(limit: 3, onSeeAll: () => shell.goTo(AppTab.profile)),
          const SizedBox(height: 16),
          const _ThisWeek(),
        ],
      ),
    );
  }
}

class _StartTile extends StatelessWidget {
  const _StartTile({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 110,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32),
                const SizedBox(height: 6),
                Text(label, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThisWeek extends StatelessWidget {
  const _ThisWeek();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = Services.of(context);
    return StreamBuilder<List<WorkoutListItem>>(
      stream: s.workouts.watchFinished(),
      builder: (context, snap) => StreamBuilder<List<Run>>(
        stream: s.runs.watchFinished(),
        builder: (context, runSnap) {
          final list = snap.data ?? const <WorkoutListItem>[];
          final runs = runSnap.data ?? const <Run>[];
          final monday = weekStart(DateTime.now());
          final week = list.where((i) => !i.workout.startedAt.isBefore(monday)).toList();
          final weekRuns = runs.where((r) => !r.startedAt.isBefore(monday)).toList();
          final volume = week.fold(0.0, (v, i) => v + i.volume);
          final sets = week.fold(0, (v, i) => v + i.setCount);
          final km = weekRuns.fold(0.0, (v, r) => v + r.distanceM);
          final minutes =
              week.fold(
                0,
                (v, i) => v + ((i.workout.endedAt ?? i.workout.startedAt).difference(i.workout.startedAt).inMinutes),
              ) +
              weekRuns.fold(0, (v, r) => v + r.durationS ~/ 60);
          // The newest workout of either kind.
          final lastRun = runs.firstOrNull;
          final lastStrength = list.firstOrNull;
          final runIsLast =
              lastRun != null && (lastStrength == null || lastRun.startedAt.isAfter(lastStrength.workout.startedAt));
          Widget stat(String label, String value) => Expanded(
            child: Column(
              children: [
                FittedBox(
                  child: Text(value, style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Text(label, style: text.labelSmall),
              ],
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('This week', style: text.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      stat('workouts', '${week.length + weekRuns.length}'),
                      stat('sets', '$sets'),
                      stat('kg lifted', formatKg(volume)),
                      stat('km run', formatKm(km)),
                      stat('minutes', '$minutes'),
                    ],
                  ),
                ),
              ),
              if (list.isNotEmpty || runs.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                  child: Row(
                    children: [
                      Expanded(child: Text('Last workout', style: text.titleMedium)),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
                        child: const Text('History'),
                      ),
                    ],
                  ),
                ),
                if (runIsLast) RunTile(run: lastRun) else WorkoutTile(item: lastStrength!),
              ],
            ],
          );
        },
      ),
    );
  }
}
