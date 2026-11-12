import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../app_services.dart';
import '../../app_shell.dart';
import '../../data/workout_repository.dart';
import '../../workout/stats.dart';
import '../../workout/streak.dart';
import '../backup_section.dart';
import '../goals_section.dart';
import '../run/weekly_plan.dart';
import '../history/history_screen.dart';
import '../stats/stats_screen.dart';
import '../streak_card.dart';
import '../../data/database.dart';
import '../../run/geo.dart';
import 'run_screen.dart';
import 'tools_screen.dart';

/// Dashboard: streak, tools, goals, this week. Starting is the Start button.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String _greeting() {
    final h = DateTime.now().hour;
    return h < 5 ? 'Good night' : (h < 12 ? 'Good morning' : (h < 18 ? 'Good afternoon' : 'Good evening'));
  }

  @override
  Widget build(BuildContext context) {
    final shell = AppShell.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_greeting())),
      body: ListView(
        // Keep cards that load data built off-screen (no jumping while scrolling).
        scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
        padding: const EdgeInsets.all(16),
        children: [
          const BackupReminder(),
          const ClosestGoalCard(),
          const TodayRunCard(),
          const StreakCard(),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          const ToolsRow(),
          const SizedBox(height: 16),
          GoalsSection(limit: 3, onSeeAll: () => shell.goTo(AppTab.profile)),
          const SizedBox(height: 16),
          const _ThisWeek(),
        ],
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
          final sunday = weekStart(DateTime.now());
          final week = list.where((i) => !i.workout.startedAt.isBefore(sunday)).toList();
          final weekRuns = runs.where((r) => !r.startedAt.isBefore(sunday)).toList();
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
              Row(
                children: [
                  Expanded(child: Text('This week', style: text.titleMedium)),
                  TextButton.icon(
                    key: const Key('openStats'),
                    icon: const Icon(Icons.insights, size: 18),
                    label: const Text('Stats'),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
                  ),
                ],
              ),
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
