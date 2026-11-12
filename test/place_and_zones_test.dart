import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/data/template_repository.dart';
import 'package:hrzones/workout/starter_programs.dart';
import 'package:hrzones/workout/training_level.dart';
import 'package:hrzones/workout/training_place.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  test('starter programs only use equipment of their place; every place has every level', () {
    final list = (jsonDecode(File('assets/exercises.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
    final byId = {for (final e in list) e['id'] as String: e};
    for (final p in starterPrograms) {
      for (final w in p.workouts) {
        for (final e in w.exercises) {
          final eq = byId[e.id]?['equipment'] as String?;
          expect(p.place.allows(eq), isTrue, reason: '${p.name}: ${e.id} needs $eq');
        }
      }
    }
    for (final place in TrainingPlaceInfo.concrete) {
      for (final l in TrainingLevel.values) {
        expect(starterPrograms.where((p) => p.place == place && p.level == l), isNotEmpty, reason: '$place $l');
      }
    }
  });

  test('where you train filters the exercise list and is saved', () async {
    final s = await testServices();
    Future<List<String>> names() async {
      final r = await s.exercises.search(allowedEquipment: s.effectivePlace().equipment);
      return [...r.popular, ...r.others].map((e) => e.id).toList();
    }

    expect(await names(), contains('Barbell_Bench_Press'));
    await s.setPlace(TrainingPlace.outdoors);
    expect(await names(), isNot(contains('Barbell_Bench_Press')));
    expect(await names(), contains('Pullups'));
    expect(await s.db.getSetting('place'), 'outdoors');

    // Hybrid: everything outside a workout, the day's place inside one.
    await s.setPlace(TrainingPlace.hybrid);
    expect(await names(), contains('Barbell_Bench_Press'));
    await s.session.setWorkoutPlace(TrainingPlace.home);
    expect(s.effectivePlace(inWorkout: true), TrainingPlace.home);
    expect(await s.db.getSetting('workoutPlace'), 'home');
    await s.close();
  });

  test('zones switched off: templates do not start monitoring', () async {
    final s = await testServices();
    final presetId = await s.presets.save(name: 'Z2', min: 120, max: 140, use: PresetUse.any);
    final id = await s.templates.save(
      name: 'Push',
      hrPresetId: presetId,
      slots: [TemplateSlot(exerciseId: 'Barbell_Bench_Press')],
    );
    final t = (await s.templates.watchAll().first).firstWhere((t) => t.template.id == id);

    await s.setZonesEnabled(false);
    expect(await s.db.getSetting('zones'), '0');
    await s.session.startFromTemplate(t);
    expect(s.hr.running, isFalse);
    await s.session.discard();

    await s.setZonesEnabled(true);
    await s.session.startFromTemplate(t);
    expect(s.hr.running, isTrue);
    await s.hr.stop();
    await s.session.discard();
    await s.close();
  });

  testWidgets('zones switch hides presets; hybrid asks where you train', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.runAsync(() => s.setPlace(TrainingPlace.hybrid));
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);

    await openTools(tester);
    await settle(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('toolZones')), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('toolZones')));
    await settle(tester);
    expect(find.byKey(const Key('newPreset')), findsOneWidget);
    await tester.tap(find.byKey(const Key('zonesSwitch')));
    await settle(tester);
    expect(find.byKey(const Key('newPreset')), findsNothing);
    expect(s.zonesEnabled.value, isFalse);
    await tester.pageBack();
    await settle(tester);
    expect(find.text('Off – tap to turn them on'), findsOneWidget);
    await tester.pageBack(); // Tools › Home
    await settle(tester);

    await tester.tap(find.text('Home').last);
    await settle(tester);
    await tapStartTile(tester, 'startStrength');
    await settle(tester);
    expect(find.text('Where are you training today?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('place-outdoors')));
    await settle(tester);
    expect(find.text('Finish'), findsOneWidget);
    expect(s.session.workoutPlace, TrainingPlace.outdoors);
    expect(find.byKey(const Key('presetRow')), findsNothing); // zones are off

    await tester.tap(find.text('Exercises'));
    await settle(tester);
    expect(find.text('Pullups'), findsWidgets);
    expect(find.text('Barbell Bench Press'), findsNothing);
    await tester.runAsync(s.session.discard);
    await tearDownApp(tester, s);
  });
}
