import 'package:drift/drift.dart';

import 'body_repository.dart';
import 'database.dart';
import 'exercise_repository.dart';
import 'workout_repository.dart';

/// A goal with its current value and progress (0–1).
class GoalProgress {
  const GoalProgress({
    required this.goal,
    required this.title,
    required this.current,
    required this.progress,
    required this.unit,
  });

  final Goal goal;
  final String title;
  final double? current;
  final double progress;
  final String unit;

  bool get achieved => progress >= 1;
}

/// Progress from [start] towards [target] at [current]; works both ways
/// (losing weight or adding kilos).
double progressBetween(double start, double target, double current) {
  if (start == target) {
    final reached = target >= start ? current >= target : current <= target;
    return reached ? 1 : 0;
  }
  return ((current - start) / (target - start)).clamp(0.0, 1.0);
}

class GoalRepository {
  GoalRepository(this.db, this.workouts, this.exercises, this.body);

  final AppDatabase db;
  final WorkoutRepository workouts;
  final ExerciseRepository exercises;
  final BodyRepository body;

  Stream<List<Goal>> watchAll() => (db.select(db.goals)..orderBy([(g) => OrderingTerm.asc(g.createdAt)])).watch();

  Future<void> addLift(String exerciseId, double targetKg, {DateTime? deadline}) async {
    final start = await bestWeight(exerciseId);
    await db
        .into(db.goals)
        .insert(
          GoalsCompanion.insert(
            type: GoalType.liftWeight,
            target: targetKg,
            exerciseId: Value(exerciseId),
            startValue: Value(start ?? 0),
            deadline: Value(deadline),
          ),
        );
  }

  Future<void> addMeasurement(String kind, double target, {DateTime? deadline}) async {
    final start = await body.latest(kind);
    await db
        .into(db.goals)
        .insert(
          GoalsCompanion.insert(
            type: GoalType.measurement,
            target: target,
            measurementKind: Value(kind),
            startValue: Value(start),
            deadline: Value(deadline),
          ),
        );
  }

  Future<void> delete(String id) => (db.delete(db.goals)..where((g) => g.id.equals(id))).go();

  /// Heaviest working-set weight ever lifted for an exercise.
  Future<double?> bestWeight(String exerciseId) async {
    double? best;
    for (final s in await workouts.exerciseHistory(exerciseId)) {
      for (final set in s.sets) {
        if (set.setType == SetType.warmup) continue;
        final w = set.weightKg;
        if (w != null && (best == null || w > best)) best = w;
      }
    }
    return best;
  }

  Future<GoalProgress> progress(Goal g) async {
    switch (g.type) {
      case GoalType.liftWeight:
        final ex = await exercises.byId(g.exerciseId ?? '');
        final current = await bestWeight(g.exerciseId ?? '');
        return GoalProgress(
          goal: g,
          title: '${ex?.name ?? 'Exercise'} ${_n(g.target)} kg',
          current: current,
          progress: progressBetween(g.startValue ?? 0, g.target, current ?? 0),
          unit: 'kg',
        );
      case GoalType.measurement:
        final kind = kindOf(g.measurementKind ?? '');
        final current = await body.latest(kind.key);
        final start = g.startValue ?? current ?? g.target;
        return GoalProgress(
          goal: g,
          title: '${kind.label} ${_n(g.target)} ${kind.unit}',
          current: current,
          progress: current == null ? 0 : progressBetween(start, g.target, current),
          unit: kind.unit,
        );
      case GoalType.workoutsPerWeek:
        return GoalProgress(goal: g, title: '${_n(g.target)} workouts a week', current: null, progress: 0, unit: '');
    }
  }

  static String _n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
