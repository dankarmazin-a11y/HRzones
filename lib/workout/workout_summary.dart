part of 'workout_session.dart';

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

  // ── End-of-workout stats (owner, 17 Nov) ─────────────────────────────
  Iterable<LoggedSet> get _working => workout.exercises
      .where((e) => !e.exercise.id.startsWith(intervalExercisePrefix))
      .expand((e) => e.sets)
      .where((s) => s.done && s.type != SetType.warmup);

  /// Reps done (both sides of a one-sided set count).
  int get reps => _working.fold(0, (n, s) => n + (s.reps ?? 0));

  /// Time inside sets: timed sets fully, other sets about [secondsPerRep] a rep.
  static const secondsPerRep = 3;
  Duration get working {
    var secs = 0;
    for (final e in workout.exercises) {
      for (final s in e.sets.where((s) => s.done)) {
        secs += s.reps != null && s.reps! > 0 ? s.reps! * secondsPerRep : (s.durationS ?? 0);
      }
    }
    final d = Duration(seconds: secs);
    return d > duration ? duration : d;
  }

  /// Time between sets.
  Duration get resting => duration - working;

  /// The heaviest working set (weight, then reps); null without weights.
  LoggedSet? get heaviestSet {
    LoggedSet? best;
    for (final s in _working) {
      final w = s.weightKg ?? 0;
      if (w <= 0) continue;
      if (best == null || w > best.weightKg! || (w == best.weightKg! && (s.reps ?? 0) > (best.reps ?? 0))) best = s;
    }
    return best;
  }

  /// Rough energy used: from the average heart rate when a strap was on
  /// (Keytel et al. 2005, the average of the men's and women's formulas),
  /// otherwise MET 5 (weight training, vigorous) × body weight × hours.
  /// Null without a body weight.
  double? calories({double? weightKg, int age = 30}) =>
      strengthCalories(durationS: duration.inSeconds, weightKg: weightKg, avgHr: avgHr, age: age);

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

double? strengthCalories({required int durationS, double? weightKg, int? avgHr, int age = 30}) {
  if (weightKg == null || weightKg <= 0 || durationS <= 0) return null;
  final minutes = durationS / 60;
  if (avgHr != null && avgHr > 60) {
    final men = (-55.0969 + 0.6309 * avgHr + 0.1988 * weightKg + 0.2017 * age) / 4.184;
    final women = (-20.4022 + 0.4472 * avgHr - 0.1263 * weightKg + 0.074 * age) / 4.184;
    final perMin = (men + women) / 2;
    if (perMin > 0) return perMin * minutes;
  }
  return 5.0 * weightKg * durationS / 3600;
}
