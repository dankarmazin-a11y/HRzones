import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/backup/backup.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/exercise_repository.dart' show SettingsAccess;
import 'package:drift/drift.dart' show Value;
import 'package:hrzones/workout/active_workout.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'hybrid_test.dart' show hybridServices;
import 'run_test.dart' show FakeLocation;
import 'test_helpers.dart';

/// Phase 4 check (2026-11-13): bugs found in the full review.
void main() {
  test('zone beeps stop when a strength workout with a zone ends (finish and discard)', () async {
    final s = await testServices();
    final id = await s.presets.save(name: 'Z2', min: 120, max: 140, use: PresetUse.any);
    final preset = await s.presets.byId(id);

    await s.session.startEmpty(preset: preset);
    expect(s.hr.running, isTrue);
    await s.session.finish();
    expect(s.hr.running, isFalse, reason: 'monitoring used to keep running after the workout');

    await s.session.startEmpty(preset: preset);
    expect(s.hr.running, isTrue);
    await s.session.discard();
    expect(s.hr.running, isFalse);
    await s.close();
  });

  test('monitoring switched on by hand before the workout stays on', () async {
    final s = await testServices();
    final id = await s.presets.save(name: 'Z2', min: 120, max: 140, use: PresetUse.any);
    await s.hr.start();
    await s.session.startEmpty(preset: await s.presets.byId(id));
    await s.session.finish();
    expect(s.hr.running, isTrue, reason: 'the workout did not start it');
    await s.hr.stop();
    await s.close();
  });

  test('a run restored after the app was closed turns its zone beeps back on', () async {
    final s = await testServices();
    s.run.location = FakeLocation();
    final id = await s.presets.save(name: 'Easy', min: 130, max: 150, use: PresetUse.any);
    await s.run.start(preset: await s.presets.byId(id));
    await s.run.flush();
    // The app is killed: monitoring is gone with it.
    await s.hr.stop();

    s.run.location = FakeLocation();
    await s.run.restore();
    expect(s.hr.running, isTrue);
    expect(s.hr.range.min, 130);
    await s.run.finish();
    expect(s.hr.running, isFalse, reason: 'the restored run switches it off again at the end');
    await s.close();
  });

  test('zones switched off: a restored run does not start monitoring', () async {
    final s = await testServices();
    s.run.location = FakeLocation();
    final id = await s.presets.save(name: 'Easy', min: 130, max: 150, use: PresetUse.any);
    await s.run.start(preset: await s.presets.byId(id));
    await s.run.flush();
    await s.setZonesEnabled(false);
    await s.run.restore();
    expect(s.hr.running, isFalse);
    await s.run.discard();
    await s.close();
  });

  test('finishing or discarding a workout during a GPS Run set turns GPS off', () async {
    final s = await hybridServices();
    for (final end in ['finish', 'discard']) {
      final gps = FakeLocation();
      s.run.location = gps;
      await s.session.startEmpty();
      await s.session.addExercises([(await s.exercises.byId('hz_run'))!]);
      final e = s.session.active!.exercises.single;
      await s.session.startSetRun(e, e.sets.first);
      expect(gps.listening, isTrue);
      end == 'finish' ? await s.session.finish() : await s.session.discard();
      expect(gps.listening, isFalse, reason: end);
      expect(s.session.setRun, isNull, reason: end);
    }
    await s.close();
  });

  test('editing a past workout keeps a set with only metres; Add set copies the metres', () async {
    final s = await hybridServices();
    await s.session.startEmpty();
    await s.session.addExercises([(await s.exercises.byId('hz_run'))!]);
    final e = s.session.active!.exercises.single;
    s.session.setDistance(e.sets.single, 1000);
    s.session.addSet(e);
    expect(e.sets.last.distanceM, 1000, reason: 'Add set copies the metres');
    s.session.toggleDone(e, e.sets.first);
    final summary = await s.session.finish();
    final workoutId = summary!.workout.id;

    // Save through an edit session.
    final session = WorkoutSession(workouts: s.workouts, exercises: s.exercises, hr: s.hr, editMode: true);
    expect(await session.loadForEdit(workoutId), isTrue);
    session.active!.exercises.single.sets.add(LoggedSet()..distanceM = 400);
    await session.saveEdits();
    final saved = (await s.workouts.loadById(workoutId))!.exercises.single.sets;
    expect(saved.map((x) => x.distanceM), [1000, 400], reason: 'the metres-only set used to be dropped');
    await s.close();
  });

  test('backups are compact (format 2) and old format-1 backups still restore', () async {
    final a = await testServices();
    a.run.location = FakeLocation();
    await a.run.start();
    await a.run.finish();
    final bytes = await createBackup(a.db);
    final json = jsonDecode(utf8.decode(const GZipDecoder().decodeBytes(bytes))) as Map<String, dynamic>;
    expect(json['format'], 2);
    final runs = (json['tables'] as Map)['runs'] as Map;
    expect(runs['columns'], contains('id'));
    expect((runs['rows'] as List), hasLength(1));
    expect(backupInfo(readBackup(bytes)).workouts, 0);

    // A format-1 backup (one map per row) from an older app version.
    final old = {
      'app': 'hrzones',
      'format': 1,
      'tables': {
        'settings': [
          {'key': 'weeklyTarget', 'value': '5'},
        ],
      },
    };
    final b = await testServices();
    await restoreBackup(b.db, readBackup(utf8.encode(jsonEncode(old))));
    expect(await b.db.getSetting('weeklyTarget'), '5');
    await a.close();
    await b.close();
  });

  test('a backup with thousands of GPS points goes back and forth intact', () async {
    final a = await testServices();
    final runId = newId();
    final start = DateTime(2026, 11, 1, 7);
    await a.runs.saveRun(RunsCompanion.insert(id: Value(runId), startedAt: start, endedAt: Value(start)));
    await a.runs.addPoints([
      for (var i = 0; i < 12000; i++)
        RunPointsCompanion.insert(
          runId: runId,
          time: start.add(Duration(seconds: i)),
          lat: 32 + i / 1e5,
          lon: 34.8,
        ),
    ]);
    final bytes = await createBackup(a.db);
    final b = await testServices();
    await restoreBackup(b.db, readBackup(bytes));
    final points = await b.runs.points(runId);
    expect(points, hasLength(12000));
    expect(points.last.lat, closeTo(32 + 11999 / 1e5, 1e-9));
    await a.close();
    await b.close();
  });
}
