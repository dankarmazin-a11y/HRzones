import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../app_services.dart';
import '../../app_shell.dart';
import '../../data/database.dart';
import '../../data/template_repository.dart';
import '../../data/workout_repository.dart';
import '../../workout/next_template.dart';
import '../../workout/streak.dart';
import '../backup_section.dart';
import '../goals_section.dart';
import '../history/history_screen.dart';
import '../run/weekly_plan.dart';
import '../stats/stats_screen.dart';
import '../theme/app_theme.dart';
import 'run_screen.dart';
import 'tools_screen.dart';
import 'workouts_screen.dart';
import '../../units/units.dart';

/// Dashboard: this week, your next workout, tools, goals, last workout.
/// Starting anything else is the Start button.
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
      appBar: AppBar(toolbarHeight: 68, title: Text(_greeting(), style: text.headlineMedium)),
      body: ListView(
        // Keep cards that load data built off-screen (no jumping while scrolling).
        scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          const BackupReminder(),
          const WeekHeroCard(),
          const SizedBox(height: 6),
          const NextWorkoutCard(),
          const TodayRunCard(),
          const ClosestGoalCard(),
          const SizedBox(height: 8),
          const ToolsRow(),
          const SizedBox(height: 16),
          GoalsSection(limit: 3, onSeeAll: () => shell.goTo(AppTab.profile)),
          const SizedBox(height: 8),
          const _LastWorkout(),
        ],
      ),
    );
  }
}

/// This week's numbers (from Sunday) and the streak.
class _Week {
  _Week(List<WorkoutListItem> workouts, List<Run> runs, int target) {
    final sunday = weekStart(DateTime.now());
    final w = workouts.where((i) => !i.workout.startedAt.isBefore(sunday)).toList();
    final r = runs.where((x) => !x.startedAt.isBefore(sunday)).toList();
    count = w.length + r.length;
    metres = r.fold(0.0, (v, x) => v + x.distanceM);
    minutes =
        w.fold(0, (v, i) => v + (i.workout.endedAt ?? i.workout.startedAt).difference(i.workout.startedAt).inMinutes) +
        r.fold(0, (v, x) => v + x.durationS ~/ 60);
    streak = weeklyStreak([
      ...workouts.map((i) => i.workout.startedAt),
      ...runs.map((x) => x.startedAt),
    ], target: target);
  }

  late final int count;
  late final double metres;
  late final int minutes;
  late final StreakInfo streak;
}

/// "This week · 3-week streak": workouts, km run, hours, progress to the weekly goal.
class WeekHeroCard extends StatelessWidget {
  const WeekHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    return StreamBuilder<List<WorkoutListItem>>(
      stream: s.workouts.watchFinished(),
      builder: (context, snap) => StreamBuilder<List<Run>>(
        stream: s.runs.watchFinished(),
        builder: (context, runSnap) => ValueListenableBuilder<int>(
          valueListenable: s.weeklyTarget,
          builder: (context, target, _) {
            final w = _Week(snap.data ?? const [], runSnap.data ?? const [], target);
            final weeks = w.streak.weeks;
            final h = w.minutes ~/ 60, m = w.minutes % 60;
            Widget number(String value, String label, {bool first = false}) => Expanded(
              child: Container(
                padding: EdgeInsets.only(left: first ? 0 : 10),
                decoration: first
                    ? null
                    : BoxDecoration(
                        border: Border(left: BorderSide(color: t.track)),
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      child: Text(
                        value,
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Text(label, style: text.labelMedium),
                  ],
                ),
              ),
            );
            return Card(
              key: const Key('weekHero'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'This week · ${weeks == 1 ? '1-week streak' : '$weeks-week streak'}',
                      style: text.labelLarge?.copyWith(color: t.muted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        number('${w.count}', 'workouts', first: true),
                        number(
                          Units.toD(w.metres).toStringAsFixed(Units.toD(w.metres) >= 10 ? 0 : 1),
                          '${Units.d} run',
                        ),
                        number('$h:${m.toString().padLeft(2, '0')}', 'hours'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: LinearProgressIndicator(
                        value: target == 0 ? 0 : (w.streak.thisWeek / target).clamp(0, 1).toDouble(),
                        minHeight: 6,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(child: Text('${w.streak.thisWeek} of $target workouts', style: text.labelMedium)),
                        TextButton(
                          key: const Key('openStats'),
                          onPressed: () =>
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
                          child: const Text('Stats ›'),
                        ),
                      ],
                    ),
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

/// Dark card with your next template and a play button (or "start a workout").
class NextWorkoutCard extends StatelessWidget {
  const NextWorkoutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return StreamBuilder<List<TemplateWithSlots>>(
      stream: s.templates.watchAll(),
      builder: (context, tSnap) => StreamBuilder<List<WorkoutListItem>>(
        stream: s.workouts.watchFinished(),
        builder: (context, wSnap) {
          final templates = tSnap.data ?? const <TemplateWithSlots>[];
          final last = (wSnap.data ?? const <WorkoutListItem>[])
              .where((w) => w.workout.templateId != null)
              .firstOrNull
              ?.workout
              .templateId;
          final next = nextTemplate(templates, last);
          final n = next?.slots.length ?? 0;
          return PlayCard(
            key: const Key('nextWorkout'),
            title: next?.template.name ?? 'Start a workout',
            subtitle: next == null
                ? 'Pick a starter program or an empty workout'
                : 'Your next workout · $n exercise${n == 1 ? '' : 's'}',
            onTap: () => next == null ? quickStartStrength(context) : startTemplateWorkout(context, next),
          );
        },
      ),
    );
  }
}

/// The dark "start this" card with a round play button in the bright colour.
class PlayCard extends StatelessWidget {
  const PlayCard({super.key, required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: dark ? scheme.surfaceContainerHigh : t.ink,
        borderRadius: BorderRadius.circular(10),
        elevation: dark ? 0 : 3,
        shadowColor: Colors.black38,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: text.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      Text(subtitle, style: text.bodySmall?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PlayButton(onTap: onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round play button in the bright colour.
class PlayButton extends StatelessWidget {
  const PlayButton({super.key, required this.onTap, this.size = 38});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Material(
      color: t.bright,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(Icons.play_arrow_rounded, color: t.onBright, size: size * 0.62),
        ),
      ),
    );
  }
}

class _LastWorkout extends StatelessWidget {
  const _LastWorkout();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = Services.of(context);
    return StreamBuilder<List<WorkoutListItem>>(
      stream: s.workouts.watchFinished(),
      builder: (context, snap) => StreamBuilder<List<Run>>(
        stream: s.runs.watchFinished(),
        builder: (context, runSnap) {
          final lastRun = (runSnap.data ?? const <Run>[]).firstOrNull;
          final lastStrength = (snap.data ?? const <WorkoutListItem>[]).firstOrNull;
          if (lastRun == null && lastStrength == null) return const SizedBox.shrink();
          final runIsLast =
              lastRun != null && (lastStrength == null || lastRun.startedAt.isAfter(lastStrength.workout.startedAt));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Last workout', style: text.titleMedium)),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
                    child: const Text('History ›'),
                  ),
                ],
              ),
              if (runIsLast) RunTile(run: lastRun) else WorkoutTile(item: lastStrength!),
            ],
          );
        },
      ),
    );
  }
}
