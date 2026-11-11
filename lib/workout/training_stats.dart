import '../data/database.dart';
import '../data/workout_repository.dart';
import 'stats.dart';
import 'streak.dart';

/// Phase 3 analytics: totals per week and training load per muscle. Pure
/// functions over what the repositories already return.

/// One week (Sunday … Saturday) of training.
class WeekSummary {
  WeekSummary(this.start);

  final DateTime start;
  int strength = 0;
  int runs = 0;
  int strengthMinutes = 0;
  int runMinutes = 0;
  int sets = 0;
  double volume = 0;
  double metres = 0;

  int get workouts => strength + runs;
  int get minutes => strengthMinutes + runMinutes;
}

/// The last [weeks] weeks, oldest first (the current week last).
List<WeekSummary> weeklySummaries({
  required List<WorkoutListItem> workouts,
  required List<Run> runs,
  int weeks = 12,
  DateTime? now,
}) {
  final current = weekStart(now ?? DateTime.now());
  final list = [
    for (var i = weeks - 1; i >= 0; i--) WeekSummary(DateTime(current.year, current.month, current.day - 7 * i)),
  ];
  final byStart = {for (final w in list) w.start: w};
  for (final i in workouts) {
    final w = byStart[weekStart(i.workout.startedAt)];
    if (w == null) continue;
    w.strength++;
    w.strengthMinutes += workoutMinutes(i.workout);
    w.sets += i.setCount;
    w.volume += i.volume;
  }
  for (final r in runs) {
    final w = byStart[weekStart(r.startedAt)];
    if (w == null) continue;
    w.runs++;
    w.runMinutes += r.durationS ~/ 60;
    w.metres += r.distanceM;
  }
  return list;
}

int workoutMinutes(Workout w) => (w.endedAt ?? w.startedAt).difference(w.startedAt).inMinutes;

/// Totals of a period.
class PeriodTotals {
  int strength = 0;
  int runs = 0;
  int minutes = 0;
  int sets = 0;
  double volume = 0;
  double metres = 0;

  int get workouts => strength + runs;
}

PeriodTotals periodTotals({required List<WorkoutListItem> workouts, required List<Run> runs, required DateTime from}) {
  final t = PeriodTotals();
  for (final i in workouts.where((i) => !i.workout.startedAt.isBefore(from))) {
    t.strength++;
    t.minutes += workoutMinutes(i.workout);
    t.sets += i.setCount;
    t.volume += i.volume;
  }
  for (final r in runs.where((r) => !r.startedAt.isBefore(from))) {
    t.runs++;
    t.minutes += r.durationS ~/ 60;
    t.metres += r.distanceM;
  }
  return t;
}

/// Working sets per muscle: the main muscle counts a whole set, each
/// secondary muscle half a set. Warm-ups, stretches and interval timers
/// don't count; a left + right pair is one set.
Map<String, double> setsPerMuscle(Iterable<SetStat> sets, Exercise? Function(String id) exercise) {
  final out = <String, double>{};
  for (final s in sets) {
    if (!s.countsForRecords || s.right) continue;
    final e = exercise(s.exerciseId);
    if (e == null || e.isStretch || e.isInterval || e.isStretchSession) continue;
    out[e.primaryMuscle] = (out[e.primaryMuscle] ?? 0) + 1;
    for (final m in e.secondaryMuscles.split(',').map((m) => m.trim()).where((m) => m.isNotEmpty)) {
      out[m] = (out[m] ?? 0) + 0.5;
    }
  }
  return out;
}

/// 0–1 per muscle for the body map: about 10 sets a week is "fully trained".
Map<String, double> muscleHeat(Map<String, double> sets, {required int days}) {
  final full = 10 * days / 7;
  return {for (final MapEntry(:key, :value) in sets.entries) key: (value / full).clamp(0.0, 1.0)};
}

/// Exercises with the most working sets (a pair = one set), most first.
List<(String, int)> topExercises(Iterable<SetStat> sets, Exercise? Function(String id) exercise, {int count = 5}) {
  final n = <String, int>{};
  for (final s in sets) {
    if (!s.countsForRecords || s.right) continue;
    final e = exercise(s.exerciseId);
    if (e == null || e.isInterval || e.isStretchSession) continue;
    n[s.exerciseId] = (n[s.exerciseId] ?? 0) + 1;
  }
  final list = n.entries.toList()..sort((a, b) => b.value - a.value);
  return [for (final e in list.take(count)) (e.key, e.value)];
}
