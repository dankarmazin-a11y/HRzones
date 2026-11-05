import 'package:drift/drift.dart';

import '../data/body_repository.dart';
import '../data/database.dart';
import '../data/run_repository.dart';
import '../run/best_efforts.dart';
import '../run/elevation.dart';
import '../run/geo.dart';
import '../run/splits.dart';
import 'xlsx_writer.dart';

/// All workouts, sets, runs (+ km splits) and body measurements as an .xlsx
/// workbook.
Future<Uint8List> exportWorkbook(AppDatabase db) async {
  final exercises = {for (final e in await db.select(db.exercises).get()) e.id: e};
  final presets = {for (final p in await db.select(db.hrPresets).get()) p.id: p};
  final workouts =
      await (db.select(db.workouts)
            ..where((w) => w.endedAt.isNotNull())
            ..orderBy([(w) => OrderingTerm.asc(w.startedAt)]))
          .get();
  final byId = {for (final w in workouts) w.id: w};
  final sets =
      await (db.select(db.workoutSets)
            ..where((s) => s.completedAt.isNotNull())
            ..orderBy([(s) => OrderingTerm.asc(s.completedAt), (s) => OrderingTerm.asc(s.setIndex)]))
          .get();

  String setType(SetType t) => switch (t) {
    SetType.warmup => 'Warm-up',
    SetType.normal => 'Normal',
    SetType.drop => 'Drop',
    SetType.failure => 'Failure',
  };

  final workoutRows = <List<Object?>>[
    ['Date', 'Workout', 'Type', 'Minutes', 'Sets', 'Volume (kg)', 'Avg HR', 'Max HR', 'HR zone preset', 'Notes'],
    for (final w in workouts)
      () {
        final ws = sets.where((s) => s.workoutId == w.id && s.setType != SetType.warmup);
        final volume = ws.fold(0.0, (v, s) => v + (s.weightKg ?? 0) * (s.reps ?? 0));
        return [
          w.startedAt,
          w.name,
          w.type.name,
          w.endedAt?.difference(w.startedAt).inMinutes,
          sets.where((s) => s.workoutId == w.id).length,
          double.parse(volume.toStringAsFixed(2)),
          w.avgHr,
          w.maxHr,
          presets[w.hrPresetId]?.name,
          w.notes.isEmpty ? null : w.notes,
        ];
      }(),
  ];

  final setRows = <List<Object?>>[
    ['Date', 'Workout', 'Exercise', 'Stretch', 'Set', 'Set type', 'Weight (kg)', 'Reps', 'Seconds', 'RPE', 'Max HR'],
    for (final s in sets)
      if (byId[s.workoutId] case final w?)
        [
          w.startedAt,
          w.name,
          exercises[s.exerciseId]?.name ?? s.exerciseId,
          s.subExerciseId == null ? null : (exercises[s.subExerciseId]?.name ?? s.subExerciseId),
          s.setIndex + 1,
          setType(s.setType),
          s.weightKg,
          s.reps,
          s.durationS,
          s.rpe,
          s.maxHr,
        ],
  ];

  final measurements = await (db.select(db.bodyMeasurements)..orderBy([(m) => OrderingTerm.asc(m.date)])).get();
  final measureRows = <List<Object?>>[
    ['Date', 'Measurement', 'Value', 'Unit'],
    for (final m in measurements) [m.date, kindOf(m.kind).label, m.value, kindOf(m.kind).unit],
  ];

  // Runs: one row per run, and one row per km split.
  final runRepo = RunRepository(db);
  final shoes = {for (final x in await db.select(db.shoes).get()) x.id: x};
  final runs =
      await (db.select(db.runs)
            ..where((r) => r.endedAt.isNotNull())
            ..orderBy([(r) => OrderingTerm.asc(r.startedAt)]))
          .get();
  String? paceText(double? secPerKm) => secPerKm == null ? null : formatPace(secPerKm);
  final runRows = <List<Object?>>[
    [
      'Date',
      'Distance (km)',
      'Moving time (min)',
      'Avg pace (min/km)',
      'Avg HR',
      'Max HR',
      'HR zone preset',
      for (final d in recordDistances.values) 'Best $d (min)',
      'Kind',
      'Effort (1–10)',
      'Weather',
      'Shoes',
      'Climb (m)',
      'Descent (m)',
      'Cadence (spm)',
      'Steps',
      'Notes',
    ],
  ];
  final splitRows = <List<Object?>>[
    ['Date', 'Km', 'Distance (km)', 'Time (min)', 'Pace (min/km)', 'Avg HR'],
  ];
  for (final r in runs) {
    final bests = await runRepo.bestsFor(r);
    final points = await runRepo.points(r.id);
    final alts = [for (final p in points) ?p.altitude];
    final climb = alts.length < 10 ? null : elevationGainLoss(alts);
    runRows.add([
      r.startedAt,
      double.parse((r.distanceM / 1000).toStringAsFixed(2)),
      double.parse((r.durationS / 60).toStringAsFixed(2)),
      paceText(paceSecPerKm(r.distanceM, r.durationS.toDouble())),
      r.avgHr,
      r.maxHr,
      presets[r.hrPresetId]?.name,
      for (final d in recordDistances.keys) bests[d] == null ? null : double.parse((bests[d]! / 60).toStringAsFixed(2)),
      r.kind.name,
      r.effort,
      r.weather,
      shoes[r.shoeId]?.name,
      climb?.climb.round(),
      climb?.descent.round(),
      r.avgCadence,
      r.steps,
      r.notes.isEmpty ? null : r.notes,
    ]);
    for (final sp in computeSplits(
      points.map((p) => (time: p.time, lat: p.lat, lon: p.lon, accuracy: p.accuracy, segment: p.segment, hr: p.hr)),
    )) {
      splitRows.add([
        r.startedAt,
        sp.km,
        double.parse((sp.distanceM / 1000).toStringAsFixed(2)),
        double.parse((sp.seconds / 60).toStringAsFixed(2)),
        paceText(sp.pace),
        sp.avgHr,
      ]);
    }
  }

  return buildXlsx([
    Sheet('Workouts', workoutRows),
    Sheet('Sets', setRows),
    Sheet('Runs', runRows),
    Sheet('Run splits', splitRows),
    Sheet('Measurements', measureRows),
  ]);
}
