import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../beep/sounds.dart';
import '../data/database.dart';
import '../data/template_repository.dart';
import '../data/workout_repository.dart';
import '../data/exercise_repository.dart';
import '../hr/hr_monitor.dart';
import '../data/preset_repository.dart';
import '../hr/zones.dart';
import '../notify/rest_notifier.dart';

import 'active_workout.dart';
import 'interval_runner.dart';
import 'training_place.dart';
import 'stats.dart';

class WorkoutSummary {
  WorkoutSummary({required this.workout, required this.endedAt, required this.records, this.avgHr, this.maxHr});

  final ActiveWorkout workout;
  final DateTime endedAt;
  final List<PersonalRecord> records;
  final int? avgHr;
  final int? maxHr;

  Duration get duration => endedAt.difference(workout.startedAt);

  List<SetStat> get sets => [
    for (final e in workout.exercises)
      for (final s in e.sets)
        if (s.done)
          SetStat(
            exerciseId: (s.subExercise ?? e.exercise).id,
            type: s.type,
            weightKg: s.weightKg,
            reps: s.reps,
            durationS: s.durationS,
          ),
  ];

  double get volume => totalVolume(sets);

  /// A left + right pair counts as one set.
  int get setCount => workout.exercises.expand((e) => e.sets).where((s) => s.done && s.side != Side.right).length;

