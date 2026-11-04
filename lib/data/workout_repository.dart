import 'package:drift/drift.dart';

import '../workout/active_workout.dart';
import '../workout/stats.dart';
import 'database.dart';
import 'exercise_repository.dart';

class WorkoutListItem {
  WorkoutListItem({required this.workout, required this.exerciseNames, required this.setCount, required this.volume});

  final Workout workout;
  final List<String> exerciseNames;
  final int setCount;
  final double volume;
}

/// One workout's sets of a single exercise (for the exercise history).
class ExerciseSession {
  ExerciseSession({required this.workout, required this.sets});

  final Workout workout;
  final List<WorkoutSet> sets;
}

class WorkoutRepository {
  WorkoutRepository(this.db, this.exercises);

  final AppDatabase db;
  final ExerciseRepository exercises;

  /// Writes the whole workout (replacing previous rows).
  Future<void> save(ActiveWorkout w, {DateTime? endedAt, int? avgHr, int? maxHr}) {
    return db.transaction(() async {
      await db
          .into(db.workouts)
          .insertOnConflictUpdate(
            WorkoutsCompanion.insert(
              id: Value(w.id),
              type: WorkoutType.strength,
              name: w.name,
              startedAt: w.startedAt,
              endedAt: Value(endedAt),
              templateId: Value(w.templateId),
              notes: Value(w.notes),
              hrPresetId: Value(w.hrPresetId),
              avgHr: Value(avgHr),
              maxHr: Value(maxHr),
              updatedAt: Value(DateTime.now()),
            ),
          );
      await (db.delete(db.workoutExercises)..where((e) => e.workoutId.equals(w.id))).go();
      await db.batch((b) {
        for (final (i, e) in w.exercises.indexed) {
          b.insert(
            db.workoutExercises,
            WorkoutExercisesCompanion.insert(
              id: Value(e.id),
              workoutId: w.id,
              exerciseId: e.exercise.id,
              position: i,
              restSeconds: Value(e.restSeconds),
              supersetGroup: Value(e.supersetGroup),
              notes: Value(e.notes),
            ),
          );
          for (final (j, s) in e.sets.indexed) {
            b.insert(
              db.workoutSets,
              WorkoutSetsCompanion.insert(
                id: Value(s.id),
                workoutId: w.id,
                workoutExerciseId: e.id,
                exerciseId: e.exercise.id,
                setIndex: j,
                setType: Value(s.type),
                weightKg: Value(s.weightKg),
                reps: Value(s.reps),
                durationS: Value(s.durationS),
                rpe: Value(s.rpe),
                maxHr: Value(s.maxHr),
                completedAt: Value(s.completedAt),
                subExerciseId: Value(s.subExercise?.id),
              ),
            );
          }
        }
      });
    });
  }

