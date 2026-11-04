import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../app_shell.dart';
import '../../data/workout_repository.dart';
import '../../hr/hr_monitor.dart';
import '../../workout/stats.dart';
import '../../workout/streak.dart';
import '../goals_section.dart';
import '../history/history_screen.dart';
import '../streak_card.dart';
import '../zone_colors.dart';
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
        padding: const EdgeInsets.all(16),
        children: [
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
              _StartTile(icon: Icons.directions_run, label: 'Run', badge: 'soon', onTap: () => shell.goTo(AppTab.run)),
              const SizedBox(width: 8),
              const _ZonesTile(),
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
  const _StartTile({super.key, required this.icon, required this.label, required this.onTap, this.badge, this.color});

  final IconData icon;
  final String label;
  final String? badge;
  final Color? color;
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
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 6),
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                if (badge != null) Text(badge!, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Zones tile shows the live heart rate when monitoring.
class _ZonesTile extends StatelessWidget {
  const _ZonesTile();

  @override
  Widget build(BuildContext context) {
    final m = HrScope.of(context);
    return _StartTile(
      icon: Icons.monitor_heart_outlined,
      label: 'HR Zones',
      badge: m.running ? '${m.bpm ?? '--'} bpm' : null,
      color: m.running ? zoneColor(m.zone?.number) : null,
      onTap: () => AppShell.of(context).goTo(AppTab.zones),
    );
  }
}

class _ThisWeek extends StatelessWidget {
  const _ThisWeek();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return StreamBuilder<List<WorkoutListItem>>(
      stream: Services.of(context).workouts.watchFinished(),
      builder: (context, snap) {
        final list = snap.data ?? const <WorkoutListItem>[];
        final monday = weekStart(DateTime.now());
        final week = list.where((i) => !i.workout.startedAt.isBefore(monday)).toList();
        final volume = week.fold(0.0, (v, i) => v + i.volume);
        final sets = week.fold(0, (v, i) => v + i.setCount);
        final minutes = week.fold(
          0,
          (v, i) => v + ((i.workout.endedAt ?? i.workout.startedAt).difference(i.workout.startedAt).inMinutes),
        );
        Widget stat(String label, String value) => Expanded(
          child: Column(
            children: [
              Text(value, style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                    stat('workouts', '${week.length}'),
                    stat('sets', '$sets'),
                    stat('kg lifted', formatKg(volume)),
                    stat('minutes', '$minutes'),
                  ],
                ),
              ),
            ),
            if (list.isNotEmpty) ...[
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
              WorkoutTile(item: list.first),
            ],
          ],
        );
      },
    );
  }
}
