import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/hr/hr_monitor.dart';

import 'test_helpers.dart';

/// A database file as an older app version left it: created with the current
/// tables, then the columns in [drop] ("table DROP COLUMN col") removed and
/// user_version set to [userVersion].
Future<File> oldDatabase(int userVersion, List<String> drop) async {
  final dir = Directory.systemTemp.createTempSync('hrzones');
  final file = File('${dir.path}/db.sqlite');
  final db = AppDatabase(NativeDatabase(file));
  await db.customSelect('SELECT 1').get(); // opening creates the tables
  await db.close();

  final downgrade = AppDatabase(
    NativeDatabase(
      file,
      setup: (raw) {
        for (final d in drop) {
          raw.execute('ALTER TABLE $d');
        }
        raw.execute('PRAGMA user_version = $userVersion');
      },
    ),
  );
  // Must run a query: the file is only opened (and setup run) on first use.
  // Use the raw executor so drift's own migration doesn't run.
  await downgrade.executor.ensureOpen(_NoMigrations());
  await downgrade.executor.close();
  return file;
}

class _NoMigrations implements QueryExecutorUser {
  @override
  int get schemaVersion => 0;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}
}

const _v2Columns = ['exercises DROP COLUMN popularity'];
const _v3Columns = ['workout_sets DROP COLUMN sub_exercise_id', 'template_exercises DROP COLUMN sub_exercise_ids'];

void main() {
  final cases = [
    ('v1 database is upgraded', 1, [..._v2Columns, ..._v3Columns]),
    ('v2 database is upgraded', 2, _v3Columns),
    ('missing column is repaired', 3, _v2Columns),
  ];
  for (final (label, version, drop) in cases) {
    test(label, () async {
      final file = await oldDatabase(version, drop);
      final s = await AppServices.open(
        loadExercises: () async => testExercisesJson,
        db: AppDatabase(NativeDatabase(file)),
        hr: HrMonitor(beeper: SilentBeeper()),
      );
      Future<List<String>> cols(String table) async =>
          (await s.db.customSelect('PRAGMA table_info($table)').get()).map((r) => r.read<String>('name')).toList();
      expect(await cols('exercises'), contains('popularity'));
      expect(await cols('workout_sets'), contains('sub_exercise_id'));
      expect(await cols('template_exercises'), contains('sub_exercise_ids'));
      expect((await s.exercises.all()).length, greaterThan(0));
      await s.close();
    });
  }
}
