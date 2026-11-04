import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/preset_repository.dart';
import 'package:hrzones/export/export_data.dart';
import 'package:hrzones/export/xlsx_writer.dart';
import 'package:hrzones/workout/interval_runner.dart';
import 'package:hrzones/workout/training_level.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'test_helpers.dart';

void main() {
  test('HR presets: per use, applied when a workout starts, stored in templates', () async {
    final s = await testServices();
    final easy = await s.presets.save(name: 'Easy run', min: 130, max: 145, use: PresetUse.run);
    final rec = await s.presets.save(name: 'Recovery', min: 100, max: 125, use: PresetUse.strength);
    await s.presets.save(name: 'Any', min: 110, max: 150, use: PresetUse.any);
    expect((await s.presets.forUse(PresetUse.strength)).map((p) => p.name), ['Recovery', 'Any']);
    expect((await s.presets.forUse(PresetUse.run)).map((p) => p.name), ['Any', 'Easy run']);

    // Empty workout with a preset: range set, monitoring started, saved on the workout.
    await s.session.startEmpty(preset: await s.presets.byId(rec));
    expect(s.hr.range.min, 100);
    expect(s.hr.range.max, 125);
    expect(s.hr.running, isTrue);
    expect(s.session.active!.hrPresetId, rec);
    await s.hr.stop();
    await s.session.discard();

    // Template with a preset: applied automatically when started.
    final t = WorkoutSession(workouts: s.workouts, exercises: s.exercises, hr: s.hr, templateMode: true)
      ..presets = s.presets;
    await t.loadTemplate(null);
    await t.addExercises([(await s.exercises.byId('Pullups'))!]);
    await t.applyPreset(await s.presets.byId(easy));
    expect(s.hr.running, isFalse); // planning a template doesn't start monitoring
    await t.saveTemplate(s.templates);
    final saved = (await s.templates.watchAll().first).single;
    expect(saved.template.hrPresetId, easy);
    await s.session.startFromTemplate(saved);
    expect(s.hr.range.min, 130);
    expect(s.session.active!.hrPresetId, easy);
    await s.hr.stop();
    await s.session.discard();
    t.dispose();
    await s.close();
  });

  test('training level filters exercises; beginners get simple muscle groups', () async {
    final s = await testServices();
    // Test data has no levels → treated as beginner; mark one intermediate.
    await s.db.customStatement("UPDATE exercises SET level = 'expert' WHERE id = 'Pullups'");
    s.exercises.clearCache();
    final beginner = await s.exercises.search(levels: TrainingLevel.beginner.exerciseLevels);
    expect(beginner.all.map((e) => e.id), isNot(contains('Pullups')));
    final advanced = await s.exercises.search(levels: TrainingLevel.advanced.exerciseLevels);
    expect(advanced.all.map((e) => e.id), contains('Pullups'));
    // Popular exercises are always shown.
    await s.db.customStatement(
      "UPDATE exercises SET level = 'expert', popularity = 1 WHERE id = 'Barbell_Bench_Press'",
    );
    s.exercises.clearCache();
    expect(
      (await s.exercises.search(levels: TrainingLevel.beginner.exerciseLevels)).all.map((e) => e.id),
      contains('Barbell_Bench_Press'),
    );
    // "back" covers lats etc.
    await s.db.customStatement("UPDATE exercises SET level = 'beginner' WHERE id = 'Pullups'");
    s.exercises.clearCache();
    expect((await s.exercises.search(muscle: 'back')).all.map((e) => e.id), contains('Pullups'));
    expect(musclesOf('arms'), ['biceps', 'triceps', 'forearms']);
    expect(simpleGroupOf('hamstrings'), 'legs');
    await s.close();
  });

  group('interval timer', () {
    final tabata = [
      const IntervalSegment(label: 'Work', seconds: 20),
      const IntervalSegment(label: 'Rest', seconds: 10, work: false),
    ];

    test('expands rounds', () {
      final steps = expandSegments(tabata, 8);
      expect(steps.length, 16);
      expect(steps.last.round, 8);
      expect(totalSeconds(tabata, 8), 240);
    });

    test('runs through the steps with beeps', () {
      final beeper = SilentBeeper();
      final r = IntervalRunner(name: 'T', steps: expandSegments(tabata, 2), rounds: 2, beeper: beeper);
      final t0 = DateTime(2026, 1, 1);
      r.begin(t0);
      expect(r.gettingReady, isTrue);
      expect(r.totalRemaining, 3 + 60);
      DateTime at(double s) => t0.add(Duration(milliseconds: (s * 1000).round()));
      for (var ms = 100; ms <= 3100; ms += 100) {
        r.tick(at(ms / 1000));
      }
      expect(r.current!.label, 'Work');
      expect(beeper.calls, contains('beep 1100x2')); // work starts
      r.tick(at(23.1));
      expect(r.current!.label, 'Rest');
      expect(beeper.calls, contains('beep 550x1')); // rest starts
      r.togglePause(at(23.2));
      r.tick(at(30));
      expect(r.current!.label, 'Rest'); // paused
      r.togglePause(at(30));
      r.skip();
      expect(r.current!.round, 2);
      r.tick(at(30 + 20 + 10 + 1));
      expect(r.finished, isTrue);
      expect(beeper.calls.last, 'beep 1200x3');
    });

    test('built-in timers are added once', () async {
      final s = await testServices();
      await s.intervals.seedDefaults();
      final list = await s.intervals.watchAll().first;
      expect(list.map((p) => p.name), contains('Tabata'));
      expect(list.length, defaultIntervalPresets.length);
      await s.close();
    });
  });

  test('spreadsheet export has Workouts, Sets and Measurements', () async {
    final s = await testServices();
    await s.session.startEmpty();
    await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
    final e = s.session.active!.exercises.single;
    s.session.setWeight(e.sets.single, 61.25);
    s.session.setReps(e.sets.single, 5);
    s.session.toggleDone(e, e.sets.single);
    s.session.stopTimer();
    await s.session.finish();
    await s.body.add('weight', 82.4);

    final bytes = await exportWorkbook(s.db);
    final zip = ZipDecoder().decodeBytes(bytes);
    String file(String n) => utf8.decode(zip.findFile(n)!.content as List<int>);
    expect(file('xl/workbook.xml'), allOf(contains('Workouts'), contains('Sets'), contains('Measurements')));
    final sets = file('xl/worksheets/sheet2.xml');
    expect(sets, contains('Barbell Bench Press'));
    expect(sets, contains('<v>61.25</v>'));
    expect(file('xl/worksheets/sheet3.xml'), contains('Body weight'));
    await s.close();
  });

  test('xlsx writer escapes text and names columns past Z', () {
    final bytes = buildXlsx([
      Sheet('Test', [
        ['a & <b>', 1, null, DateTime(2026, 1, 1)],
        [for (var i = 0; i < 28; i++) i],
      ]),
    ]);
    final xml = utf8.decode(ZipDecoder().decodeBytes(bytes).findFile('xl/worksheets/sheet1.xml')!.content as List<int>);
    expect(xml, contains('a &amp; &lt;b&gt;'));
    expect(xml, contains('r="AB2"'));
    expect(xml, contains('<c r="D1" s="2"><v>46023'));
  });
}
