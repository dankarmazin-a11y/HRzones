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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _open() => driftDatabase(
    name: 'hrzones',
    web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
  );
}
