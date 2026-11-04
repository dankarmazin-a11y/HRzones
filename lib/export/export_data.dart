import 'package:drift/drift.dart';

import '../data/body_repository.dart';
import '../data/database.dart';
import 'xlsx_writer.dart';

/// All workouts, sets and body measurements as an .xlsx workbook.
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

  return buildXlsx([Sheet('Workouts', workoutRows), Sheet('Sets', setRows), Sheet('Measurements', measureRows)]);
}
