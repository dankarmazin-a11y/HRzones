import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../hr/hr_monitor.dart';
import '../../workout/active_workout.dart';
import '../../workout/stats.dart';
import '../../workout/training_level.dart';
import '../../workout/workout_session.dart';
import '../exercises/exercise_avatar.dart';
import '../exercises/exercise_detail_screen.dart';
import '../exercises/exercise_library_screen.dart';
import '../hr_presets.dart';
import '../number_input.dart';
import '../zone_colors.dart';
import 'calculators_sheet.dart';
import 'reorder_sheet.dart';
import 'timer_widgets.dart';
import 'workout_summary_screen.dart';

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
                        _ElapsedText(since: w.startedAt),
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
          body: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              LinearProgressIndicator(value: session.progress, minHeight: 3),
              if (!session.editMode || session.templateMode)
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton(
                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    onPressed: () => _discard(context, session),
                    child: const Text('Discard workout'),
                  ),
                ),
            ],
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

  static Future<void> _finish(BuildContext context, WorkoutSession session) async {
    final w = session.active!;
    final done = w.completedSets.length;
    final total = w.exercises.fold(0, (n, e) => n + e.sets.length);
    if (done == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tick at least one set as done (✓), or discard the workout.')));
      return;
    }
    if (done < total) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Finish workout?'),
          content: Text('${total - done} unfinished set(s) will be removed.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep going')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Finish')),
          ],
        ),
      );
      if (ok != true) return;
    }
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
  const _ElapsedText({required this.since});

  final DateTime since;

  @override
  State<_ElapsedText> createState() => _ElapsedTextState();
}

class _ElapsedTextState extends State<_ElapsedText> {
  late final Timer _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));

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
      avatar: Icon(Icons.favorite, color: m.running ? color : null, size: 18),
      label: Text(m.running ? (m.bpm?.toString() ?? '--') : 'HR'),
      onPressed: m.running ? m.stop : m.start,
    );
  }
}

/// Compact button showing how an exercise is logged; each tap switches
/// weight × reps → reps → time.
class TrackingToggle extends StatelessWidget {
  const TrackingToggle({super.key, required this.type, required this.onChanged});

  final TrackingType type;
  final ValueChanged<TrackingType> onChanged;

  static const _order = [TrackingType.weightReps, TrackingType.bodyweightReps, TrackingType.duration];

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (type) {
      TrackingType.weightReps => (Icons.fitness_center, 'kg×reps'),
      TrackingType.bodyweightReps => (Icons.repeat, 'reps'),
      TrackingType.duration || TrackingType.distance => (Icons.timer_outlined, 'time'),
    };
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Tap to change how this exercise is logged',
      child: InkWell(
        key: const Key('trackingToggle'),
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final i = _order.indexOf(type);
          onChanged(_order[(i + 1) % _order.length]);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 4),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({super.key, required this.index, required this.entry});

  final int index;
  final LoggedExercise entry;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final e = entry;
    final isSession = e.exercise.isStretchSession;
    final tracking = e.exercise.trackingType;
    final text = Theme.of(context).textTheme;
    final group = e.supersetGroup;
    final list = session.active!.exercises;
    final linkedToNext = group != null && index + 1 < list.length && list[index + 1].supersetGroup == group;

