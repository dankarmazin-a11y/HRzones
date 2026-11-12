import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/template_repository.dart';
import '../../data/workout_repository.dart';
import '../../workout/training_level.dart';
import '../goals_section.dart';
import '../programs/starter_programs_screen.dart';
import '../run/run_start.dart';
import '../screens/settings_screen.dart';
import '../screens/workouts_screen.dart';
import '../screens/zones_screen.dart';
import '../theme/app_theme.dart';
import '../workout/workout_editor.dart';

/// One step of a "get started" card.
class GuideStep {
  const GuideStep({required this.id, required this.title, this.detail, required this.done, this.actions = const []});

  final String id;
  final String title;
  final String? detail;
  final bool done;

  /// (label, onTap) buttons; the first is the main one.
  final List<(String, VoidCallback)> actions;
}

/// Empty-screen guide (docs/DESIGN.md): numbered steps, done ones ticked,
/// the first open step shows its buttons.
class GuidedSteps extends StatelessWidget {
  const GuidedSteps({super.key, required this.title, required this.steps});

  final String title;
  final List<GuideStep> steps;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    final current = steps.indexWhere((s) => !s.done);
    final doneCount = steps.where((s) => s.done).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
                Text('$doneCount of ${steps.length}', style: text.labelMedium?.copyWith(color: t.muted)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: doneCount / steps.length, minHeight: 5),
            ),
            const SizedBox(height: 6),
            for (final (i, s) in steps.indexed)
              _StepRow(step: s, number: i + 1, current: i == current, last: i == steps.length - 1),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.number, required this.current, required this.last});

  final GuideStep step;
  final int number;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    final dot = Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: step.done ? t.bright : (current ? t.ink : t.track)),
      child: step.done
          ? Icon(Icons.check_rounded, size: 17, color: t.onBright)
          : Text(
              '$number',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: current ? onColor(t.ink) : t.muted),
            ),
    );
    return InkWell(
      key: Key('guide_${step.id}'),
      borderRadius: BorderRadius.circular(9),
      onTap: step.actions.isEmpty ? null : step.actions.first.$2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dot,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 3),
                  Text(
                    step.title,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: step.done ? t.muted : null,
                      decoration: step.done ? TextDecoration.lineThrough : null,
                      decorationColor: t.muted,
                    ),
                  ),
                  if (step.detail != null) Text(step.detail!, style: text.bodySmall?.copyWith(color: t.muted)),
                  if (current && step.actions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final (j, a) in step.actions.indexed)
                          j == 0
                              ? FilledButton(key: Key('guideAction_${step.id}_$j'), onPressed: a.$2, child: Text(a.$1))
                              : OutlinedButton(
                                  key: Key('guideAction_${step.id}_$j'),
                                  onPressed: a.$2,
                                  child: Text(a.$1),
                                ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Strength tab until the first strength workout: level ✓ → program or
/// template → goal → first workout.
class StrengthGetStarted extends StatelessWidget {
  const StrengthGetStarted({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    return StreamBuilder<List<WorkoutListItem>>(
      stream: s.workouts.watchFinished(),
      builder: (context, wSnap) {
        if (!wSnap.hasData || wSnap.data!.isNotEmpty) return const SizedBox.shrink();
        return StreamBuilder<List<TemplateWithSlots>>(
          stream: s.templates.watchAll(),
          builder: (context, tSnap) => StreamBuilder<List<Goal>>(
            stream: s.goals.watchAll(),
            builder: (context, gSnap) => ValueListenableBuilder(
              valueListenable: s.level,
              builder: (context, level, _) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GuidedSteps(
                  key: const Key('strengthGuide'),
                  title: 'Get started',
                  steps: [
                    GuideStep(
                      id: 'level',
                      title: 'Your level',
                      detail: '${level.label} · change it in Settings',
                      done: true,
                      actions: [('Change', () => push(const SettingsScreen()))],
                    ),
                    GuideStep(
                      id: 'program',
                      title: 'Pick a program or create a template',
                      detail: 'Ready-made plans for your level, or build your own',
                      done: (tSnap.data ?? const []).isNotEmpty,
                      actions: [
                        ('Starter programs', () => push(const StarterProgramsScreen())),
                        ('Create a template', () => openTemplateEditor(context, null)),
                      ],
                    ),
                    GuideStep(
                      id: 'goal',
                      title: 'Set a goal',
                      detail: 'A lift, workouts per week or a body measurement',
                      done: (gSnap.data ?? const []).isNotEmpty,
                      actions: [('Set a goal', () => addGoal(context))],
                    ),
                    GuideStep(
                      id: 'first',
                      title: 'Do your first workout',
                      detail: 'Log sets as you go – rest timer and beeps included',
                      done: false,
                      actions: [('Start', () => quickStartStrength(context))],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Run tab until the first run: age ✓ → easy-run zone → goal → first run.
class RunGetStarted extends StatelessWidget {
  const RunGetStarted({super.key});

  static const _runGoals = {GoalType.runKmPerWeek, GoalType.runDistance, GoalType.runTime};

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final hr = s.hr;
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    return StreamBuilder<List<HrPreset>>(
      stream: s.presets.watchAll(),
      builder: (context, pSnap) => StreamBuilder<List<Goal>>(
        stream: s.goals.watchAll(),
        builder: (context, gSnap) {
          final zones = hr.zones;
          final z2 = zones.zones.length > 1 ? zones.zones[1] : null;
          return GuidedSteps(
            key: const Key('runGuide'),
            title: 'Get started',
            steps: [
              GuideStep(
                id: 'age',
                title: 'Your age',
                detail: '${hr.age} · max heart rate ${zones.maxHr}',
                done: true,
                actions: [('Change', () => push(const ZonesScreen()))],
              ),
              GuideStep(
                id: 'zone',
                title: 'Set your easy-run zone',
                detail: z2 == null
                    ? 'Beeps when you run too fast or too slow'
                    : 'Zone 2 for you is ${z2.minBpm}–${z2.maxBpm} bpm – beeps when you leave it',
                done: (pSnap.data ?? const <HrPreset>[]).any((p) => p.use != PresetUse.strength),
                actions: [('Set zone', () => push(const ZonesScreen()))],
              ),
              GuideStep(
                id: 'goal',
                title: 'Set a goal',
                detail: 'Km per week, a distance or a time',
                done: (gSnap.data ?? const <Goal>[]).any((g) => _runGoals.contains(g.type)),
                actions: [('Set a goal', () => addGoal(context))],
              ),
              GuideStep(
                id: 'first',
                title: 'Go for your first run',
                detail: 'Lock the phone and go – it keeps recording with music playing',
                done: false,
                actions: [('Start run', () => startRun(context))],
              ),
            ],
          );
        },
      ),
    );
  }
}
