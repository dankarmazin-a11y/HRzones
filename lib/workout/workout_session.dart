import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../data/template_repository.dart';
import '../data/workout_repository.dart';
import '../data/exercise_repository.dart';
import '../hr/hr_monitor.dart';
import 'active_workout.dart';
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
  int get setCount => sets.length;

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
      records: findRecords(current: summary.sets, history: history),
      avgHr: avgHr,
      maxHr: maxHr,
    );
  }
}

enum TimerKind { rest, setTimer, countdown, stopwatch }

/// The one timer shown in the bottom bar of a workout.
class RunningTimer {
  RunningTimer({required this.kind, required this.total, this.exercise, this.set}) : startedAt = DateTime.now();

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
    TimerKind.rest => 'Rest',
    TimerKind.setTimer => set?.subExercise?.name ?? exercise?.exercise.name ?? 'Set',
    TimerKind.countdown => 'Timer',
    TimerKind.stopwatch => 'Stopwatch',
  };
}

/// The workout currently being logged + the timers.
class WorkoutSession extends ChangeNotifier {
  WorkoutSession({required this.workouts, required this.exercises, required this.hr});

  final WorkoutRepository workouts;
  final ExerciseRepository exercises;
  final HrMonitor hr;

  /// Default seconds of rest between sets (saved as a setting).
  int defaultRestSeconds = 90;

  /// Rest between stretches / timed holds.
  static const stretchRestSeconds = 10;

  /// Length of a timed set when nothing was entered.
  static const defaultSetSeconds = 30;

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
    _active = await workouts.loadActive();
    notifyListeners();
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

  Future<void> startEmpty() async {
    _active = ActiveWorkout(name: _defaultName());
    hr.resetSession();
    await _saveNow();
    notifyListeners();
  }

  Future<void> startFromTemplate(TemplateWithSlots t) async {
    final w = ActiveWorkout(name: t.template.name, templateId: t.template.id);
    for (final slot in t.slots) {
      final ex = await exercises.byId(slot.exerciseId);
      if (ex == null) continue;
      final le = LoggedExercise(exercise: ex, restSeconds: slot.restSeconds, supersetGroup: slot.supersetGroup);
      if (ex.isStretchSession) {
        for (final id in slot.subExerciseIds) {
          final stretch = await exercises.byId(id);
          if (stretch != null) le.sets.add(LoggedSet(durationS: defaultSetSeconds)..subExercise = stretch);
        }
        w.exercises.add(le);
        continue;
      }
      le.previous = await workouts.previousSets(ex.id);
      for (var i = 0; i < slot.targetSets; i++) {
        final prev = le.previousFor(i);
        le.sets.add(LoggedSet(type: prev?.setType ?? SetType.normal));
      }
      w.exercises.add(le);
    }
    _active = w;
    hr.resetSession();
    await _saveNow();
    notifyListeners();
  }

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
      le.previous = await workouts.previousSets(ex.id, excludeWorkoutId: w.id);
      le.sets.add(LoggedSet(type: le.previousFor(0)?.setType ?? SetType.normal));
      w.exercises.add(le);
    }
    _changed();
  }

  /// Adds stretches as rows of a "Stretching" card.
  void addStretches(LoggedExercise card, List<Exercise> stretches) {
    _addStretchRows(card, stretches);
    _changed();
  }

  void _addStretchRows(LoggedExercise card, List<Exercise> stretches) {
    for (final s in stretches) {
      card.sets.add(LoggedSet(durationS: defaultSetSeconds)..subExercise = s);
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
    if (_timer?.set == s) stopTimer();
    e.sets.remove(s);
    _changed();
  }

  void setWeight(LoggedSet s, double? v) {
    s.weightKg = v;
    _changed(notify: false);
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

  void cycleSetType(LoggedSet s) {
    s.type = SetType.values[(s.type.index + 1) % SetType.values.length];
    _changed();
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
    notifyListeners();
  }

  void adjustRest(int delta) => adjustTimer(delta);

  void _start(RunningTimer t) {
    _timer = t;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    notifyListeners();
  }

  void _tick() {
    final t = _timer;
    if (t == null) {
      _ticker?.cancel();
      return;
    }
    if (t.countsDown && t.remaining <= 0) {
      _ticker?.cancel();
      _timer = null;
      switch (t.kind) {
        case TimerKind.setTimer:
          hr.beeper.beep(frequency: 880, count: 2);
          if (t.exercise != null && t.set != null && _active?.exercises.contains(t.exercise) == true) {
            _complete(t.exercise!, t.set!, chain: true);
            _changed();
          }
        case TimerKind.rest:
          hr.beeper.beep(frequency: 880, count: 1);
          final from = _restChainFrom;
          _restChainFrom = null;
          if (t.chainNext && from != null) _startNextTimedSet(from);
        case TimerKind.countdown:
          hr.beeper.beep(frequency: 880, count: 3);
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
      if (!x.exercise.isTimed) continue;
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
  Future<WorkoutSummary?> finish() async {
    final w = _active;
    if (w == null) return null;
    _timer = null;
    _ticker?.cancel();
    for (final e in w.exercises) {
      e.sets.removeWhere((s) => !s.done);
    }
    w.exercises.removeWhere((e) => e.sets.isEmpty);
    final end = DateTime.now();
    final avg = hr.sessionAvg, max = hr.sessionMax;
    _saveTimer?.cancel();
    await workouts.save(w, endedAt: end, avgHr: avg, maxHr: max);
    final summary = await WorkoutSummary.build(workouts, w, end, avgHr: avg, maxHr: max);
    _active = null;
    notifyListeners();
    return summary;
  }

  Future<void> discard() async {
    final w = _active;
    if (w == null) return;
    _timer = null;
    _ticker?.cancel();
    _saveTimer?.cancel();
    await workouts.delete(w.id);
    _active = null;
    notifyListeners();
  }

  void _changed({bool notify = true}) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _saveNow);
    if (notify) notifyListeners();
  }

  Future<void> _saveNow() async {
    final w = _active;
    if (w != null) await workouts.save(w);
  }

  /// Saves pending changes immediately (e.g. in tests or when backgrounding).
  Future<void> flush() async {
    _saveTimer?.cancel();
    await _saveNow();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _ticker?.cancel();
    super.dispose();
  }
}