    Future<void> addStretches() async {
      final picked = await ExerciseLibraryScreen.pick(context, group: ExerciseGroup.stretching);
      if (picked != null) session.addStretches(e, picked.where((x) => x.isStretch && !x.isStretchSession).toList());
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      shape: group == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _supersetColors[group % _supersetColors.length], width: 2),
            ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExerciseAvatar(exercise: e.exercise, radius: 16),
                const SizedBox(width: 8),
                Expanded(
                  // Tap: details. Hold: compact list to reorder the workout.
                  child: InkWell(
                    onTap: isSession
                        ? null
                        : () =>
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: e.exercise))),
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      showReorderSheet(context, session);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        e.exercise.name,
                        style: text.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                ),
                if (!isSession) TrackingToggle(type: tracking, onChanged: (t) => session.setTrackingType(e, t)),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    switch (v) {
                      case 'rest':
                        final r = await pickRestSeconds(context, e.restSeconds);
                        if (r != null) session.setRestSeconds(e, r);
                      case 'superset':
                        session.toggleSupersetWithNext(e);
                      case 'swap':
                        final picked = await ExerciseLibraryScreen.pick(context);
                        final next = picked?.where((x) => !x.isStretchSession).firstOrNull;
                        if (next != null) await session.swapExercise(e, next);
                      case 'calc':
                        final last = e.sets.lastWhere((x) => x.weightKg != null, orElse: () => e.sets.first);
                        if (context.mounted) {
                          await showCalculators(context, weightKg: last.weightKg, reps: last.reps);
                        }
                      case 'reorder':
                        if (context.mounted) await showReorderSheet(context, session);
                      case 'remove':
                        session.removeExercise(e);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'rest', child: Text('Rest timer (${formatRest(e.restSeconds)})')),
                    if (index + 1 < list.length && !isSession)
                      PopupMenuItem(
                        value: 'superset',
                        child: Text(linkedToNext ? 'Remove superset with next' : 'Superset with next'),
                      ),
                    if (!isSession) const PopupMenuItem(value: 'swap', child: Text('Swap exercise')),
                    if (tracking == TrackingType.weightReps && e.sets.isNotEmpty)
                      const PopupMenuItem(value: 'calc', child: Text('Plate & 1RM calculator')),
                    if (list.length > 1) const PopupMenuItem(value: 'reorder', child: Text('Reorder exercises')),
                    const PopupMenuItem(value: 'remove', child: Text('Remove exercise')),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 2),
              child: Text(
                [
                  if (group != null) 'Superset',
                  'Rest ${formatRest(e.restSeconds)}',
                  if (isSession) 'tap ▶ and the stretches run one after another',
                ].join(' · '),
                style: text.labelSmall,
              ),
            ),
            if (isSession)
              const _StretchHeaderRow()
            else
              _HeaderRow(
                tracking: tracking,
                showRpe: !e.exercise.isStretch && Services.of(context).level.value.showsAdvancedSetOptions,
              ),
            for (final (i, s) in e.sets.indexed)
              Dismissible(
                key: ValueKey(s.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete),
                ),
                onDismissed: (_) => session.removeSet(e, s),
                child: SetRow(entry: e, set: s, index: i),
              ),
            TextButton.icon(
              onPressed: isSession ? addStretches : () => session.addSet(e),
              icon: const Icon(Icons.add),
              label: Text(isSession ? 'Add stretch' : 'Add set'),
            ),
          ],
        ),
      ),
    );
  }
}

const _setW = 32.0, _prevW = 80.0, _rpeW = 40.0, _doneW = 44.0, _kgW = 56.0, _secW = 64.0;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.tracking, required this.showRpe});

  final TrackingType tracking;
  final bool showRpe;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).textTheme.labelSmall;
    Widget cell(String t) => Text(t, style: s, textAlign: TextAlign.center);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: _setW, child: cell('SET')),
          SizedBox(width: _prevW, child: cell('PREVIOUS')),
          if (tracking == TrackingType.duration) ...[
            Expanded(child: cell('+KG')),
            Expanded(child: cell('SECONDS')),
          ] else ...[
            Expanded(child: cell(tracking == TrackingType.bodyweightReps ? '+KG' : 'KG')),
            Expanded(child: cell('REPS')),
          ],
          if (showRpe) SizedBox(width: _rpeW, child: cell('RPE')),
          SizedBox(
            width: _doneW,
            child: SessionScope.of(context).templateMode ? null : const Icon(Icons.check, size: 16),
          ),
        ],
      ),
    );
  }
}

class _StretchHeaderRow extends StatelessWidget {
  const _StretchHeaderRow();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).textTheme.labelSmall;
    Widget cell(String t) => Text(t, style: s, textAlign: TextAlign.center);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: _setW, child: cell('#')),
          Expanded(child: Text('STRETCH', style: s)),
          SizedBox(width: _kgW, child: cell('+KG')),
          SizedBox(width: _secW, child: cell('SEC')),
          const SizedBox(width: _doneW, child: Icon(Icons.play_arrow, size: 16)),
        ],
      ),
    );
  }
}

