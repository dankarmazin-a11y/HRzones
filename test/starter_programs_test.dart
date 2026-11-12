import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/workout/starter_programs.dart';
import 'package:hrzones/workout/training_level.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  test('every starter exercise exists in the exercise list and is not hidden', () {
    final raw = jsonDecode(File('assets/exercises.json').readAsStringSync());
    final list = (raw is Map ? raw['exercises'] : raw) as List;
    final byId = {for (final e in list.cast<Map<String, dynamic>>()) e['id'] as String: e};
    for (final p in starterPrograms) {
      expect(p.workouts, isNotEmpty, reason: p.name);
      for (final w in p.workouts) {
        for (final e in w.exercises) {
          expect(byId[e.id], isNotNull, reason: '${p.name} / ${w.name}: ${e.id} missing');
          expect(byId[e.id]!['hidden'], isNot(true), reason: '${e.id} is hidden');
          expect(
            [e.reps, e.seconds, e.metres].where((x) => x != null).length,
            1,
            reason: '${e.id}: reps, seconds or metres',
          );
        }
      }
    }
    for (final l in TrainingLevel.values) {
      expect(starterPrograms.where((p) => p.level == l), isNotEmpty, reason: 'no program for $l');
    }
  });

  test('adding a program saves its workouts as templates in a folder', () async {
    final s = await testServices();
    final p = starterPrograms.firstWhere((p) => p.name == 'Strength 5×5');
    // The test exercise list is small: use ids it knows.
    final program = StarterProgram(
      name: p.name,
      level: p.level,
      schedule: p.schedule,
      description: p.description,
      workouts: const [
        StarterWorkout('5×5 A', [StarterExercise('Barbell_Bench_Press', 5, reps: 5, rest: 180, warmups: 1)]),
        StarterWorkout('Core', [StarterExercise('Plank', 3, seconds: 30)]),
      ],
    );
    await addProgramToTemplates(s.templates, program);
    final saved = await s.templates.watchAll().first;
    expect(saved.map((t) => t.template.name), ['5×5 A', 'Core']);
    expect(saved.every((t) => t.template.folder == 'Strength 5×5'), isTrue);
    final bench = saved.first.slots.single;
    expect(bench.sets.length, 6);
    expect(bench.sets.first.type, SetType.warmup);
    expect(bench.sets.last.reps, 5);

    // Starting one right away (without saving) prefills targets.
    await s.session.startFromTemplate(starterTemplate(program, program.workouts.last));
    final plank = s.session.active!.exercises.single;
    expect(s.session.active!.templateId, isNull);
    expect(plank.sets.map((x) => x.durationS), [30, 30, 30]);
    await s.session.discard();
    await s.close();
  });

  testWidgets('Tools tab opens heart-rate zones and timers', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await openTools(tester);
    await settle(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('toolZones')), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('toolZones')));
    await settle(tester);
    expect(find.byKey(const Key('newPreset')), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('toolTimers')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('toolTimers')));
    await settle(tester);
    expect(find.byKey(const Key('newTimer')), findsOneWidget);
    await tearDownApp(tester, s);
  });

  testWidgets('starter programs list follows the level chips', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.text('Strength').last);
    await settle(tester);
    await tester.tap(find.byKey(const Key('starterPrograms')));
    await settle(tester);
    expect(find.text('Upper / Lower'), findsOneWidget); // default level: intermediate
    await tester.tap(find.text('Beginner'));
    await settle(tester);
    expect(find.text('Full Body A/B'), findsOneWidget);
    expect(find.text('Upper / Lower'), findsNothing);
    await tester.tap(find.text('Full Body A/B'));
    await settle(tester);
    expect(find.text('Full Body A'), findsOneWidget);
    expect(find.byKey(const Key('addProgram')), findsOneWidget);
    await tearDownApp(tester, s);
  });
}
