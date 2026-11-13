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
