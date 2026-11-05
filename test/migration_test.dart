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
          raw.execute(d.startsWith('DROP TABLE') ? d : 'ALTER TABLE $d');
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
const _v5Changes = [
  'exercises DROP COLUMN level',
  'templates DROP COLUMN hr_preset_id',
  'workouts DROP COLUMN hr_preset_id',
  'DROP TABLE hr_presets',
  'DROP TABLE interval_presets',
];
const _v6Columns = [
  'exercises DROP COLUMN unilateral',
  'exercises DROP COLUMN note',
  'exercises DROP COLUMN note_at',
  'workout_sets DROP COLUMN side',
];
const _v7Changes = ['DROP TABLE run_points', 'DROP TABLE runs'];
const _v8Columns = ['runs DROP COLUMN bests_json'];
const _v9Columns = ['goals DROP COLUMN distance_m'];
const _v10Columns = ['runs DROP COLUMN kind', 'runs DROP COLUMN effort', 'runs DROP COLUMN weather'];
const _v11Changes = ['runs DROP COLUMN shoe_id', 'DROP TABLE shoes'];
const _shoes = ['DROP TABLE shoes'];
const _v4Changes = [
  'exercises DROP COLUMN hidden',
  'template_exercises DROP COLUMN sets_json',
  'DROP TABLE body_measurements',
  'DROP TABLE goals',
];

void main() {
  final cases = [
    (
      'v1 database is upgraded',
      1,
      [..._v2Columns, ..._v3Columns, ..._v4Changes, ..._v5Changes, ..._v6Columns, ..._v7Changes, ..._shoes],
    ),
    (
      'v2 database is upgraded',
      2,
      [..._v3Columns, ..._v4Changes, ..._v5Changes, ..._v6Columns, ..._v7Changes, ..._shoes],
    ),
    ('v3 database is upgraded', 3, [..._v4Changes, ..._v5Changes, ..._v6Columns, ..._v7Changes, ..._shoes]),
    ('v4 database is upgraded', 4, [..._v5Changes, ..._v6Columns, ..._v7Changes, ..._v9Columns, ..._shoes]),
    ('v5 database is upgraded', 5, [..._v6Columns, ..._v7Changes, ..._v9Columns, ..._shoes]),
    ('v6 database is upgraded', 6, [..._v7Changes, ..._v9Columns, ..._shoes]),
    ('v7 database is upgraded', 7, [..._v8Columns, ..._v9Columns, ..._v10Columns, ..._v11Changes]),
    ('v8 database is upgraded', 8, [..._v9Columns, ..._v10Columns, ..._v11Changes]),
    ('v9 database is upgraded', 9, [..._v10Columns, ..._v11Changes]),
    ('v10 database is upgraded', 10, _v11Changes),
    ('missing column/table is repaired', 11, [..._v2Columns, 'DROP TABLE goals']),
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
      expect(await cols('template_exercises'), contains('sets_json'));
      expect(await cols('exercises'), contains('hidden'));
      expect(await cols('body_measurements'), contains('kind'));
      expect(await cols('goals'), containsAll(['target', 'distance_m']));
      expect(await cols('exercises'), contains('level'));
      expect(await cols('workouts'), contains('hr_preset_id'));
      expect(await cols('templates'), contains('hr_preset_id'));
      expect(await cols('hr_presets'), contains('min_bpm'));
      expect(await cols('interval_presets'), contains('segments_json'));
      expect(await cols('exercises'), containsAll(['unilateral', 'note', 'note_at']));
      expect(await cols('workout_sets'), contains('side'));
      expect(
        await cols('runs'),
        containsAll(['distance_m', 'paused_s', 'duration_s', 'bests_json', 'kind', 'effort', 'weather']),
      );
      expect(await cols('run_points'), containsAll(['run_id', 'lat', 'lon', 'segment', 'hr']));
      if (version < 6) {
        // Existing installs get the common one-sided exercises marked.
        expect((await s.exercises.byId('Hamstring_Stretch'))!.unilateral, isTrue);
      }
      expect((await s.exercises.all()).length, greaterThan(0));
      await s.close();
    });
  }
}
