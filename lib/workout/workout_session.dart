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
          SetStat(exerciseId: e.exercise.id, type: s.type, weightKg: s.weightKg, reps: s.reps, durationS: s.durationS),
  ];

  double get volume => totalVolume(sets);
  int get setCount => sets.length;

  /// Working sets per primary muscle.
  Map<String, int> get setsPerMuscle {
    final out = <String, int>{};
    for (final e in workout.exercises) {
      final n = e.sets.where((s) => s.done && s.type != SetType.warmup).length;
      if (n > 0) out.update(e.exercise.primaryMuscle, (v) => v + n, ifAbsent: () => n);
    }
    return out;
  }

  String exerciseName(String id) =>
      workout.exercises.firstWhere((e) => e.exercise.id == id, orElse: () => workout.exercises.first).exercise.name;

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

/// The workout currently being logged + the rest timer.
class WorkoutSession extends ChangeNotifier {
  WorkoutSession({required this.workouts, required this.exercises, required this.hr});

  final WorkoutRepository workouts;
  final ExerciseRepository exercises;
  final HrMonitor hr;

  ActiveWorkout? _active;
  ActiveWorkout? get active => _active;

  Timer? _saveTimer;
  Timer? _restTicker;
  DateTime? _restEndsAt;
  int _restTotal = 0;

  /// Seconds left on the rest timer, or null when not resting.
  int? get restRemaining {
    final end = _restEndsAt;
    if (end == null) return null;
    final left = end.difference(DateTime.now()).inMilliseconds;
    return left <= 0 ? 0 : (left / 1000).ceil();
  }

  int get restTotal => _restTotal;

  Future<void> restore() async {
    _active = await workouts.loadActive();
    notifyListeners();
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

  Future<void> addExercises(List<Exercise> list) async {
    final w = _active;
    if (w == null) return;
    for (final ex in list) {
      final le = LoggedExercise(exercise: ex, restSeconds: ex.defaultRestSeconds);
      le.previous = await workouts.previousSets(ex.id, excludeWorkoutId: w.id);
      le.sets.add(LoggedSet(type: le.previousFor(0)?.setType ?? SetType.normal));
      w.exercises.add(le);
    }
    _changed();
  }

  void removeExercise(LoggedExercise e) {
    _active?.exercises.remove(e);
    _changed();
  }

  void moveExercise(int from, int to) {
    final list = _active?.exercises;
    if (list == null) return;
    final e = list.removeAt(from);
    list.insert(to.clamp(0, list.length), e);
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
      ),
    );
    _changed();
  }

  void removeSet(LoggedExercise e, LoggedSet s) {
    e.sets.remove(s);
    _changed();
  }

  void updateSet(LoggedSet s, {double? weightKg, int? reps, int? durationS, double? rpe, bool clearRpe = false}) {
    if (weightKg != null) s.weightKg = weightKg;
    if (reps != null) s.reps = reps;
    if (durationS != null) s.durationS = durationS;
    if (rpe != null) s.rpe = rpe;
    if (clearRpe) s.rpe = null;
    _changed(notify: false);
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
      final prev = e.previousFor(e.sets.indexOf(s));
      s.weightKg ??= prev?.weightKg;
      s.reps ??= prev?.reps;
      s.durationS ??= prev?.durationS;
      s.completedAt = DateTime.now();
      s.maxHr = hr.takeIntervalMax();
      // In a superset, rest only after the last exercise of the group.
      final list = _active!.exercises;
      final i = list.indexOf(e);
      final inSupersetBeforeEnd =
          e.supersetGroup != null && i + 1 < list.length && list[i + 1].supersetGroup == e.supersetGroup;
      if (!inSupersetBeforeEnd) startRest(e.restSeconds);
    }
    _changed();
  }

  void setRestSeconds(LoggedExercise e, int seconds) {
    e.restSeconds = seconds;
    _changed();
  }

  void startRest(int seconds) {
    if (seconds <= 0) return;
    _restTotal = seconds;
    _restEndsAt = DateTime.now().add(Duration(seconds: seconds));
    _restTicker?.cancel();
    _restTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if ((restRemaining ?? 0) <= 0) {
        _restTicker?.cancel();
        _restEndsAt = null;
        hr.beeper.beep(frequency: 880, count: 1);
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void adjustRest(int delta) {
    final end = _restEndsAt;
    if (end == null) return;
    _restEndsAt = end.add(Duration(seconds: delta));
    _restTotal = (_restTotal + delta).clamp(1, 3600);
    notifyListeners();
  }

  void skipRest() {
    _restTicker?.cancel();
    _restEndsAt = null;
    notifyListeners();
  }

  void rename(String name) {
    _active?.name = name;
    _changed();
  }

  /// Finishes the workout. Uncompleted sets are dropped.
  Future<WorkoutSummary?> finish() async {
    final w = _active;
    if (w == null) return null;
    skipRest();
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
    skipRest();
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
    _restTicker?.cancel();
    super.dispose();
  }
}
