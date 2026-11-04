import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/backup/backup.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/data/template_repository.dart';
import 'package:hrzones/ui/backup_section.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

Future<void> logWorkout(AppServices s, {double kg = 60}) async {
  await s.session.startEmpty();
  final bench = (await s.exercises.byId('Barbell_Bench_Press'))!;
  await s.session.addExercises([bench]);
  final e = s.session.active!.exercises.single;
  s.session.setWeight(e.sets.single, kg);
  s.session.setReps(e.sets.single, 5);
  s.session.toggleDone(e, e.sets.single);
  await s.session.finish();
}

void main() {
  test('backup → restore on another phone brings everything back', () async {
    final a = await testServices();
    await logWorkout(a, kg: 80);
    await a.templates.save(
      name: 'Push',
      folder: 'PPL',
      slots: [TemplateSlot(exerciseId: 'Barbell_Bench_Press')],
    );
    await a.presets.save(name: 'Z2', min: 120, max: 140, use: PresetUse.any);
    await a.setWeeklyTarget(4);
    await a.setLastBackupAt(DateTime(2026, 1, 1));
    final bytes = await createBackup(a.db);
    expect(bytes.take(2), [0x1f, 0x8b]); // gzip
    await a.close();

    final b = await testServices();
    await logWorkout(b, kg: 20); // will be replaced
    await b.setLastBackupAt(DateTime(2026, 11, 1));
    final finished = b.workouts.watchFinished();
    final emissions = <int>[];
    final sub = finished.listen((l) => emissions.add(l.length));

    final backup = readBackup(bytes);
    expect(backupInfo(backup).workouts, 1);
    expect(backupInfo(backup).templates, 1);
    await restoreBackup(b.db, backup);
    await b.reloadAfterRestore();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final list = await b.workouts.watchFinished().first;
    expect(list.single.volume, 400); // 80 kg × 5 from the backup, not 20 kg
    expect((await b.templates.watchAll().first).single.template.folder, 'PPL');
    expect((await b.presets.all()).single.name, 'Z2');
    expect(b.weeklyTarget.value, 4);
    // This phone's last-backup time is kept.
    expect(b.lastBackupAt.value, DateTime(2026, 11, 1));
    expect(await b.db.getSetting('lastBackupAt'), DateTime(2026, 11, 1).toIso8601String());
    expect(emissions, isNotEmpty); // open screens are told about the change
    await sub.cancel();
    await b.close();
  });

  test('bad files are refused with a clear message, and nothing changes', () async {
    expect(() => readBackup(utf8.encode('hello')), throwsA(isA<BackupException>()));
    expect(() => readBackup(utf8.encode('{"app": "other", "tables": {}}')), throwsA(isA<BackupException>()));
    expect(
      () => readBackup(utf8.encode('{"app": "hrzones", "format": 99, "tables": {}}')),
      throwsA(isA<BackupException>().having((e) => e.message, 'message', contains('newer version'))),
    );

    final s = await testServices();
    await logWorkout(s);
    // A row that breaks a reference → the whole restore is rolled back.
    final broken = {
      'app': 'hrzones',
      'format': 1,
      'tables': {
        'workout_sets': [
          {
            'id': 'x',
            'workout_id': 'missing',
            'workout_exercise_id': 'missing',
            'exercise_id': 'missing',
            'set_index': 0,
          },
        ],
      },
    };
    await expectLater(restoreBackup(s.db, broken), throwsA(anything));
    expect((await s.workouts.watchFinished().first).length, 1);
    await s.close();
  });

  test('older backups: unknown columns are skipped, missing ones get defaults', () async {
    final s = await testServices();
    final backup = readBackup(
      utf8.encode(
        jsonEncode({
          'app': 'hrzones',
          'format': 1,
          'tables': {
            'hr_presets': [
              {
                'id': 'p1',
                'name': 'Easy',
                'min_bpm': 110,
                'max_bpm': 130,
                'use': 0,
                'updated_at': DateTime(2026).toIso8601String(),
                'column_from_the_past': 1,
              },
            ],
          },
        }),
      ),
    );
    await restoreBackup(s.db, backup);
    await s.reloadAfterRestore();
    expect((await s.presets.all()).single.name, 'Easy');
    // The exercise list comes back by itself (re-seeded).
    expect(await s.exercises.byId('Barbell_Bench_Press'), isNotNull);
    await s.close();
  });

  test('last backup text', () {
    final now = DateTime(2026, 11, 10, 9);
    expect(lastBackupText(null, now: now), 'never');
    expect(lastBackupText(DateTime(2026, 11, 10, 1), now: now), 'today');
    expect(lastBackupText(DateTime(2026, 11, 9, 23), now: now), 'yesterday');
    expect(lastBackupText(DateTime(2026, 11, 1), now: now), '9 days ago');
  });

  testWidgets('Home reminds you to back up once you have workouts', (tester) async {
    final s = (await tester.runAsync(() async {
      final s = await testServices();
      await logWorkout(s);
      return s;
    }))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    expect(find.byKey(const Key('backupReminder')), findsOneWidget);
    expect(find.text('Last backup: never'), findsOneWidget);

    await tester.runAsync(() => s.setLastBackupAt(DateTime.now()));
    await settle(tester);
    expect(find.byKey(const Key('backupReminder')), findsNothing);
    await tearDownApp(tester, s);
  });

  testWidgets('no reminder before the first workout', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    expect(find.byKey(const Key('backupReminder')), findsNothing);
    await tearDownApp(tester, s);
  });
}
