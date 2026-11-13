import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../../app_services.dart';
import '../../data/database.dart';
import '../../hr/hr_monitor.dart';
import '../../data/preset_repository.dart';
import '../../workout/active_workout.dart';
import '../../workout/interval_runner.dart';
import '../../workout/stats.dart';
import '../../workout/training_level.dart';
import '../../workout/template_update.dart';
import '../../workout/workout_session.dart';
import '../../run/location_source.dart';
import '../exercises/exercise_avatar.dart';
import '../exercises/exercise_detail_screen.dart';
import '../exercises/exercise_library_screen.dart';
import '../hr_presets.dart';
import '../number_input.dart';
import '../zone_colors.dart';
import '../timers/interval_run_screen.dart';
import 'calculators_sheet.dart';
import 'reorder_sheet.dart';
import 'timer_widgets.dart';
import 'workout_summary_screen.dart';
import '../../units/units.dart';

part 'exercise_card.dart';
part 'set_row.dart';
part 'workout_inputs.dart';
part 'workout_notes.dart';

const _supersetColors = [Colors.purple, Colors.teal, Colors.amber, Colors.pink];

/// Teal used for timed sets, readable on light and dark backgrounds.
Color timedColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.tealAccent : Colors.teal.shade700;

/// Gives the workout widgets their session: the running workout, or a
/// separate one when editing a past workout.
class SessionScope extends InheritedWidget {
  const SessionScope({super.key, required this.session, required super.child});

  final WorkoutSession session;

  static WorkoutSession of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()?.session ?? Services.of(context).session;

  @override
  bool updateShouldNotify(SessionScope oldWidget) => session != oldWidget.session;
}

class ActiveWorkoutScreen extends StatelessWidget {
  const ActiveWorkoutScreen({super.key, this.session});

  /// Defaults to the running workout; pass an edit-mode session to edit a
  /// past workout.
  final WorkoutSession? session;

  @override
  Widget build(BuildContext context) {
    final session = this.session ?? Services.of(context).session;
    return SessionScope(session: session, child: _build(context, session));
  }