  /// The unfinished workout, if the app was closed mid-workout.
  Future<ActiveWorkout?> loadActive() async {
    final row =
        await (db.select(db.workouts)
              ..where((w) => w.endedAt.isNull())
              ..orderBy([(w) => OrderingTerm.desc(w.startedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _load(row);
  }

  Future<ActiveWorkout> _load(Workout row) async {
    final wes =
        await (db.select(db.workoutExercises)
              ..where((e) => e.workoutId.equals(row.id))
              ..orderBy([(e) => OrderingTerm.asc(e.position)]))
            .get();
    final sets =
        await (db.select(db.workoutSets)
              ..where((s) => s.workoutId.equals(row.id))
              ..orderBy([(s) => OrderingTerm.asc(s.setIndex)]))
            .get();
    final w = ActiveWorkout(id: row.id, name: row.name, startedAt: row.startedAt, templateId: row.templateId)
      ..notes = row.notes
      ..hrPresetId = row.hrPresetId;
    for (final we in wes) {
      final ex = await exercises.byId(we.exerciseId);
      if (ex == null) continue;
      final le = LoggedExercise(id: we.id, exercise: ex, restSeconds: we.restSeconds, supersetGroup: we.supersetGroup)
        ..notes = we.notes;
      for (final s in sets.where((s) => s.workoutExerciseId == we.id)) {
        le.sets.add(
          LoggedSet(id: s.id, type: s.setType, weightKg: s.weightKg, reps: s.reps, durationS: s.durationS, rpe: s.rpe)
            ..maxHr = s.maxHr
            ..completedAt = s.completedAt
            ..subExercise = s.subExerciseId == null ? null : await exercises.byId(s.subExerciseId!),
        );
      }
      le.previous = await previousSets(ex.id, excludeWorkoutId: row.id);
      w.exercises.add(le);
    }
    return w;
  }

  Future<ActiveWorkout?> loadById(String id) async {
    final row = await (db.select(db.workouts)..where((w) => w.id.equals(id))).getSingleOrNull();
    return row == null ? null : _load(row);
  }

  Future<Workout?> workoutRow(String id) => (db.select(db.workouts)..where((w) => w.id.equals(id))).getSingleOrNull();

  /// Completed sets of the most recent finished workout containing [exerciseId].
  Future<List<WorkoutSet>> previousSets(String exerciseId, {String? excludeWorkoutId}) async {
    final q =
        db.select(db.workoutSets).join([innerJoin(db.workouts, db.workouts.id.equalsExp(db.workoutSets.workoutId))])
          ..where(
            db.workoutSets.exerciseId.equals(exerciseId) &
                db.workouts.endedAt.isNotNull() &
                db.workoutSets.completedAt.isNotNull() &
                (excludeWorkoutId == null ? const Constant(true) : db.workouts.id.equals(excludeWorkoutId).not()),
          )
          ..orderBy([OrderingTerm.desc(db.workouts.startedAt), OrderingTerm.asc(db.workoutSets.setIndex)]);
    final rows = await q.get();
    if (rows.isEmpty) return [];
    final latest = rows.first.readTable(db.workouts).id;
    return [
      for (final r in rows)
        if (r.readTable(db.workouts).id == latest) r.readTable(db.workoutSets),
    ];
  }

  /// All completed sets from finished workouts other than [excludeWorkoutId]
  /// (and started before [before]), limited to [exerciseIds].
  Future<List<SetStat>> history(Iterable<String> exerciseIds, {String? excludeWorkoutId, DateTime? before}) async {
    final ids = exerciseIds.toSet();
    if (ids.isEmpty) return [];
    final q =
        db.select(db.workoutSets).join([innerJoin(db.workouts, db.workouts.id.equalsExp(db.workoutSets.workoutId))])
          ..where(
            (db.workoutSets.exerciseId.isIn(ids) | db.workoutSets.subExerciseId.isIn(ids)) &
                db.workouts.endedAt.isNotNull() &
                db.workoutSets.completedAt.isNotNull() &
                (excludeWorkoutId == null ? const Constant(true) : db.workouts.id.equals(excludeWorkoutId).not()) &
                (before == null ? const Constant(true) : db.workouts.startedAt.isSmallerThanValue(before)),
          );
    return [for (final r in await q.get()) SetStat.fromRow(r.readTable(db.workoutSets))];
  }

  Stream<List<WorkoutListItem>> watchFinished() {
    final q = db.select(db.workouts)
      ..where((w) => w.endedAt.isNotNull())
      ..orderBy([(w) => OrderingTerm.desc(w.startedAt)]);
    return q.watch().asyncMap((rows) async {
      final sets = await (db.select(db.workoutSets)..where((s) => s.completedAt.isNotNull())).get();
      final wes = await (db.select(db.workoutExercises)..orderBy([(e) => OrderingTerm.asc(e.position)])).get();
      final out = <WorkoutListItem>[];
      for (final w in rows) {
        final ws = sets.where((s) => s.workoutId == w.id).map(SetStat.fromRow).toList();
        final names = <String>[];
        for (final we in wes.where((e) => e.workoutId == w.id)) {
          final ex = await exercises.byId(we.exerciseId);
          if (ex != null) names.add(ex.name);
        }
        out.add(WorkoutListItem(workout: w, exerciseNames: names, setCount: ws.length, volume: totalVolume(ws)));
      }
      return out;
    });
  }

  /// Every finished workout that contains [exerciseId] (as an exercise or as
  /// a stretch row), newest first, with its completed sets of that exercise.
  Future<List<ExerciseSession>> exerciseHistory(String exerciseId) async {
    final q =
        db.select(db.workoutSets).join([innerJoin(db.workouts, db.workouts.id.equalsExp(db.workoutSets.workoutId))])
          ..where(
            (db.workoutSets.exerciseId.equals(exerciseId) | db.workoutSets.subExerciseId.equals(exerciseId)) &
                db.workouts.endedAt.isNotNull() &
                db.workoutSets.completedAt.isNotNull(),
          )
          ..orderBy([OrderingTerm.desc(db.workouts.startedAt), OrderingTerm.asc(db.workoutSets.setIndex)]);
    final out = <String, ExerciseSession>{};
    for (final r in await q.get()) {
      final w = r.readTable(db.workouts);
      out.putIfAbsent(w.id, () => ExerciseSession(workout: w, sets: [])).sets.add(r.readTable(db.workoutSets));
    }
    return out.values.toList();
  }

  Future<void> delete(String id) => (db.delete(db.workouts)..where((w) => w.id.equals(id))).go();
}
