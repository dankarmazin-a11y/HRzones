import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

/// How an exercise is logged.
enum TrackingType { weightReps, bodyweightReps, duration, distance }

/// Warm-up / normal / drop / failure. (Stored by index – never reorder.)
enum SetType { warmup, normal, drop, failure }

/// Which side a set of a one-sided ("each side") exercise is for.
enum Side { left, right }

enum WorkoutType { strength, run, walk, cycle, other }

/// Id of the "Stretching" session container exercise.
const stretchingSessionId = 'hz_stretching';

extension ExerciseKind on Exercise {
  bool get isStretch => category == 'stretching';
  bool get isStretchSession => id == stretchingSessionId;
  bool get isTimed => trackingType == TrackingType.duration;
  bool get hasNote => (note ?? '').trim().isNotEmpty;
}

/// Exercise library "type" filter.
enum ExerciseGroup { strength, stretching, cardio, timers }

/// Interval timers (Tools › Timers) also exist as exercises with this id
/// prefix + the preset id, category "interval", so they can be added to
/// workouts and templates like any exercise.
const intervalExercisePrefix = 'hz_iv_';

extension ExerciseGroupOf on Exercise {
  ExerciseGroup get group => switch (category) {
    'stretching' => ExerciseGroup.stretching,
    'cardio' || 'plyometrics' => ExerciseGroup.cardio,
    'interval' => ExerciseGroup.timers,
    _ => ExerciseGroup.strength,
  };

  bool get isInterval => category == 'interval';

  /// The interval preset this exercise runs (null for normal exercises).
  String? get intervalPresetId => isInterval ? id.substring(intervalExercisePrefix.length) : null;
}

/// Every table has a UUID primary key and updatedAt (for cloud sync later).
mixin SyncColumns on Table {
  TextColumn get id => text().clientDefault(newId)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
}

