import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

/// How an exercise is logged.
enum TrackingType { weightReps, bodyweightReps, duration, distance }

/// Warm-up / normal / drop / failure.
enum SetType { warmup, normal, drop, failure }

enum WorkoutType { strength, run, walk, cycle, other }

/// Id of the "Stretching" session container exercise.
const stretchingSessionId = 'hz_stretching';

extension ExerciseKind on Exercise {
  bool get isStretch => category == 'stretching';
  bool get isStretchSession => id == stretchingSessionId;
  bool get isTimed => trackingType == TrackingType.duration;
}

/// Exercise library "type" filter.
enum ExerciseGroup { strength, stretching, cardio }

extension ExerciseGroupOf on Exercise {
  ExerciseGroup get group => switch (category) {
    'stretching' => ExerciseGroup.stretching,
    'cardio' || 'plyometrics' => ExerciseGroup.cardio,
    _ => ExerciseGroup.strength,
  };
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

  @override
  Set<Column> get primaryKey => {id};
}

class Templates extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get folder => text().nullable()();
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
  IntColumn get maxHr => integer().nullable()();

  /// Null = not completed (not counted in stats).
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Simple key/value store for user settings.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Exercises, Templates, TemplateExercises, Workouts, WorkoutExercises, WorkoutSets, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.addColumn(exercises, exercises.popularity);
      if (from < 3) {
        await m.addColumn(workoutSets, workoutSets.subExerciseId);
        await m.addColumn(templateExercises, templateExercises.subExerciseIds);
      }
    },
    beforeOpen: (details) async {
      await _addMissingColumns();
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
      if (rows.isEmpty) continue; // table not created yet
      final existing = {for (final r in rows) r.read<String>('name')};
      for (final column in table.$columns) {
        if (!existing.contains(column.name)) await m.addColumn(table, column);
      }
    }
  }

  static QueryExecutor _open() => driftDatabase(
    name: 'hrzones',
    web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
  );
}
