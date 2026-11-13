import 'package:drift/drift.dart';

import 'body_repository.dart';
import 'database.dart';
import 'exercise_repository.dart';
import 'run_repository.dart';
import '../run/best_efforts.dart';
import '../workout/streak.dart';
import 'workout_repository.dart';
import '../units/units.dart';

/// A goal with its current value and progress (0–1).
class GoalProgress {
  const GoalProgress({
    required this.goal,
    required this.title,
    required this.current,
    required this.progress,
    required this.unit,
    this.toShown = _same,
    this.fromShown = _same,
  });

  final Goal goal;
  final String title;

  /// [current] and the goal's target are stored in kg / cm / km / minutes;
  /// [toShown] turns them into the chosen units ([unit]), [fromShown] back.
  final double? current;
  final double progress;
  final String unit;
  final double Function(double) toShown;
  final double Function(double) fromShown;

  static double _same(double v) => v;

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
  GoalRepository(this.db, this.workouts, this.exercises, this.body, this.runs);

  final AppDatabase db;
  final WorkoutRepository workouts;
  final ExerciseRepository exercises;
  final BodyRepository body;
  final RunRepository runs;

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

  /// Running goals: km per week ([GoalType.runKmPerWeek], target km), one
  /// long run ([GoalType.runDistance], target km), or a time at a distance
  /// ([GoalType.runTime], target minutes, [distanceM]).
  Future<void> addRun(GoalType type, double target, {double? distanceM, DateTime? deadline}) async {
    double? start;
    if (type == GoalType.runDistance) start = ((await runs.records()).longest?.value ?? 0) / 1000;
    if (type == GoalType.runTime) {
      final best = (await runs.records()).fastest[distanceM?.round()]?.value;
      start = best == null ? null : best / 60;
    }
    await db
        .into(db.goals)
        .insert(
          GoalsCompanion.insert(
            type: type,
            target: target,
            startValue: Value(start),
            distanceM: Value(distanceM),
            deadline: Value(deadline),
          ),
        );
  }

  /// Km run since Sunday (start of the week).
  Future<double> kmThisWeek() async {
    final sunday = weekStart(DateTime.now());
    final list = await (db.select(
      db.runs,
    )..where((r) => r.endedAt.isNotNull() & r.startedAt.isBiggerOrEqualValue(sunday))).get();
    return list.fold<double>(0, (a, r) => a + r.distanceM) / 1000;
  }

  /// Changes a goal's target and deadline.
  Future<void> updateGoal(String id, {required double target, DateTime? deadline}) =>
      (db.update(db.goals)..where((g) => g.id.equals(id))).write(
        GoalsCompanion(target: Value(target), deadline: Value(deadline), updatedAt: Value(DateTime.now())),
      );

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

  /// Progress of [g]; the first time a goal is reached its date is saved
  /// (`goals.achieved_at`) for Profile › Records › Goals reached.
  Future<GoalProgress> progress(Goal g) async {
    final p = await _progressOf(g);
    if (!p.achieved || g.achievedAt != null) return p;
    final now = DateTime.now();
    await (db.update(
      db.goals,
    )..where((x) => x.id.equals(g.id))).write(GoalsCompanion(achievedAt: Value(now), updatedAt: Value(now)));
    return GoalProgress(
      goal: g.copyWith(achievedAt: Value(now)),
      title: p.title,
      current: p.current,
      progress: p.progress,
      unit: p.unit,
      toShown: p.toShown,
      fromShown: p.fromShown,
    );
  }

  Future<GoalProgress> _progressOf(Goal g) async {
    switch (g.type) {
      case GoalType.liftWeight:
        final ex = await exercises.byId(g.exerciseId ?? '');
        final current = await bestWeight(g.exerciseId ?? '');
        return GoalProgress(
          goal: g,
          title: '${ex?.name ?? 'Exercise'} ${_n(Units.toW(g.target))} ${Units.w}',
          current: current,
          progress: progressBetween(g.startValue ?? 0, g.target, current ?? 0),
          unit: Units.w,
          toShown: Units.toW,
          fromShown: Units.fromW,
        );
      case GoalType.measurement:
        final kind = kindOf(g.measurementKind ?? '');
        final current = await body.latest(kind.key);
        final start = g.startValue ?? current ?? g.target;
        return GoalProgress(
          goal: g,
          title: '${kind.label} ${_n(kind.toShown(g.target))} ${kind.shownUnit}',
          current: current,
          progress: current == null ? 0 : progressBetween(start, g.target, current),
          unit: kind.shownUnit,
          toShown: kind.toShown,
          fromShown: kind.fromShown,
        );
      case GoalType.runKmPerWeek:
        final km = await kmThisWeek();
        return GoalProgress(
          goal: g,
          title: 'Run ${_n(_kmShown(g.target))} ${Units.d} a week',
          current: km,
          progress: g.target <= 0 ? 0 : (km / g.target).clamp(0.0, 1.0),
          unit: Units.d,
          toShown: _kmShown,
          fromShown: _kmStored,
        );
      case GoalType.runDistance:
        final longest = ((await runs.records()).longest?.value ?? 0) / 1000;
        return GoalProgress(
          goal: g,
          title: 'Run ${_n(_kmShown(g.target))} ${Units.d} in one go',
          current: longest,
          progress: progressBetween(g.startValue ?? 0, g.target, longest),
          unit: Units.d,
          toShown: _kmShown,
          fromShown: _kmStored,
        );
      case GoalType.runTime:
        final d = (g.distanceM ?? 5000).round();
        final best = (await runs.records()).fastest[d]?.value;
        final current = best == null ? null : best / 60;
        // No time yet: count from 30% slower than the target.
        final start = g.startValue ?? g.target * 1.3;
        return GoalProgress(
          goal: g,
          title: '${recordDistances[d] ?? '${_n(d / 1000)} km'} under ${minutesText(g.target)}',
          current: current,
          progress: current == null ? 0 : progressBetween(start, g.target, current),
          unit: 'min',
        );
      case GoalType.workoutsPerWeek:
        return GoalProgress(goal: g, title: '${_n(g.target)} workouts a week', current: null, progress: 0, unit: '');
    }
  }

  /// Run goals are stored in km.
  static double _kmShown(double km) => Units.toD(km * 1000);
  static double _kmStored(double v) => Units.fromD(v) / 1000;

  static String _n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

/// 24.5 minutes → "24:30".
String minutesText(double minutes) {
  final s = (minutes * 60).round();
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '$m:${two(sec)}';
}