class Exercises extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get primaryMuscle => text()();

  /// Comma-separated.
  TextColumn get secondaryMuscles => text().withDefault(const Constant(''))();
  TextColumn get equipment => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('strength'))();
  IntColumn get trackingType => intEnum<TrackingType>()();

  /// Steps separated by newlines.
  TextColumn get instructions => text().withDefault(const Constant(''))();

  /// Relative path inside free-exercise-db, e.g. "Barbell_Squat/0.jpg".
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  IntColumn get defaultRestSeconds => integer().withDefault(const Constant(90))();

  /// Lower = more popular (null = not ranked). Used to list the most popular
  /// exercises of a muscle group first.
  IntColumn get popularity => integer().nullable()();

  /// Duplicates hidden from the list (kept so old workouts still show them).
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  /// "beginner" / "intermediate" / "expert" (from free-exercise-db).
  TextColumn get level => text().nullable()();

  /// Logged per side: every set is a left + right pair (user setting; the
  /// seed marks common one-sided exercises).
  BoolColumn get unilateral => boolean().withDefault(const Constant(false))();

  /// The user's permanent note (shown as a sticky note in workouts).
  TextColumn get note => text().nullable()();
  DateTimeColumn get noteAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Templates extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get folder => text().nullable()();

  /// Heart-rate zone preset applied when the template is started.
  TextColumn get hrPresetId => text().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class TemplateExercises extends Table with SyncColumns {
  TextColumn get templateId => text().references(Templates, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get position => integer()();
  IntColumn get targetSets => integer().withDefault(const Constant(3))();
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();
  IntColumn get supersetGroup => integer().nullable()();

  /// For the "Stretching" session slot: the stretches, comma-separated ids.
  TextColumn get subExerciseIds => text().nullable()();

  /// Target sets as JSON: [{"t": setType, "w": kg, "r": reps, "s": seconds}].
  TextColumn get setsJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Workouts extends Table with SyncColumns {
  IntColumn get type => intEnum<WorkoutType>()();
  TextColumn get name => text()();
  DateTimeColumn get startedAt => dateTime()();

  /// Null while the workout is in progress.
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get templateId => text().nullable()();
  TextColumn get hrPresetId => text().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get avgHr => integer().nullable()();
  IntColumn get maxHr => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutExercises extends Table with SyncColumns {
  TextColumn get workoutId => text().references(Workouts, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get position => integer()();
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();
  IntColumn get supersetGroup => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutSets extends Table with SyncColumns {
  TextColumn get workoutId => text().references(Workouts, #id, onDelete: KeyAction.cascade)();
  TextColumn get workoutExerciseId => text().references(WorkoutExercises, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get setIndex => integer()();
  IntColumn get setType => intEnum<SetType>().withDefault(const Constant(1))();
  RealColumn get weightKg => real().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationS => integer().nullable()();
  RealColumn get distanceM => real().nullable()();
  RealColumn get rpe => real().nullable()();

  /// In a "Stretching" session: which stretch this row is.
  TextColumn get subExerciseId => text().nullable()();

  /// Left / right for one-sided exercises (null = both sides / not split).
  IntColumn get side => intEnum<Side>().nullable()();
  IntColumn get maxHr => integer().nullable()();

  /// Null = not completed (not counted in stats).
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Simple key/value store for user settings.
/// Body measurements: weight, body fat, circumferences…
class BodyMeasurements extends Table with SyncColumns {
  DateTimeColumn get date => dateTime()();

  /// Key from `measurementKinds` (e.g. "weight", "waist") or a custom name.
  TextColumn get kind => text()();
  RealColumn get value => real()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stored by index – only ever add at the end.
enum GoalType { workoutsPerWeek, liftWeight, measurement, runKmPerWeek, runDistance, runTime }

class Goals extends Table with SyncColumns {
  IntColumn get type => intEnum<GoalType>()();
  RealColumn get target => real()();

  /// Where the user started (for measurement goals: weight 85 → 80).
  RealColumn get startValue => real().nullable()();
  TextColumn get exerciseId => text().nullable()();
  TextColumn get measurementKind => text().nullable()();
  DateTimeColumn get deadline => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get achievedAt => dateTime().nullable()();

  /// Run time goals: the distance in metres ("5 km under 25 min").
  RealColumn get distanceM => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Which kind of workout a heart-rate preset is meant for.
enum PresetUse { any, strength, run }

/// A named heart-rate range ("Easy run 130–145").
class HrPresets extends Table with SyncColumns {
  TextColumn get name => text()();
  IntColumn get minBpm => integer()();
  IntColumn get maxBpm => integer()();
  IntColumn get use => intEnum<PresetUse>().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Interval timer preset: segments as JSON + rounds.
class IntervalPresets extends Table with SyncColumns {
  TextColumn get name => text()();

  /// [{"l": label, "s": seconds, "w": isWork}]
  TextColumn get segmentsJson => text()();
  IntColumn get rounds => integer().withDefault(const Constant(1))();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stored by index – only add at the end.
enum RunKind { outdoor, treadmill }

/// A GPS run. While it is being recorded `endedAt` is null; the moving time
/// is (pausedAt ?? now) − startedAt − pausedS.
class Runs extends Table with SyncColumns {
  TextColumn get name => text().withDefault(const Constant('Run'))();
  DateTimeColumn get startedAt => dateTime()();

  /// Null while the run is being recorded.
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// Set while paused: when the pause started.
  DateTimeColumn get pausedAt => dateTime().nullable()();

  /// Seconds spent in earlier (finished) pauses.
  IntColumn get pausedS => integer().withDefault(const Constant(0))();

  /// Moving time in seconds (kept up to date while recording).
  IntColumn get durationS => integer().withDefault(const Constant(0))();
  RealColumn get distanceM => real().withDefault(const Constant(0))();
  TextColumn get hrPresetId => text().nullable()();
  IntColumn get avgHr => integer().nullable()();
  IntColumn get maxHr => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// Fastest time per record distance inside this run, JSON {"1000": 251.3,
  /// "5000": …} (seconds). Null = not worked out yet (computed on demand).
  TextColumn get bestsJson => text().nullable()();

  /// Outdoor (GPS) or treadmill (distance typed in at the end).
  IntColumn get kind => intEnum<RunKind>().withDefault(const Constant(0))();

  /// How hard it felt, 1–10 (null = not rated).
  IntColumn get effort => integer().nullable()();

  /// Weather tags, comma-separated ("sunny,windy").
  TextColumn get weather => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One GPS fix of a run (about one per second while moving).
class RunPoints extends Table with SyncColumns {
  TextColumn get runId => text().references(Runs, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get time => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();

  /// Metres (GPS accuracy radius / altitude).
  RealColumn get accuracy => real().nullable()();
  RealColumn get altitude => real().nullable()();

  /// Pauses split the route: points of different segments are not joined.
  IntColumn get segment => integer().withDefault(const Constant(0))();

  /// Heart rate at this point (null without a signal).
  IntColumn get hr => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Exercises done one side at a time, logged as left + right by default.
const defaultUnilateral = [
  'hz_bulgarian_split_squat',
  'One-Arm_Dumbbell_Row',
  'Dumbbell_Step_Ups',
  'Single_Leg_Glute_Bridge',
  'One_Arm_Lat_Pulldown',
  'Concentration_Curls',
  'Tricep_Dumbbell_Kickback',
  'hz_cable_kickback',
  'Glute_Kickback',
  'Crossover_Reverse_Lunge',
  'hz_side_plank',
  'Hamstring_Stretch',
  'Quad_Stretch',
  'Kneeling_Hip_Flexor',
  'hz_pigeon_pose',
  'Ankle_On_The_Knee',
  'Shoulder_Stretch',
  'Triceps_Stretch',
  'Side_Neck_Stretch',
  'Calf_Stretch_Hands_Against_Wall',
  'Worlds_Greatest_Stretch',
  'Lying_Crossover',
];

@DriftDatabase(
  tables: [
    Exercises,
    Templates,
    TemplateExercises,
    Workouts,
    WorkoutExercises,
    WorkoutSets,
    Settings,
    BodyMeasurements,
    Goals,
    HrPresets,
    IntervalPresets,
    Runs,
    RunPoints,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.addColumn(exercises, exercises.popularity);
      if (from < 3) {
        await m.addColumn(workoutSets, workoutSets.subExerciseId);
        await m.addColumn(templateExercises, templateExercises.subExerciseIds);
      }
      if (from < 4) {
        await m.addColumn(exercises, exercises.hidden);
        await m.addColumn(templateExercises, templateExercises.setsJson);
        await m.createTable(bodyMeasurements);
        await m.createTable(goals);
      }
      if (from < 5) {
        await m.addColumn(exercises, exercises.level);
        await m.addColumn(templates, templates.hrPresetId);
        await m.addColumn(workouts, workouts.hrPresetId);
        await m.createTable(hrPresets);
        await m.createTable(intervalPresets);
      }
      if (from < 6) {
        await m.addColumn(exercises, exercises.unilateral);
        await m.addColumn(exercises, exercises.note);
        await m.addColumn(exercises, exercises.noteAt);
        await m.addColumn(workoutSets, workoutSets.side);
        // Existing installs: mark the common one-sided exercises (new ones get
        // it from the seed).
        await customUpdate(
          'UPDATE exercises SET unilateral = 1 WHERE id IN (${defaultUnilateral.map((_) => '?').join(',')})',
          variables: [for (final id in defaultUnilateral) Variable.withString(id)],
          updates: {exercises},
        );
      }
      if (from < 7) {
        await m.createTable(runs);
        await m.createTable(runPoints); // its index is created in beforeOpen
      }
      // Before v7 the runs table is created above, already with this column.
      if (from == 7) await m.addColumn(runs, runs.bestsJson);
      // Before v4 the goals table is created above, already with this column.
      if (from >= 4 && from < 9) await m.addColumn(goals, goals.distanceM);
      if (from >= 7 && from < 10) {
        await m.addColumn(runs, runs.kind);
        await m.addColumn(runs, runs.effort);
        await m.addColumn(runs, runs.weather);
      }
    },
    beforeOpen: (details) async {
      await _addMissingColumns();
      await customStatement(_runPointsIndex);
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Safety net for upgrades: adds any column the code expects but the stored
  /// table lacks (e.g. if a migration step was forgotten). Only works for
  /// nullable/defaulted columns – keep new columns that way.
  Future<void> _addMissingColumns() async {
    final m = createMigrator();
    for (final table in allTables) {
      final rows = await customSelect('PRAGMA table_info("${table.actualTableName}")').get();
      if (rows.isEmpty) {
        // A whole table is missing (forgotten createTable in a migration).
        await m.createTable(table as TableInfo<Table, dynamic>);
        continue;
      }
      final existing = {for (final r in rows) r.read<String>('name')};
      for (final column in table.$columns) {
        if (!existing.contains(column.name)) await m.addColumn(table, column);
      }
    }
  }

  /// Points are always read per run, in time order (created on every open, so
  /// new installs and upgrades both get it).
  static const _runPointsIndex = 'CREATE INDEX IF NOT EXISTS run_points_by_run ON run_points (run_id, time)';

  static QueryExecutor _open() => driftDatabase(
    name: 'hrzones',
    web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
  );
}
