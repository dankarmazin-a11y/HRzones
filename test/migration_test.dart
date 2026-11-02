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
/// tables, then the `popularity` column removed and user_version set to
/// [userVersion].
Future<File> oldDatabase(int userVersion) async {
  final dir = Directory.systemTemp.createTempSync('hrzones');
  final file = File('${dir.path}/db.sqlite');
  final db = AppDatabase(NativeDatabase(file));
  await db.customSelect('SELECT 1').get(); // opening creates the tables
  await db.close();

  final downgrade = AppDatabase(
    NativeDatabase(
      file,
      setup: (raw) {
        raw.execute('ALTER TABLE exercises DROP COLUMN popularity');
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

void main() {
  for (final (label, version) in [('v1 database is upgraded', 1), ('missing column is repaired', 2)]) {
    test(label, () async {
      final file = await oldDatabase(version);
      final s = await AppServices.open(
        loadExercises: () async => testExercisesJson,
        db: AppDatabase(NativeDatabase(file)),
        hr: HrMonitor(beeper: SilentBeeper()),
      );
      final cols = await s.db.customSelect('PRAGMA table_info(exercises)').get();
      expect(cols.map((r) => r.read<String>('name')), contains('popularity'));
      expect((await s.exercises.all()).length, 3);
      await s.close();
    });
  }
}
