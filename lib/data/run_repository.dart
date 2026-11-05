import 'package:drift/drift.dart';

import 'database.dart';

/// Runs and their GPS points.
class RunRepository {
  RunRepository(this.db);

  final AppDatabase db;

  Future<void> saveRun(RunsCompanion run) => db.into(db.runs).insertOnConflictUpdate(run);

  /// Appends GPS points (the route is only ever added to while recording).
  Future<void> addPoints(List<RunPointsCompanion> points) async {
    if (points.isEmpty) return;
    await db.batch((b) => b.insertAll(db.runPoints, points));
  }

  /// The run being recorded, if the app was closed during a run.
  Future<Run?> loadActive() =>
      (db.select(db.runs)
            ..where((r) => r.endedAt.isNull())
            ..orderBy([(r) => OrderingTerm.desc(r.startedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<Run?> byId(String id) => (db.select(db.runs)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<List<RunPoint>> points(String runId) =>
      (db.select(db.runPoints)
            ..where((p) => p.runId.equals(runId))
            ..orderBy([(p) => OrderingTerm.asc(p.time)]))
          .get();

  /// Finished runs, newest first. Only emits when they change (the run being
  /// recorded is saved every few seconds).
  Stream<List<Run>> watchFinished() =>
      (db.select(db.runs)
            ..where((r) => r.endedAt.isNotNull())
            ..orderBy([(r) => OrderingTerm.desc(r.startedAt)]))
          .watch()
          .distinct(_same);

  static bool _same(List<Run> a, List<Run> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Stream<Run?> watch(String id) => (db.select(db.runs)..where((r) => r.id.equals(id))).watchSingleOrNull();

  Future<void> delete(String id) => (db.delete(db.runs)..where((r) => r.id.equals(id))).go();
}
