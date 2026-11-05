import 'dart:convert';

import 'package:drift/drift.dart';

import '../run/best_efforts.dart';

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

  /// Fastest time per record distance inside [run] (worked out from its
  /// points and saved the first time).
  Future<Map<int, double>> bestsFor(Run run) async {
    final saved = decodeBests(run.bestsJson);
    if (saved != null) return saved;
    final pts = await points(run.id);
    final bests = bestEfforts(
      pts.map((p) => (time: p.time, lat: p.lat, lon: p.lon, accuracy: p.accuracy, segment: p.segment)),
    );
    await (db.update(
      db.runs,
    )..where((r) => r.id.equals(run.id))).write(RunsCompanion(bestsJson: Value(encodeBests(bests))));
    return bests;
  }

  /// The record for each distance, and the longest run, over finished runs
  /// started before [before] (all when null), except [excludeId].
  Future<RunRecords> records({DateTime? before, String? excludeId}) async {
    final rows =
        await (db.select(db.runs)
              ..where((r) => r.endedAt.isNotNull())
              ..orderBy([(r) => OrderingTerm.asc(r.startedAt)]))
            .get();
    final best = <int, RunRecord>{};
    RunRecord? longest;
    for (final r in rows) {
      if (r.id == excludeId || (before != null && !r.startedAt.isBefore(before))) continue;
      for (final e in (await bestsFor(r)).entries) {
        final cur = best[e.key];
        if (cur == null || e.value < cur.value) best[e.key] = RunRecord(run: r, value: e.value);
      }
      if (longest == null || r.distanceM > longest.value) longest = RunRecord(run: r, value: r.distanceM);
    }
    return RunRecords(fastest: best, longest: longest);
  }
}

/// A record and the run it was set in.
class RunRecord {
  const RunRecord({required this.run, required this.value});

  final Run run;

  /// Seconds (fastest) or metres (longest).
  final double value;
}

class RunRecords {
  const RunRecords({required this.fastest, required this.longest});

  /// Distance in metres → fastest time.
  final Map<int, RunRecord> fastest;
  final RunRecord? longest;
}

String encodeBests(Map<int, double> b) => jsonEncode({for (final e in b.entries) '${e.key}': e.value});

Map<int, double>? decodeBests(String? json) {
  if (json == null) return null;
  try {
    return {
      for (final e in (jsonDecode(json) as Map<String, dynamic>).entries) int.parse(e.key): (e.value as num).toDouble(),
    };
  } catch (_) {
    return null;
  }
}