/// One set: type label, previous values (tap to copy), inputs, RPE, done.
/// In a Stretching card: stretch name, optional assisting weight, seconds, ▶.
class SetRow extends StatefulWidget {
  const SetRow({super.key, required this.entry, required this.set, required this.index});

  final LoggedExercise entry;
  final LoggedSet set;
  final int index;

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late final _weight = TextEditingController(text: formatKg(widget.set.weightKg));
  late final _reps = TextEditingController(text: widget.set.reps?.toString() ?? '');
  late final _secs = TextEditingController(text: widget.set.durationS?.toString() ?? '');

  @override
  void didUpdateWidget(SetRow old) {
    super.didUpdateWidget(old);
    _sync(_weight, formatKg(widget.set.weightKg));
    _sync(_reps, widget.set.reps?.toString() ?? '');
    _sync(_secs, widget.set.durationS?.toString() ?? '');
  }

  /// Update a field from the model without fighting the user's typing.
  void _sync(TextEditingController c, String v) {
    if (c.text == v) return;
    final parsedSame = double.tryParse(c.text.replaceAll(',', '.')) == double.tryParse(v);
    if (!parsedSame) c.text = v;
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    _secs.dispose();
    super.dispose();
  }

  String _label() {
    final s = widget.set;
    if (s.subExercise != null) return '${widget.index + 1}';
    switch (s.type) {
      case SetType.warmup:
        return 'W';
      case SetType.drop:
        return 'D';
      case SetType.failure:
        return 'F';
      case SetType.normal:
        final sets = widget.entry.sets;
        return '${sets.take(widget.index + 1).where((x) => x.type == SetType.normal).length}';
    }
  }

  Color? _labelColor(BuildContext context) => switch (widget.set.type) {
    SetType.warmup => Colors.amber,
    SetType.drop => Colors.purple,
    SetType.failure => Colors.red,
    SetType.normal => null,
  };

  String _previousText(WorkoutSet? p) {
    if (p == null) return '—';
    final w = p.weightKg;
    if (widget.entry.exercise.trackingType == TrackingType.duration) {
      return (w == null || w == 0) ? '${p.durationS ?? 0} s' : '+${formatKg(w)} · ${p.durationS ?? 0}s';
    }
    final reps = p.reps ?? 0;
    return (w == null || w == 0) ? '$reps reps' : '${formatKg(w)} × $reps';
  }

  void _fillFromPrevious(WorkoutSet? p) {
    if (p == null) return;
    final session = SessionScope.of(context);
    if (p.weightKg != null) session.setWeight(widget.set, p.weightKg);
    if (p.reps != null) session.setReps(widget.set, p.reps);
    if (p.durationS != null) session.setDuration(widget.set, p.durationS);
    setState(() {
      _weight.text = formatKg(widget.set.weightKg);
      _reps.text = widget.set.reps?.toString() ?? '';
      _secs.text = widget.set.durationS?.toString() ?? '';
    });
  }

  /// ✓ for weight/reps sets. Timed sets get ▶ (start countdown) / ■ (stop).
  Widget _doneButton(WorkoutSession session, LoggedSet s, TrackingType tracking) {
    if (session.templateMode) return const SizedBox.shrink(); // planning, not doing
    if (s.done) {
      return IconButton(
        tooltip: 'Undo',
        icon: const Icon(Icons.check_box, color: Colors.green),
        onPressed: () => session.toggleDone(widget.entry, s),
      );
    }
    if (tracking == TrackingType.duration && !session.editMode) {
      final running = session.timer?.kind == TimerKind.setTimer && session.timer?.set == s;
      return IconButton(
        tooltip: running ? 'Stop' : 'Start timer',
        icon: Icon(running ? Icons.stop_circle : Icons.play_circle, color: timedColor(context)),
        onPressed: () {
          FocusScope.of(context).unfocus();
          running ? session.stopTimer() : session.startSetTimer(widget.entry, s);
        },
      );
    }
    return IconButton(
      icon: const Icon(Icons.check_box_outline_blank),
      onPressed: () {
        FocusScope.of(context).unfocus();
        session.toggleDone(widget.entry, s);
      },
    );
  }