  /// Working sets per primary muscle (stretching rows count for their stretch).
  Map<String, int> get setsPerMuscle {
    final out = <String, int>{};
    for (final e in workout.exercises) {
      for (final s in e.sets) {
        if (!s.done || s.type == SetType.warmup) continue;
        out.update((s.subExercise ?? e.exercise).primaryMuscle, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return out;
  }

  String exerciseName(String id) {
    for (final e in workout.exercises) {
      if (e.exercise.id == id) return e.exercise.name;
      for (final s in e.sets) {
        if (s.subExercise?.id == id) return s.subExercise!.name;
      }
    }
    return '';
  }

  static Future<WorkoutSummary> build(
    WorkoutRepository repo,
    ActiveWorkout w,
    DateTime endedAt, {
    int? avgHr,
    int? maxHr,
  }) async {
    final summary = WorkoutSummary(workout: w, endedAt: endedAt, records: const [], avgHr: avgHr, maxHr: maxHr);
    final history = await repo.history(
      w.exercises.map((e) => e.exercise.id),
      excludeWorkoutId: w.id,
      before: w.startedAt,
    );
    return WorkoutSummary(
      workout: w,
      endedAt: endedAt,
      // Interval timers aren't lifts: no records for them.
      records: findRecords(
        current: summary.sets.where((s) => !s.exerciseId.startsWith(intervalExercisePrefix)).toList(),
        history: history,
      ),
      avgHr: avgHr,
      maxHr: maxHr,
    );
  }
}

enum TimerKind { rest, setTimer, countdown, stopwatch }

/// The one timer shown in the bottom bar of a workout.
class RunningTimer {
  RunningTimer({required this.kind, required this.total, this.exercise, this.set, this.switchSides = false})
    : startedAt = DateTime.now();

  /// The short pause between the left and right side of a timed hold.
  final bool switchSides;

  final TimerKind kind;
  final DateTime startedAt;

  /// Length in seconds (0 for a stopwatch).
  int total;
  final LoggedExercise? exercise;
  final LoggedSet? set;

  /// Set timer → rest → next timed set: continue automatically.
  bool chainNext = false;
  final Duration _paused = Duration.zero;

  int get elapsed => (DateTime.now().difference(startedAt) - _paused).inSeconds;

  int get remaining {
    final left = DateTime.now().difference(startedAt) - _paused;
    final ms = total * 1000 - left.inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  bool get countsDown => kind != TimerKind.stopwatch;

  String get label => switch (kind) {
    TimerKind.rest => switchSides ? 'Switch sides' : 'Rest',
    TimerKind.setTimer =>
      '${set?.subExercise?.name ?? exercise?.exercise.name ?? 'Set'}'
          '${set?.side == null ? '' : (set!.side == Side.left ? ' · left' : ' · right')}',
    TimerKind.countdown => 'Timer',
    TimerKind.stopwatch => 'Stopwatch',
  };
}

/// The workout currently being logged + the timers.
class WorkoutSession extends ChangeNotifier {
  WorkoutSession({
    required this.workouts,
    required this.exercises,
    required this.hr,
    bool editMode = false,
    this.templateMode = false,
  }) : editMode = editMode || templateMode;

  /// Editing a finished workout (or logging a past one), or a template: no
  /// timers, no auto-save – changes are written by [saveEdits] /
  /// [saveTemplate].
  final bool editMode;

  /// Building/editing a template in the workout view (no ✓ column).
  final bool templateMode;
  String? templateFolder;

  /// Loads a template (or a blank one) into the workout view for editing.
  Future<void> loadTemplate(TemplateWithSlots? t) async {
    _active = await _buildFromTemplate(t, name: t?.template.name ?? 'New template');
    templateFolder = t?.template.folder;
    _dirty = t == null;
    notifyListeners();
  }

  void setTemplateFolder(String? folder) {
    templateFolder = (folder == null || folder.trim().isEmpty) ? null : folder.trim();
    _changed();
  }

  /// Saves the template being edited. Returns its id.
  Future<String?> saveTemplate(TemplateRepository repo) async {
    final w = _active;
    if (w == null) return null;
    final id = await repo.save(
      id: w.templateId,
      name: w.name,
      folder: templateFolder,
      hrPresetId: w.hrPresetId,
      slots: [
        for (final e in w.exercises)
          TemplateSlot(
            exerciseId: e.exercise.id,
            targetSets: e.sets.length,
            restSeconds: e.restSeconds,
            supersetGroup: e.supersetGroup,
            subExerciseIds: [
              for (final s in e.sets)
                if (s.subExercise != null && s.side != Side.right) s.subExercise!.id,
            ],
            sets: e.exercise.isStretchSession
                ? const []
                : [
                    for (final s in e.sets)
                      TemplateSet(
                        type: s.type,
                        weightKg: s.weightKg,
                        reps: s.reps,
                        durationS: s.durationS,
                        side: s.side,
                      ),
                  ],
          ),
      ],
    );
    _dirty = false;
    return id;
  }

  DateTime? _editEndedAt;
  int? _editAvgHr, _editMaxHr;
  bool _dirty = false;

  /// True when an edit has unsaved changes.
  bool get hasUnsavedEdits => _dirty;
  DateTime? get editEndedAt => _editEndedAt;

  /// Loads a finished workout for editing.
  Future<bool> loadForEdit(String workoutId) async {
    final row = await workouts.workoutRow(workoutId);
    final w = await workouts.loadById(workoutId);
    if (row == null || w == null) return false;
    _active = w;
    _editEndedAt = row.endedAt ?? row.startedAt;
    _editAvgHr = row.avgHr;
    _editMaxHr = row.maxHr;
    _dirty = false;
    notifyListeners();
    return true;
  }

  /// Starts logging a workout that happened in the past.
  void startManual(DateTime start, Duration duration) {
    _active = ActiveWorkout(name: 'Workout', startedAt: start);
    _editEndedAt = start.add(duration);
    _dirty = true;
    notifyListeners();
  }

  /// Changes when an edited workout happened.
  void setTimes(DateTime start, Duration duration) {
    _active?.startedAt = start;
    _editEndedAt = start.add(duration);
    _changed();
  }

  /// Writes the edited workout. Sets with values count as done; empty ones are
  /// dropped. Returns the summary, or null if nothing was logged.
  Future<WorkoutSummary?> saveEdits() async {
    final w = _active;
    final end = _editEndedAt;
    if (w == null || end == null) return null;
    for (final e in w.exercises) {
      e.sets.removeWhere((s) => !s.done && s.weightKg == null && s.reps == null && s.durationS == null);
      for (final s in e.sets) {
        s.completedAt ??= end;
      }
    }
    w.exercises.removeWhere((e) => e.sets.isEmpty);
    if (w.exercises.isEmpty) return null;
    await workouts.save(w, endedAt: end, avgHr: _editAvgHr, maxHr: _editMaxHr);
    _dirty = false;
    return WorkoutSummary.build(workouts, w, end, avgHr: _editAvgHr, maxHr: _editMaxHr);
  }

  final WorkoutRepository workouts;
  final ExerciseRepository exercises;
  final HrMonitor hr;

  /// Default seconds of rest between sets (saved as a setting).
  int defaultRestSeconds = 90;

  /// Rest between stretches / timed holds.
  static const stretchRestSeconds = 10;

  /// Length of a timed set when nothing was entered.
  static const defaultSetSeconds = 30;

  /// Pause between the left and right side of a timed hold.
  static const switchSidesSeconds = 5;

  ActiveWorkout? _active;
  ActiveWorkout? get active => _active;

  Timer? _saveTimer;
  Timer? _ticker;
  RunningTimer? _timer;
  RunningTimer? get timer => _timer;

  /// Seconds left on the rest timer, or null when not resting.
  int? get restRemaining => _timer?.kind == TimerKind.rest ? _timer!.remaining : null;

  Future<void> restore() async {
    defaultRestSeconds = int.tryParse(await workouts.db.getSetting('defaultRestS') ?? '') ?? defaultRestSeconds;
    final placeName = await workouts.db.getSetting('workoutPlace');
    workoutPlace = TrainingPlace.values.where((p) => p.name == placeName).firstOrNull;
    _active = await workouts.loadActive();
    final w = _active;
    if (w != null) {
      // The app was closed mid-workout: turn the workout's heart-rate alerts
      // back on.
      final preset = zonesEnabled ? await presets?.byId(w.hrPresetId) : null;
      final last = w.lastChangeAt; // turning alerts back on is not a change
      if (preset != null && !hr.running) await applyPreset(preset);
      w.lastChangeAt = last;
      _syncIdleNotice();
    }
    notifyListeners();
  }

  /// While a workout timer runs, the audio session stays on, so the timer
  /// keeps counting and can beep with the screen locked. Only then: a silent
  /// running audio engine costs battery (the phone got warm in the first
  /// real workout).
  Future<void> _holdAudio() => hr.beeper.start('workout');

  void _releaseAudio() {
    // Give a final beep/ding time to play before the audio stops.
    if (_timer == null) hr.beeper.stop('workout', const Duration(seconds: 3));
  }

  int restFor(Exercise e) => e.isStretch ? stretchRestSeconds : defaultRestSeconds;

  /// Sets the default rest and applies it to every (non-stretch) exercise of
  /// the current workout.
  Future<void> setDefaultRest(int seconds) async {
    defaultRestSeconds = seconds;
    for (final e in _active?.exercises ?? const <LoggedExercise>[]) {
      if (!e.exercise.isStretch) e.restSeconds = seconds;
    }
    if (_active != null) _changed();
    notifyListeners();
    await workouts.db.setSetting('defaultRestS', '$seconds');
  }

  /// Heart-rate presets (set by AppServices; null in some tests).
  HrPresetRepository? presets;

  /// Interval timers (to run interval "exercises" inside a workout).
  IntervalPresetRepository? intervals;

  /// Heart-rate zones switched on (Tools › Heart-rate zones). Off: presets
  /// are never applied, so monitoring/beeps don't start by themselves.
  bool zonesEnabled = true;

  /// End of rest: a light vibration (setting `restVibrate`, default on) and,
  /// if turned on, a notification for when the phone is locked / in another
  /// app (setting `restNotify`).
  bool vibrateRestOver = true;
  bool notifyRestOver = false;
  RestNotifier? restNotifier;

  /// How many times rest ended with a vibration (for tests).
  int restVibrations = 0;

  void _restOver() {
    if (!vibrateRestOver) return;
    restVibrations++;
    try {
      HapticFeedback.lightImpact().catchError((Object _) {});
    } catch (_) {
      // No vibration available (tests).
    }
  }

  /// Schedules (or cancels) the "Rest is over" notification for the timer
  /// that is running now.
  void _syncRestNotice() {
    final t = _timer;
    final n = restNotifier;
    if (n == null) return;
    if (t != null && t.kind == TimerKind.rest && !t.switchSides && notifyRestOver && !editMode) {
      n.scheduleRestOver(Duration(milliseconds: t.remaining * 1000));
    } else {
      n.cancel();
    }
  }

  /// A workout with no change for this long counts as forgotten: a
  /// notification ("Still working out?") and, back in the app, a question.
  static const idleAfter = Duration(minutes: 90);

  /// Setting `idleReminder` (default on).
  bool idleReminder = true;

  String get idleReminderText => '${idleAfter.inMinutes} minutes';

  /// How long the running workout has had no change (zero while a timer runs).
  Duration get idleFor {
    final w = _active;
    if (w == null || editMode || _timer != null) return Duration.zero;
    return DateTime.now().difference(w.lastChangeAt);
  }

  /// "Keep going": the workout counts as active again.
  Future<void> keepGoing() async {
    _active?.lastChangeAt = DateTime.now();
    await _saveNow();
  }

  /// (Re)schedules the "Still working out?" notification for [idleAfter]
  /// after the last change.
  void _syncIdleNotice() {
    final n = restNotifier;
    final w = _active;
    if (n == null || editMode) return;
    if (w == null || !idleReminder) {
      n.cancelIdle();
      return;
    }
    final due = w.lastChangeAt.add(idleAfter).difference(DateTime.now());
    if (due > Duration.zero) {
      n.scheduleIdle(due, workout: w.name);
    } else {
      n.cancelIdle(); // already overdue: the app asks on screen
    }
  }

  /// Hybrid trainers pick the place when a workout starts: gym, home or
  /// outdoors. Filters the exercise list during that workout.
  TrainingPlace? workoutPlace;

  Future<void> setWorkoutPlace(TrainingPlace? p) async {
    workoutPlace = p;
    await workouts.db.setSetting('workoutPlace', p?.name ?? '');
  }

  Future<void> startEmpty({HrPreset? preset}) async {
    _active = ActiveWorkout(name: _defaultName());
    hr.resetSession();
    await applyPreset(preset);
    await _saveNow();
    notifyListeners();
  }

  Future<void> startFromTemplate(TemplateWithSlots t) async {
    _active = await _buildFromTemplate(t, name: t.template.name);
    hr.resetSession();
    // The template's heart-rate preset applies automatically.
    final preset = zonesEnabled ? await presets?.byId(t.template.hrPresetId) : null;
    if (preset != null) await applyPreset(preset);
    await _saveNow();
    notifyListeners();
  }

  /// Uses a heart-rate preset for this workout/template: sets the range and,
  /// in a live workout, starts monitoring (beeps). Null = no preset.
  Future<void> applyPreset(HrPreset? p) async {
    final w = _active;
    if (w == null) return;
    w.hrPresetId = p?.id;
    if (p != null && !templateMode && !editMode) {
      hr.setRange(HrRange(min: p.minBpm, max: p.maxBpm));
      if (!hr.running) await hr.start();
    }
    _changed();
  }

  /// Workout (or template draft) from a template: planned sets keep their
  /// target values; old templates without them get empty sets.
  Future<ActiveWorkout> _buildFromTemplate(TemplateWithSlots? t, {required String name}) async {
    // A starter program workout started directly has no saved template (id '').
    final templateId = (t == null || t.template.id.isEmpty) ? null : t.template.id;
    final w = ActiveWorkout(name: name, templateId: templateId)..hrPresetId = t?.template.hrPresetId;
    for (final slot in t?.slots ?? const <TemplateSlot>[]) {
      final ex = await exercises.byId(slot.exerciseId);
      if (ex == null) continue;
      final le = LoggedExercise(exercise: ex, restSeconds: slot.restSeconds, supersetGroup: slot.supersetGroup);
      if (ex.isStretchSession) {
        for (final id in slot.subExerciseIds) {
          final stretch = await exercises.byId(id);
          if (stretch != null) _addStretchRows(le, [stretch]);
        }
        w.exercises.add(le);
        continue;
      }
      le.previous = await workouts.previousSets(ex.id);
      if (slot.sets.isNotEmpty) {
        for (final ts in slot.sets) {
          le.sets.add(
            LoggedSet(type: ts.type, weightKg: ts.weightKg, reps: ts.reps, durationS: ts.durationS)..side = ts.side,
          );
        }
      } else {
        for (var i = 0; i < slot.targetSets; i++) {
          final prev = le.previousFor(i);
          le.sets.add(LoggedSet(type: prev?.setType ?? SetType.normal));
        }
      }
      _matchSides(le);
      w.exercises.add(le);
    }
    return w;
  }

  /// Starts a new workout now with the exercises and values of an old one
  /// (as targets, not ticked).
  Future<bool> startFromWorkout(String workoutId) async {
    final old = await workouts.loadById(workoutId);
    if (old == null) return false;
    final w = ActiveWorkout(name: old.name)..hrPresetId = zonesEnabled ? old.hrPresetId : null;
    for (final e in old.exercises) {
      final le = LoggedExercise(exercise: e.exercise, restSeconds: e.restSeconds, supersetGroup: e.supersetGroup)
        ..notes = e.notes;
      le.previous = e.exercise.isStretchSession ? const [] : await workouts.previousSets(e.exercise.id);
      for (final s in e.sets) {
        le.sets.add(s.copy());
      }
      w.exercises.add(le);
    }
    _active = w;
    hr.resetSession();
    final preset = await presets?.byId(w.hrPresetId);
    if (preset != null) await applyPreset(preset);
    await _saveNow();
    notifyListeners();
    return true;
  }

  /// Template slots for an old workout (Save as template).
  static List<TemplateSlot> slotsFrom(ActiveWorkout w) => [
    for (final e in w.exercises)
      TemplateSlot(
        exerciseId: e.exercise.id,
        targetSets: e.sets.length,
        restSeconds: e.restSeconds,
        supersetGroup: e.supersetGroup,
        subExerciseIds: [
          for (final s in e.sets)
            if (s.subExercise != null && s.side != Side.right) s.subExercise!.id,
        ],
        sets: e.exercise.isStretchSession
            ? const []
            : [
                for (final s in e.sets)
                  TemplateSet(type: s.type, weightKg: s.weightKg, reps: s.reps, durationS: s.durationS, side: s.side),
              ],
      ),
  ];

  static String _defaultName() {
    final h = DateTime.now().hour;
    final part = h < 12 ? 'Morning' : (h < 17 ? 'Afternoon' : 'Evening');
    return '$part workout';
  }

  /// Adds exercises. Stretches are grouped into one "Stretching" card (rows =
  /// stretches), added to the last Stretching card if it is the last exercise.
  Future<void> addExercises(List<Exercise> list) async {
    final w = _active;
    if (w == null) return;
    final stretches = list.where((e) => e.isStretch && !e.isStretchSession).toList();
    if (stretches.isNotEmpty) {
      final session = await exercises.byId(stretchingSessionId);
      if (session != null) {
        var card = w.exercises.lastOrNull;
        if (card == null || !card.exercise.isStretchSession) {
          card = LoggedExercise(exercise: session, restSeconds: stretchRestSeconds);
          w.exercises.add(card);
        }
        _addStretchRows(card, stretches);
        list = list.where((e) => !stretches.contains(e)).toList();
      }
    }
    for (final ex in list) {
      final le = LoggedExercise(exercise: ex, restSeconds: restFor(ex));
      if (ex.isInterval) {
        // One round of the interval timer; ▶ runs it.
        final p = await intervals?.byId(ex.intervalPresetId!);
        final secs = p == null ? null : totalSeconds(decodeSegments(p.segmentsJson), p.rounds);
        le.sets.add(LoggedSet(durationS: secs));
        w.exercises.add(le);
        continue;
      }
      le.previous = await workouts.previousSets(ex.id, excludeWorkoutId: w.id);
      le.sets.add(LoggedSet(type: le.previousFor(0)?.setType ?? SetType.normal));
      _matchSides(le);
      w.exercises.add(le);
    }
    _changed();
  }

  /// One-sided exercises log every set as a left + right pair; others don't
  /// split. Converts the sets of [e] to match its exercise's setting.
  void _matchSides(LoggedExercise e) {
    if (e.exercise.isStretchSession) return;
    final split = e.exercise.unilateral;
    final hasSides = e.sets.any((s) => s.side != null);
    if (split && !hasSides) {
      final out = <LoggedSet>[];
      for (final s in e.sets) {
        out
          ..add(s..side = Side.left)
          ..add(s.copy(side: Side.right)..completedAt = s.completedAt);
      }
      e.sets
        ..clear()
        ..addAll(out);
    } else if (!split && hasSides) {
      e.sets.removeWhere((s) => s.side == Side.right);
      for (final s in e.sets) {
        s.side = null;
      }
    }
  }

  /// "Each side" on/off for an exercise (saved for future workouts too). Its
  /// sets become left/right pairs, or single sets again.
  Future<void> setUnilateral(LoggedExercise e, bool on) async {
    e.exercise = await exercises.setUnilateral(e.exercise.id, on);
    _matchSides(e);
    _changed();
  }

  /// Writes the permanent note of [e]'s exercise (dated today).
  Future<void> setExerciseNote(LoggedExercise e, String text) async {
    e.exercise = await exercises.setNote(e.exercise.id, text);
    e.noteHidden = false;
    notifyListeners();
  }

  /// Note on [e] for this workout only.
  void setWorkoutNote(LoggedExercise e, String text) {
    e.notes = text.trim();
    _changed();
  }

  void hideNote(LoggedExercise e) {
    e.noteHidden = true;
    notifyListeners();
  }

  /// Adds stretches as rows of a "Stretching" card.
  void addStretches(LoggedExercise card, List<Exercise> stretches) {
    _addStretchRows(card, stretches);
    _changed();
  }

  void _addStretchRows(LoggedExercise card, List<Exercise> stretches) {
    for (final s in stretches) {
      final row = LoggedSet(durationS: defaultSetSeconds)..subExercise = s;
      if (s.unilateral) {
        // One stretch, both sides: left then right.
        card.sets
          ..add(row..side = Side.left)
          ..add(row.copy(side: Side.right));
      } else {
        card.sets.add(row);
      }
    }
  }

  void removeExercise(LoggedExercise e) {
    if (_timer?.exercise == e) stopTimer();
    _active?.exercises.remove(e);
    _changed();
  }

  /// [to] is the final index (already adjusted for the removed item).
  void moveExercise(int from, int to) {
    final list = _active?.exercises;
    if (list == null || from == to) return;
    final e = list.removeAt(from);
    list.insert(to.clamp(0, list.length), e);
    _changed();
  }

  /// Replaces the exercise of [e] (keeps the sets; "previous" comes from the
  /// new exercise).
  Future<void> swapExercise(LoggedExercise e, Exercise next) async {
    final w = _active;
    if (w == null) return;
    e.exercise = next;
    e.previous = await workouts.previousSets(next.id, excludeWorkoutId: w.id);
    _changed();
  }

  /// Changes how [e] is logged; also saved for future workouts.
  Future<void> setTrackingType(LoggedExercise e, TrackingType type) async {
    e.exercise = await exercises.setTrackingType(e.exercise.id, type);
    _changed();
  }

  /// Links [e] with the next exercise as a superset (or unlinks it).
  void toggleSupersetWithNext(LoggedExercise e) {
    final list = _active?.exercises;
    if (list == null) return;
    final i = list.indexOf(e);
    if (i < 0 || i + 1 >= list.length) return;
    final next = list[i + 1];
    if (e.supersetGroup != null && e.supersetGroup == next.supersetGroup) {
      next.supersetGroup = null;
      if (i == 0 || list[i - 1].supersetGroup != e.supersetGroup) e.supersetGroup = null;
    } else {
      final group = e.supersetGroup ?? (list.map((x) => x.supersetGroup ?? 0).fold(0, (a, b) => a > b ? a : b) + 1);
      e.supersetGroup = group;
      next.supersetGroup = group;
    }
    _changed();
  }

  void addSet(LoggedExercise e) {
    final last = e.sets.lastOrNull;
    if (last?.side != null && !e.exercise.isStretchSession) {
      // One-sided: add another left + right pair like the last one.
      final left = e.sets.lastWhere((s) => s.side == Side.left, orElse: () => last!);
      final type = last!.type == SetType.warmup ? SetType.normal : last.type;
      e.sets
        ..add(left.copy(side: Side.left)..type = type)
        ..add(last.copy(side: Side.right)..type = type);
      _changed();
      return;
    }
    e.sets.add(
      LoggedSet(
        type: last?.type == SetType.warmup ? SetType.normal : (last?.type ?? SetType.normal),
        weightKg: last?.weightKg,
        reps: last?.reps,
        durationS: last?.durationS,
      )..subExercise = last?.subExercise,
    );
    _changed();
  }

  void removeSet(LoggedExercise e, LoggedSet s) {
    // A side never stays alone: removing left or right removes the pair.
    final i = e.sets.indexOf(s);
    final partner = switch (s.side) {
      Side.left when i + 1 < e.sets.length && e.sets[i + 1].side == Side.right => e.sets[i + 1],
      Side.right when i > 0 && e.sets[i - 1].side == Side.left => e.sets[i - 1],
      _ => null,
    };
    for (final x in [s, ?partner]) {
      if (_timer?.set == x) stopTimer();
      e.sets.remove(x);
    }
    _changed();
  }

  /// Sets the weight of [s] and copies it to the following sets of the same
  /// exercise that aren't done yet – if they are empty or still hold the old
  /// value (so a pyramid typed by hand isn't overwritten). Warm-up sets only
  /// copy to warm-up sets, working sets to working sets.
  void setWeight(LoggedSet s, double? v) {
    final old = s.weightKg;
    s.weightKg = v;
    var copied = false;
    final e = _active?.exercises.where((x) => x.sets.contains(s)).firstOrNull;
    if (e != null && !e.exercise.isStretchSession) {
      final warm = s.type == SetType.warmup;
      for (final x in e.sets.skip(e.sets.indexOf(s) + 1)) {
        if (x.done || (x.type == SetType.warmup) != warm) continue;
        if (x.weightKg == null || x.weightKg == old) {
          if (x.weightKg != v) copied = true;
          x.weightKg = v;
        }
      }
    }
    // Rebuild only when other rows changed (not on every keystroke).
    _changed(notify: copied);
  }

  void setReps(LoggedSet s, int? v) {
    s.reps = v;
    _changed(notify: false);
  }

  void setDuration(LoggedSet s, int? v) {
    s.durationS = v;
    _changed(notify: false);
  }

  void setRpe(LoggedSet s, double? v) {
    s.rpe = v;
    _changed();
  }

  /// Tap order of the set types: number → F → W → D → number. (The stored
  /// enum order is different and must not change.)
  static const setTypeCycle = [SetType.normal, SetType.failure, SetType.warmup, SetType.drop];

  void cycleSetType(LoggedSet s) {
    s.type = setTypeCycle[(setTypeCycle.indexOf(s.type) + 1) % setTypeCycle.length];
    _changed();
  }

  void setSetType(LoggedSet s, SetType type) {
    s.type = type;
    _changed();
  }

  /// True when the done set [s] beats everything logged for its exercise
  /// before (heavier, more reps or a longer hold). Never on an exercise's
  /// first workout – same rule as the summary's records.
  Future<bool> isRecord(LoggedExercise e, LoggedSet s) async {
    final w = _active;
    if (w == null || !s.done || s.type == SetType.warmup) return false;
    final id = (s.subExercise ?? e.exercise).id;
    final history = await workouts.history([id], excludeWorkoutId: w.id);
    if (history.isEmpty) return false;
    final working = history.where((h) => h.type != SetType.warmup);
    double best(double? Function(SetStat) f) => working.map(f).whereType<double>().fold(0.0, (a, b) => a > b ? a : b);
    switch (e.exercise.trackingType) {
      case TrackingType.duration:
        return (s.durationS ?? 0) > best((h) => h.durationS?.toDouble());
      case TrackingType.bodyweightReps || TrackingType.distance:
        return (s.reps ?? 0) > best((h) => h.reps?.toDouble());
      case TrackingType.weightReps:
        final kg = s.weightKg ?? 0;
        final heavier = kg > 0 && kg > best((h) => h.weightKg);
        final e1rm = (s.reps ?? 0) > 0 ? estimated1RM(kg, s.reps!) : 0.0;
        final stronger =
            e1rm > 0 && e1rm > best((h) => (h.reps ?? 0) > 0 ? estimated1RM(h.weightKg ?? 0, h.reps!) : null);
        return heavier || stronger;
    }
  }

  /// Ticks a set done (fills empty values from the previous workout) and
  /// starts the rest timer; ticking again un-does it.
  void toggleDone(LoggedExercise e, LoggedSet s) {
    if (s.done) {
      s.completedAt = null;
      s.maxHr = null;
    } else {
      if (_timer?.set == s) _timer = null;
      final prev = e.previousFor(e.sets.indexOf(s));
      s.weightKg ??= prev?.weightKg;
      s.reps ??= prev?.reps;
      s.durationS ??= prev?.durationS;
      _complete(e, s);
    }
    _changed();
  }

  void _complete(LoggedExercise e, LoggedSet s, {bool chain = false}) {
    if (editMode) {
      s.completedAt = _editEndedAt ?? DateTime.now();
      return;
    }
    s.completedAt = DateTime.now();
    s.maxHr = hr.takeIntervalMax();
    // In a superset, rest only after the last exercise of the group.
    final list = _active!.exercises;
    final i = list.indexOf(e);
    final inSupersetBeforeEnd =
        e.supersetGroup != null && i + 1 < list.length && list[i + 1].supersetGroup == e.supersetGroup;
    if (inSupersetBeforeEnd) {
      if (chain) _startNextTimedSet(e);
      return;
    }
    // Left side done: the right side comes next – no rest. Timed holds get a
    // short "switch sides" pause, then the right side starts by itself.
    final idx = e.sets.indexOf(s);
    if (s.side == Side.left && idx + 1 < e.sets.length && e.sets[idx + 1].side == Side.right) {
      if (chain) {
        _start(RunningTimer(kind: TimerKind.rest, total: switchSidesSeconds, switchSides: true)..chainNext = true);
        _restChainFrom = e;
      }
      return;
    }
    if (e.restSeconds > 0) {
      _start(RunningTimer(kind: TimerKind.rest, total: e.restSeconds)..chainNext = chain);
      _restChainFrom = chain ? e : null;
    } else if (chain) {
      _startNextTimedSet(e);
    }
  }

  LoggedExercise? _restChainFrom;

  void setRestSeconds(LoggedExercise e, int seconds) {
    e.restSeconds = seconds;
    _changed();
  }

  /// An interval timer in the workout ran to the end: the round counts as
  /// done and the normal rest starts.
  void completeInterval(LoggedExercise e, LoggedSet s, {required int seconds}) {
    s.durationS = seconds;
    _complete(e, s);
    _changed();
  }

  // ---- Timers ---------------------------------------------------------------

  void startRest(int seconds) {
    if (seconds <= 0) return;
    _start(RunningTimer(kind: TimerKind.rest, total: seconds));
  }

  /// Counts down a timed set (stretch, plank…). When it ends the set is
  /// marked done, rest runs, and the next timed set starts automatically.
  void startSetTimer(LoggedExercise e, LoggedSet s) {
    final prev = e.previousFor(e.sets.indexOf(s));
    final seconds = s.durationS ?? prev?.durationS ?? defaultSetSeconds;
    s.durationS = seconds;
    _start(RunningTimer(kind: TimerKind.setTimer, total: seconds, exercise: e, set: s));
    _changed();
  }

  void startCountdown(int seconds) => _start(RunningTimer(kind: TimerKind.countdown, total: seconds));

  void startStopwatch() => _start(RunningTimer(kind: TimerKind.stopwatch, total: 0));

  /// Stops the bottom-bar timer. A running set timer counts as done with the
  /// time held so far.
  void stopTimer() {
    final t = _timer;
    _timer = null;
    _ticker?.cancel();
    _releaseAudio();
    _syncRestNotice();
    _restChainFrom = null;
    if (t != null && t.kind == TimerKind.setTimer && t.exercise != null && t.set != null) {
      final held = t.elapsed;
      if (held > 0 && _active?.exercises.contains(t.exercise) == true) {
        t.set!.durationS = held;
        _complete(t.exercise!, t.set!);
        _changed();
      }
    }
    notifyListeners();
  }

  /// Kept for older call sites/tests.
  void skipRest() => stopTimer();

  void adjustTimer(int delta) {
    final t = _timer;
    if (t == null || !t.countsDown) return;
    t.total = (t.total + delta).clamp(1, 3600);
    _syncRestNotice();
    notifyListeners();
  }

  void adjustRest(int delta) => adjustTimer(delta);

  void _start(RunningTimer t) {
    if (editMode) return; // no timers while editing a past workout
    _holdAudio();
    _timer = t;
    _syncRestNotice();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    notifyListeners();
  }

  /// Seconds shown by the running timer; changes once per second. Listen to
  /// this (not the session) for clock displays.
  final ticks = ValueNotifier<int>(0);

  void _tick() {
    final t = _timer;
    if (t == null) {
      _ticker?.cancel();
      return;
    }
    if (!t.countsDown || t.remaining > 0) {
      // Just time passing: only the clock widgets need to repaint (once per
      // second), not the whole workout screen – that made scrolling jerky.
      final shown = t.countsDown ? t.remaining : t.elapsed;
      if (shown != ticks.value) ticks.value = shown;
      return;
    }
    {
      _ticker?.cancel();
      _timer = null;
      _releaseAudio(); // kept if the next timer starts right away
      switch (t.kind) {
        case TimerKind.setTimer:
          hr.beeper.play(SoundEvent.setTimerOver);
          if (t.exercise != null && t.set != null && _active?.exercises.contains(t.exercise) == true) {
            _complete(t.exercise!, t.set!, chain: true);
            _changed();
          }
        case TimerKind.rest:
          // Rest is over – a bell, not a beep. "Switch sides" gets a short beep.
          hr.beeper.play(t.switchSides ? SoundEvent.switchSides : SoundEvent.restOver);
          if (!t.switchSides) _restOver();

          final from = _restChainFrom;
          _restChainFrom = null;
          if (t.chainNext && from != null) _startNextTimedSet(from);
        case TimerKind.countdown:
          hr.beeper.play(SoundEvent.countdownOver);
        case TimerKind.stopwatch:
          break;
      }
    }
    notifyListeners();
  }

  /// Next undone set of [e], or the first undone set of the following
  /// exercise if that one is timed too.
  void _startNextTimedSet(LoggedExercise e) {
    final next = _nextTimedSet(e);
    if (next != null) startSetTimer(next.$1, next.$2);
  }

  (LoggedExercise, LoggedSet)? _nextTimedSet(LoggedExercise e, {LoggedSet? skip}) {
    final list = _active?.exercises;
    if (list == null || !list.contains(e)) return null;
    final candidates = [e, if (list.indexOf(e) + 1 < list.length) list[list.indexOf(e) + 1]];
    for (final x in candidates) {
      // Interval timers are started by hand (▶ opens the full-screen timer).
      if (!x.exercise.isTimed || x.exercise.isInterval) continue;
      final next = x.sets.where((s) => !s.done && s != skip).firstOrNull;
      if (next != null) return (x, next);
    }
    return null;
  }

  /// What starts next in a timed chain (shown as "Next: …"), if anything.
  String? get nextUpLabel {
    final t = _timer;
    if (t == null) return null;
    final (LoggedExercise, LoggedSet)? next = switch (t.kind) {
      TimerKind.setTimer when t.exercise != null => _nextTimedSet(t.exercise!, skip: t.set),
      TimerKind.rest when t.chainNext && _restChainFrom != null => _nextTimedSet(_restChainFrom!),
      _ => null,
    };
    if (next == null) return null;
    return (next.$2.subExercise ?? next.$1.exercise).name;
  }

  /// Share of sets ticked done (0–1).
  double get progress {
    final all = _active?.exercises.expand((e) => e.sets).toList() ?? const [];
    if (all.isEmpty) return 0;
    return all.where((s) => s.done).length / all.length;
  }

  // ---------------------------------------------------------------------------

  void rename(String name) {
    _active?.name = name;
    _changed();
  }

  /// Finishes the workout. Uncompleted sets are dropped.
  /// When the last set was ticked (for workouts left open far too long).
  DateTime? get lastSetAt {
    DateTime? last;
    for (final s in _active?.completedSets ?? const <LoggedSet>[]) {
      if (last == null || s.completedAt!.isAfter(last)) last = s.completedAt;
    }
    return last;
  }

  /// Finishes the workout. Uncompleted sets are dropped. [endedAt] overrides
  /// "now" (e.g. the last set's time when the workout was left open).
  Future<WorkoutSummary?> finish({DateTime? endedAt}) async {
    final w = _active;
    // A second tap on Finish while the first is still saving does nothing.
    if (w == null || _finishing) return null;
    _finishing = true;
    try {
      return await _finish(w, endedAt);
    } finally {
      _finishing = false;
    }
  }

  bool _finishing = false;

  Future<WorkoutSummary> _finish(ActiveWorkout w, DateTime? endedAt) async {
    _timer = null;
    _ticker?.cancel();
    _syncRestNotice();
    for (final e in w.exercises) {
      e.sets.removeWhere((s) => !s.done);
    }
    w.exercises.removeWhere((e) => e.sets.isEmpty);
    final end = endedAt ?? DateTime.now();
    final avg = hr.sessionAvg, max = hr.sessionMax;
    _saveTimer?.cancel();
    await workouts.save(w, endedAt: end, avgHr: avg, maxHr: max);
    final summary = await WorkoutSummary.build(workouts, w, end, avgHr: avg, maxHr: max);
    _active = null;
    restNotifier?.cancelIdle();
    _releaseAudio();
    notifyListeners();
    return summary;
  }

  Future<void> discard() async {
    final w = _active;
    if (w == null) return;
    if (editMode) {
      // Nothing was written yet: just forget the changes.
      _active = null;
      _dirty = false;
      notifyListeners();
      return;
    }
    _timer = null;
    _ticker?.cancel();
    _syncRestNotice();
    _saveTimer?.cancel();
    await workouts.delete(w.id);
    _active = null;
    restNotifier?.cancelIdle();
    _releaseAudio();
    notifyListeners();
  }

  void _changed({bool notify = true}) {
    if (editMode) {
      _dirty = true;
      if (notify) notifyListeners();
      return;
    }
    _active?.lastChangeAt = DateTime.now();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _saveNow);
    if (notify) notifyListeners();
  }

  Future<void> _saveNow() async {
    final w = _active;
    if (w != null) await workouts.save(w);
    _syncIdleNotice(); // debounced like the save: not on every keystroke
  }

  /// Saves pending changes immediately (e.g. in tests or when backgrounding).
  Future<void> flush() async {
    _saveTimer?.cancel();
    await _saveNow();
  }

  @override
  void dispose() {
    ticks.dispose();
    _saveTimer?.cancel();
    _ticker?.cancel();
    super.dispose();
  }
}