  Widget _build(BuildContext context, WorkoutSession session) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final w = session.active;
        if (w == null) return const Scaffold(body: Center(child: Text('No workout in progress')));
        return Scaffold(
          appBar: session.templateMode
              ? _templateAppBar(context, session, w)
              : session.editMode
              ? _editAppBar(context, session, w)
              : AppBar(
                  leading: IconButton(
                    tooltip: 'Minimise',
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  titleSpacing: 0,
                  title: GestureDetector(
                    onTap: () => _rename(context, session, w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ElapsedText(key: const Key('workoutClock'), since: w.startedAt),
                        Text(w.name, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Timers',
                      icon: const Icon(Icons.timer_outlined),
                      onPressed: () => showTimerSheet(context, session),
                    ),
                    const _HrChip(),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      child: FilledButton(onPressed: () => _finish(context, session), child: const Text('Finish')),
                    ),
                  ],
                ),
          body: _withKeyboardBar(
            context,
            // The progress line stays at the top while the exercises scroll.
            header: session.editMode
                ? null
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: LinearProgressIndicator(
                      key: const Key('workoutProgress'),
                      value: session.progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
            ValueListenableBuilder<bool>(
              valueListenable: session.reorderMode,
              builder: (context, reordering, cards) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: reordering ? InPlaceReorder(session: session) : cards,
              ),
              child: ListView(
                // Keep cards that load data built off-screen (no jumping while scrolling).
                scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  if ((!session.editMode || session.templateMode) && Services.of(context).zonesEnabled.value)
                    PresetRow(presetId: w.hrPresetId, onChanged: session.applyPreset),
                  for (final (i, e) in w.exercises.indexed) _ExerciseCard(key: ValueKey(e.id), index: i, entry: e),
                  if (w.exercises.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Tip: hold an exercise name to reorder',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            icon: const Icon(Icons.add),
                            label: const Text('Exercises'),
                            onPressed: () async {
                              final picked = await ExerciseLibraryScreen.pick(context);
                              if (picked != null) await session.addExercises(picked);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            icon: const Icon(Icons.self_improvement),
                            label: const Text('Stretching'),
                            onPressed: () async {
                              final picked = await ExerciseLibraryScreen.pick(context, group: ExerciseGroup.stretching);
                              if (picked != null) await session.addExercises(picked);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!session.editMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: FilledButton(
                        key: const Key('discardWorkout'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => _discard(context, session),
                        child: const Text('Discard workout'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: session.timer == null || session.editMode ? null : TimerBar(session: session),
        );
      },
    );
  }

  /// Header when building a template: name + folder (tap to change), Save.
  PreferredSizeWidget _templateAppBar(BuildContext context, WorkoutSession session, ActiveWorkout w) {
    return AppBar(
      leading: IconButton(
        tooltip: 'Cancel',
        icon: const Icon(Icons.close),
        onPressed: () async {
          if (session.hasUnsavedEdits && w.exercises.isNotEmpty) {
            final leave = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Discard changes?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep editing')),
                  TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Discard')),
                ],
              ),
            );
            if (leave != true) return;
          }
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
      titleSpacing: 0,
      title: InkWell(
        key: const Key('templateHeader'),
        onTap: () => _rename(context, session, w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${w.name}  ✎', overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
            Text(
              session.templateFolder == null ? 'Template' : 'Template · ${session.templateFolder}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Folder',
          icon: const Icon(Icons.folder_outlined),
          onPressed: () => _pickFolder(context, session),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilledButton(
            onPressed: () async {
              if (w.exercises.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one exercise.')));
                return;
              }
              await session.saveTemplate(Services.of(context).templates);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }

  static Future<void> _pickFolder(BuildContext context, WorkoutSession session) async {
    final folders = await Services.of(context).templates.folders();
    if (!context.mounted) return;
    final c = TextEditingController(text: session.templateFolder ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: c,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'e.g. Push/Pull/Legs (empty = none)'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [for (final f in folders) ActionChip(label: Text(f), onPressed: () => Navigator.pop(ctx, f))],
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('OK'))],
      ),
    );
    if (result != null) session.setTemplateFolder(result);
  }

  /// Header when editing a past workout: date + duration (tap to change),
  /// Cancel and Save.
  PreferredSizeWidget _editAppBar(BuildContext context, WorkoutSession session, ActiveWorkout w) {
    final end = session.editEndedAt ?? w.startedAt;
    return AppBar(
      leading: IconButton(
        tooltip: 'Cancel',
        icon: const Icon(Icons.close),
        onPressed: () async {
          if (session.hasUnsavedEdits) {
            final leave = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Discard changes?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep editing')),
                  TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Discard')),
                ],
              ),
            );
            if (leave != true) return;
          }
          await session.discard();
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
      titleSpacing: 0,
      title: InkWell(
        key: const Key('editTimes'),
        onTap: () => _editTimes(context, session, w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(w.name, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${formatDate(w.startedAt)} · ${formatDuration(end.difference(w.startedAt))}  ✎',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Rename',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _rename(context, session, w),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilledButton(
            onPressed: () async {
              final summary = await session.saveEdits();
              if (!context.mounted) return;
              if (summary == null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Add at least one set with a weight, reps or time.')));
                return;
              }
              await Navigator.of(context)
                  .pushReplacement(MaterialPageRoute(builder: (_) => WorkoutSummaryScreen(summary: summary)));
            },
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }

  static Future<void> _editTimes(BuildContext context, WorkoutSession session, ActiveWorkout w) async {
    final start = await pickWorkoutStart(context, w.startedAt);
    if (start == null || !context.mounted) return;
    final current = (session.editEndedAt ?? w.startedAt).difference(w.startedAt).inMinutes;
    final minutes = await promptNumber(
      context,
      title: 'Duration (minutes)',
      initial: current,
      min: 1,
      max: 600,
      suffix: 'min',
    );
    session.setTimes(start, Duration(minutes: (minutes ?? current).round().clamp(1, 600)));
  }

  static Future<void> _rename(BuildContext context, WorkoutSession session, ActiveWorkout w) async {
    final c = TextEditingController(text: w.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Workout name'),
        content: TextField(controller: c, autofocus: true),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK'))],
      ),
    );
    if (name != null && name.isNotEmpty) session.rename(name);
  }

  /// After a workout started from a template: if anything changed, ask
  /// whether to update the template – keep it, take the new values only, or
  /// take everything (exercises, sets and values).
  static Future<void> offerTemplateUpdate(BuildContext context, ActiveWorkout w) async {
    final id = w.templateId;
    if (id == null) return;
    final repo = Services.of(context).templates;
    final t = await repo.byId(id);
    if (t == null || !context.mounted) return;
    final change = compareToTemplate(t, w);
    if (change == TemplateChange.none) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Update "${t.template.name}"?'),
        content: Text(
          change == TemplateChange.valuesOnly
              ? 'You used different weights, reps or times than the template.'
              : 'This workout had different exercises or sets than the template.',
        ),
        actions: [
          TextButton(
            key: const Key('keepTemplate'),
            onPressed: () => Navigator.pop(c, 'keep'),
            child: const Text('Keep template'),
          ),
          if (change == TemplateChange.structure)
            TextButton(
              key: const Key('updateValues'),
              onPressed: () => Navigator.pop(c, 'values'),
              child: const Text('Values only'),
            ),
          FilledButton(
            key: const Key('updateTemplate'),
            onPressed: () => Navigator.pop(c, change == TemplateChange.valuesOnly ? 'values' : 'all'),
            child: Text(change == TemplateChange.valuesOnly ? 'Update values' : 'Update everything'),
          ),
        ],
      ),
    );
    switch (choice) {
      case 'values':
        await repo.save(
          id: t.template.id,
          name: t.template.name,
          folder: t.template.folder,
          hrPresetId: t.template.hrPresetId,
          slots: templateWithNewValues(t, w),
        );
      case 'all':
        await repo.save(
          id: t.template.id,
          name: t.template.name,
          folder: t.template.folder,
          hrPresetId: t.template.hrPresetId,
          slots: WorkoutSession.slotsFrom(w),
        );
    }
  }

  /// The list, plus Next/Done right above the keyboard while it is open.
  static Widget _withKeyboardBar(BuildContext context, Widget list, {Widget? header}) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      children: [
        ?header,
        Expanded(child: list),
        if (keyboardOpen) const KeyboardBar(),
      ],
    );
  }

  static Future<void> _finish(BuildContext context, WorkoutSession session) async {
    final w = session.active!;
    final done = w.completedSets.length;
    final total = w.exercises.fold(0, (n, e) => n + e.sets.length);
    if (done == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tick at least one set as done (✓), or discard the workout.')));
      return;
    }
    // Always ask – one question that also says what will be dropped.
    final left = total - done;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Finish workout?'),
        content: Text(
          left == 0 ? 'All sets done – nice work.' : '$left set${left == 1 ? '' : 's'} not done will be removed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep going')),
          FilledButton(
            key: const Key('confirmFinish'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // Left open for hours (e.g. forgot to finish)? Offer the last set's time.
    DateTime? endAt;
    final last = session.lastSetAt;
    final open = DateTime.now().difference(w.startedAt);
    if (last != null && open > const Duration(hours: 4) && context.mounted) {
      final useLast = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Workout was open a long time'),
          content: Text(
            'It has been running for ${formatDuration(open)}. '
            'End it at your last set (${TimeOfDay.fromDateTime(last).format(c)})?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep full time')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('End at last set')),
          ],
        ),
      );
      if (useLast == null) return;
      if (useLast) endAt = last.add(const Duration(minutes: 1));
    }
    final summary = await session.finish(endedAt: endAt);
    if (summary == null || !context.mounted) return;
    await offerTemplateUpdate(context, summary.workout);
    if (!context.mounted) return;
    await Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => WorkoutSummaryScreen(summary: summary, justFinished: true)));
  }

  static Future<void> _discard(BuildContext context, WorkoutSession session) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Discard workout?'),
        content: const Text('Everything logged in this workout will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Discard')),
        ],
      ),
    );
    if (ok != true) return;
    await session.discard();
    if (context.mounted) Navigator.of(context).pop();
  }
}

/// The workout's running time (big, in the header).
class _ElapsedText extends StatefulWidget {
  const _ElapsedText({super.key, required this.since});

  final DateTime since;

  @override
  State<_ElapsedText> createState() => _ElapsedTextState();
}

class _ElapsedTextState extends State<_ElapsedText> {
  // Started in initState: a `late` field was only created in dispose(), so
  // the clock never ticked by itself (it froze between rest timers).
  late final Timer _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
    formatDuration(DateTime.now().difference(widget.since)),
    style: Theme.of(context).textTheme.headlineSmall
        ?.copyWith(fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()]),
  );
}

/// Live heart rate; tap to start/stop HR monitoring.
class _HrChip extends StatelessWidget {
  const _HrChip();

  @override
  Widget build(BuildContext context) {
    final m = HrScope.of(context);
    final color = zoneColor(m.zone?.number);
    return ActionChip(
      avatar: Icon(Icons.favorite, color: m.running ? AppColors.heart : color.withValues(alpha: 0.6), size: 18),
      label: Text(m.running ? (m.bpm?.toString() ?? '--') : 'HR'),
      onPressed: m.running ? m.stop : m.start,
    );
  }
}