  Future<void> _pickRpe() async {
    final session = SessionScope.of(context);
    const values = [6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0];
    final v = await showModalBottomSheet<double>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(title: Text('RPE (rate of perceived exertion)'), subtitle: Text('10 = nothing left')),
            for (final r in values) ListTile(title: Text(formatKg(r)), onTap: () => Navigator.pop(c, r)),
            ListTile(title: const Text('Clear'), onTap: () => Navigator.pop(c, -1)),
          ],
        ),
      ),
    );
    if (v == null) return;
    session.setRpe(widget.set, v < 0 ? null : v);
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final s = widget.set;
    final prev = widget.entry.previousFor(widget.index);
    final tracking = widget.entry.exercise.trackingType;
    final scheme = Theme.of(context).colorScheme;
    final running = session.timer?.kind == TimerKind.setTimer && session.timer?.set == s;

    Widget field(TextEditingController c, String hint, ValueChanged<String> onChanged, {bool decimal = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: TextField(
            controller: c,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,]' : r'[0-9]'))],
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: onChanged,
          ),
        );

    String hintOf(num? v) => v == null ? '' : (v is double ? formatKg(v) : '$v');
    Widget weightField(String hint) =>
        field(_weight, hint, (v) => session.setWeight(s, double.tryParse(v.replaceAll(',', '.'))), decimal: true);
    Widget secondsCell() => running
        ? Center(
            child: Text(
              '${session.timer!.remaining} s',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: timedColor(context)),
            ),
          )
        : field(
            _secs,
            hintOf(prev?.durationS ?? WorkoutSession.defaultSetSeconds),
            (v) => session.setDuration(s, int.tryParse(v)),
          );

    final sub = s.subExercise;
    final children = sub != null
        ? <Widget>[
            SizedBox(
              width: _setW,
              child: Text(
                _label(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: sub))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      ExerciseAvatar(exercise: sub, radius: 12),
                      const SizedBox(width: 6),
                      Expanded(child: Text(sub.name, maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: _kgW, child: weightField('')),
            SizedBox(width: _secW, child: secondsCell()),
            SizedBox(width: _doneW, child: _doneButton(session, s, TrackingType.duration)),
          ]
        : <Widget>[
            SizedBox(
              width: _setW,
              child: InkWell(
                // Set types (warm-up/drop/failure) are hidden for beginners.
                onTap: Services.of(context).level.value.showsAdvancedSetOptions ? () => session.cycleSetType(s) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _label(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: _labelColor(context)),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _prevW,
              child: InkWell(
                onTap: () => _fillFromPrevious(prev),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _previousText(prev),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              ),
            ),
            if (tracking == TrackingType.duration) ...[
              Expanded(child: weightField(hintOf(prev?.weightKg))),
              Expanded(child: secondsCell()),
            ] else ...[
              Expanded(child: weightField(hintOf(prev?.weightKg))),
              Expanded(child: field(_reps, hintOf(prev?.reps), (v) => session.setReps(s, int.tryParse(v)))),
            ],
            if (!widget.entry.exercise.isStretch && Services.of(context).level.value.showsAdvancedSetOptions)
              SizedBox(
                width: _rpeW,
                child: InkWell(
                  onTap: _pickRpe,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      s.rpe == null ? '–' : formatKg(s.rpe),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            SizedBox(width: _doneW, child: _doneButton(session, s, tracking)),
          ];

    return Container(
      color: s.done ? Colors.green.withValues(alpha: 0.18) : (running ? Colors.teal.withValues(alpha: 0.18) : null),
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: children),
    );
  }
}

/// Asks for a date and time (for logging or editing a past workout).
Future<DateTime?> pickWorkoutStart(BuildContext context, DateTime initial) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: initial.isAfter(now) ? now : initial,
    firstDate: DateTime(now.year - 5),
    lastDate: now,
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
