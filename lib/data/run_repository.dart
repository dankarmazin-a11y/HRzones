import 'dart:convert';

import 'package:drift/drift.dart';

import '../run/best_efforts.dart';
import '../run/geo.dart';

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

  /// Drops the route after [endAt] (a forgotten run that kept recording).
  Future<void> deletePointsAfter(String runId, DateTime endAt) =>
      (db.delete(db.runPoints)..where((p) => p.runId.equals(runId) & p.time.isBiggerThanValue(endAt))).go();

  /// A run logged by hand (treadmill, or the phone stayed at home): no
  /// route, no records.
  Future<String> logRun({
    required DateTime startedAt,
    required int durationS,
    required double distanceM,
    RunKind kind = RunKind.outdoor,
    int? avgHr,
    int? effort,
    String notes = '',
    String? shoeId,
  }) async {
    final id = newId();
    await saveRun(
      RunsCompanion.insert(
        id: Value(id),
        startedAt: startedAt,
        endedAt: Value(startedAt.add(Duration(seconds: durationS))),
        durationS: Value(durationS),
        distanceM: Value(distanceM),
        kind: Value(kind),
        avgHr: Value(avgHr),
        effort: Value(effort),
        notes: Value(notes),
        bestsJson: const Value('{}'),
        shoeId: Value(shoeId),
      ),
    );
    return id;
  }

  /// Changes a finished run's start, time, distance, kind or average HR.
  Future<void> updateRun(
    Run run, {
    DateTime? startedAt,
    int? durationS,
    double? distanceM,
    RunKind? kind,
    int? avgHr,
  }) async {
    final start = startedAt ?? run.startedAt;
    final secs = durationS ?? run.durationS;
    final moved = start != run.startedAt || secs != run.durationS;
    await (db.update(db.runs)..where((r) => r.id.equals(run.id))).write(
      RunsCompanion(
        startedAt: Value(start),
        durationS: Value(secs),
        endedAt: moved ? Value(start.add(Duration(seconds: secs + run.pausedS))) : const Value.absent(),
        distanceM: distanceM == null ? const Value.absent() : Value(distanceM),
        kind: kind == null ? const Value.absent() : Value(kind),
        avgHr: avgHr == null ? const Value.absent() : Value(avgHr),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// A run that kept recording after you stopped: drops the route after
  /// [endAt] and works out the distance and moving time again.
  Future<void> trimEnd(Run run, DateTime endAt) async {
    await deletePointsAfter(run.id, endAt);
    final pts = await points(run.id);
    final tracker = DistanceTracker();
    var moving = 0.0;
    RunPoint? prev;
    for (final p in pts) {
      if (prev == null || prev.segment != p.segment) {
        tracker.newSegment();
      } else {
        final dt = p.time.difference(prev.time).inMilliseconds / 1000;
        if (dt > 0 && dt <= 60) moving += dt;
      }
      tracker.add(GeoFix(time: p.time, lat: p.lat, lon: p.lon, accuracy: p.accuracy));
      prev = p;
    }
    await (db.update(db.runs)..where((r) => r.id.equals(run.id))).write(
      RunsCompanion(
        endedAt: Value(endAt),
        distanceM: Value(tracker.distanceM),
        durationS: Value(moving.round()),
        bestsJson: const Value(null), // worked out again on demand
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// How it felt: effort 1–10, weather tags, notes.
  Future<void> updateNotes(String id, {int? effort, String? weather, String? notes, bool clearEffort = false}) =>
      (db.update(db.runs)..where((r) => r.id.equals(id))).write(
        RunsCompanion(
          effort: clearEffort ? const Value(null) : (effort == null ? const Value.absent() : Value(effort)),
          weather: weather == null ? const Value.absent() : Value(weather.isEmpty ? null : weather),
          notes: notes == null ? const Value.absent() : Value(notes),
          updatedAt: Value(DateTime.now()),
        ),
      );

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
