import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../hr/hr_monitor.dart';
import '../../workout/active_workout.dart';
import '../../workout/stats.dart';
import '../../workout/workout_session.dart';
import '../exercises/exercise_detail_screen.dart';
import '../exercises/exercise_library_screen.dart';
import '../templates/template_editor_screen.dart';
import '../zone_colors.dart';
import 'workout_summary_screen.dart';

const _supersetColors = [Colors.purpleAccent, Colors.tealAccent, Colors.amberAccent, Colors.pinkAccent];

class ActiveWorkoutScreen extends StatelessWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Services.of(context).session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final w = session.active;
        if (w == null) return const Scaffold(body: Center(child: Text('No workout in progress')));
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Minimise',
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: GestureDetector(
              onTap: () => _rename(context, session, w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.name, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                  _ElapsedText(since: w.startedAt),
                ],
              ),
            ),
            actions: [
              const _HrChip(),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(onPressed: () => _finish(context, session), child: const Text('Finish')),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              for (final (i, e) in w.exercises.indexed) _ExerciseCard(key: ValueKey(e.id), index: i, entry: e),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add exercises'),
                  onPressed: () async {
                    final picked = await ExerciseLibraryScreen.pick(context);
                    if (picked != null) await session.addExercises(picked);
                  },
                ),
              ),
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
          bottomNavigationBar: session.restRemaining == null ? null : _RestBar(session: session),
        );
      },
    );
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
    final summary = await session.finish();
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
  Widget build(BuildContext context) =>
      Text(formatDuration(DateTime.now().difference(widget.since)), style: Theme.of(context).textTheme.bodySmall);
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
      label: Text(m.running ? (m.bpm?.toString() ?? '--') : 'HR off'),
      onPressed: m.running ? m.stop : m.start,
    );
  }
}

class _RestBar extends StatelessWidget {
  const _RestBar({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final left = session.restRemaining ?? 0;
    final total = session.restTotal;
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: total == 0 ? 0 : left / total),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'Rest ${formatDuration(Duration(seconds: left))}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(onPressed: () => session.adjustRest(-15), child: const Text('−15')),
                  TextButton(onPressed: () => session.adjustRest(15), child: const Text('+15')),
                  FilledButton(onPressed: session.skipRest, child: const Text('Skip')),
                ],
              ),
            ),
          ],
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
    final session = Services.of(context).session;
    final e = entry;
    final tracking = e.exercise.trackingType;
    final text = Theme.of(context).textTheme;
    final group = e.supersetGroup;
    final list = session.active!.exercises;
    final linkedToNext = group != null && index + 1 < list.length && list[index + 1].supersetGroup == group;

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
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: e.exercise))),
                    child: Text(
                      e.exercise.name,
                      style: text.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
                if (group != null) Text('Superset', style: text.labelSmall),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    switch (v) {
                      case 'rest':
                        final r = await pickRestSeconds(context, e.restSeconds);
                        if (r != null) session.setRestSeconds(e, r);
                      case 'superset':
                        session.toggleSupersetWithNext(e);
                      case 'up':
                        session.moveExercise(index, index - 1);
                      case 'down':
                        session.moveExercise(index, index + 1);
                      case 'remove':
                        session.removeExercise(e);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'rest', child: Text('Rest timer (${e.restSeconds} s)')),
                    if (index + 1 < list.length)
                      PopupMenuItem(
                        value: 'superset',
                        child: Text(linkedToNext ? 'Remove superset with next' : 'Superset with next'),
                      ),
                    if (index > 0) const PopupMenuItem(value: 'up', child: Text('Move up')),
                    if (index + 1 < list.length) const PopupMenuItem(value: 'down', child: Text('Move down')),
                    const PopupMenuItem(value: 'remove', child: Text('Remove exercise')),
                  ],
                ),
              ],
            ),
            _HeaderRow(tracking: tracking),
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
              onPressed: () => session.addSet(e),
              icon: const Icon(Icons.add),
              label: const Text('Add set'),
            ),
          ],
        ),
      ),
    );
  }
}

const _setW = 36.0, _prevW = 84.0, _rpeW = 44.0, _doneW = 44.0;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.tracking});

  final TrackingType tracking;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).textTheme.labelSmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: _setW,
            child: Text('SET', style: s, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: _prevW,
            child: Text('PREVIOUS', style: s, textAlign: TextAlign.center),
          ),
          if (tracking == TrackingType.duration)
            Expanded(
              child: Text('SECONDS', style: s, textAlign: TextAlign.center),
            )
          else ...[
            Expanded(
              child: Text(
                tracking == TrackingType.bodyweightReps ? '+KG' : 'KG',
                style: s,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text('REPS', style: s, textAlign: TextAlign.center),
            ),
          ],
          SizedBox(
            width: _rpeW,
            child: Text('RPE', style: s, textAlign: TextAlign.center),
          ),
          const SizedBox(width: _doneW, child: Icon(Icons.check, size: 16)),
        ],
      ),
    );
  }
}

/// One set: type label, previous values (tap to copy), inputs, RPE, done.
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
    SetType.drop => Colors.purpleAccent,
    SetType.failure => Colors.redAccent,
    SetType.normal => null,
  };

  String _previousText(WorkoutSet? p) {
    if (p == null) return '—';
    if (widget.entry.exercise.trackingType == TrackingType.duration) return '${p.durationS ?? 0} s';
    final w = p.weightKg;
    final reps = p.reps ?? 0;
    return (w == null || w == 0) ? '$reps reps' : '${formatKg(w)} × $reps';
  }

  void _fillFromPrevious(WorkoutSet? p) {
    if (p == null) return;
    final session = Services.of(context).session;
    if (p.weightKg != null) session.setWeight(widget.set, p.weightKg);
    if (p.reps != null) session.setReps(widget.set, p.reps);
    if (p.durationS != null) session.setDuration(widget.set, p.durationS);
    setState(() {
      _weight.text = formatKg(widget.set.weightKg);
      _reps.text = widget.set.reps?.toString() ?? '';
      _secs.text = widget.set.durationS?.toString() ?? '';
    });
  }

  Future<void> _pickRpe() async {
    final session = Services.of(context).session;
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
    final session = Services.of(context).session;
    final s = widget.set;
    final prev = widget.entry.previousFor(widget.index);
    final tracking = widget.entry.exercise.trackingType;
    final scheme = Theme.of(context).colorScheme;

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

    return Container(
      color: s.done ? Colors.green.withValues(alpha: 0.18) : null,
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: _setW,
            child: InkWell(
              onTap: () => session.cycleSetType(s),
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
          if (tracking == TrackingType.duration)
            Expanded(child: field(_secs, hintOf(prev?.durationS), (v) => session.setDuration(s, int.tryParse(v))))
          else ...[
            Expanded(
              child: field(
                _weight,
                hintOf(prev?.weightKg),
                (v) => session.setWeight(s, double.tryParse(v.replaceAll(',', '.'))),
                decimal: true,
              ),
            ),
            Expanded(child: field(_reps, hintOf(prev?.reps), (v) => session.setReps(s, int.tryParse(v)))),
          ],
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
          SizedBox(
            width: _doneW,
            child: IconButton(
              icon: Icon(s.done ? Icons.check_box : Icons.check_box_outline_blank, color: s.done ? Colors.green : null),
              onPressed: () {
                FocusScope.of(context).unfocus();
                session.toggleDone(widget.entry, s);
              },
            ),
          ),
        ],
      ),
    );
  }
}
