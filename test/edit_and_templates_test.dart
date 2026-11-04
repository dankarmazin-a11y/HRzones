import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/data/template_repository.dart';
import 'package:hrzones/ui/body_map.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  test('edit a finished workout: change values, add a set, save', () async {
    final s = await testServices();
    final bench = (await s.exercises.byId('Barbell_Bench_Press'))!;
    await s.session.startEmpty();
    await s.session.addExercises([bench]);
    var e = s.session.active!.exercises.single;
    s.session.setWeight(e.sets.single, 60);
    s.session.setReps(e.sets.single, 5);
    s.session.toggleDone(e, e.sets.single);
    s.session.stopTimer();
    final done = (await s.session.finish())!;

    final edit = WorkoutSession(workouts: s.workouts, exercises: s.exercises, hr: s.hr, editMode: true);
    expect(await edit.loadForEdit(done.workout.id), isTrue);
    e = edit.active!.exercises.single;
    edit.setWeight(e.sets.single, 62.5);
    edit.addSet(e); // copies 62.5 × 5, not ticked
    edit.toggleDone(e, e.sets.last);
    expect(edit.timer, isNull); // no rest timer while editing
    expect(edit.hasUnsavedEdits, isTrue);
    final summary = (await edit.saveEdits())!;
    expect(summary.setCount, 2);
    expect(summary.volume, 62.5 * 5 * 2);

    final reloaded = (await s.workouts.loadById(done.workout.id))!;
    expect(reloaded.exercises.single.sets.map((x) => x.weightKg), [62.5, 62.5]);
    expect((await s.workouts.workoutRow(done.workout.id))!.endedAt, isNotNull);

    // Cancel in edit mode must not delete the workout.
    final edit2 = WorkoutSession(workouts: s.workouts, exercises: s.exercises, hr: s.hr, editMode: true);
    await edit2.loadForEdit(done.workout.id);
    await edit2.discard();
    expect(await s.workouts.workoutRow(done.workout.id), isNotNull);
    edit.dispose();
    edit2.dispose();
    await s.close();
  });

  test('log a past workout with date and duration', () async {
    final s = await testServices();
    final start = DateTime(2026, 10, 30, 18, 0);
    final edit = WorkoutSession(workouts: s.workouts, exercises: s.exercises, hr: s.hr, editMode: true)
      ..startManual(start, const Duration(minutes: 45));
    await edit.addExercises([(await s.exercises.byId('Pullups'))!]);
    final e = edit.active!.exercises.single;
    edit.setReps(e.sets.single, 10);
    edit.addSet(e);
    edit.setReps(e.sets.last, 8);
    edit.addSet(e);
    edit.setReps(e.sets.last, null); // empty set is dropped on save
    final summary = (await edit.saveEdits())!;
    expect(summary.workout.startedAt, start);
    expect(summary.duration, const Duration(minutes: 45));
    expect(summary.setCount, 2);
    final history = await s.workouts.watchFinished().first;
    expect(history.single.workout.startedAt, start);
    expect(s.session.active, isNull); // the live session is untouched
    edit.dispose();
    await s.close();
  });

  test('template folders and duplicate', () async {
    final s = await testServices();
    await s.templates.save(
      name: 'Push A',
      folder: 'PPL',
      slots: [TemplateSlot(exerciseId: 'Barbell_Bench_Press')],
    );
    await s.templates.save(
      name: 'Mobility',
      slots: [TemplateSlot(exerciseId: 'Plank')],
    );
    expect(await s.templates.folders(), ['PPL']);
    final push = (await s.templates.watchAll().first).firstWhere((t) => t.template.name == 'Push A');
    await s.templates.duplicate(push);
    final all = await s.templates.watchAll().first;
    final copy = all.firstWhere((t) => t.template.name == 'Push A (copy)');
    expect(copy.template.folder, 'PPL');
    expect(copy.slots.single.exerciseId, 'Barbell_Bench_Press');
    await s.close();
  });

  test('body map regions', () {
    expect(muscleAt(const Offset(0.4, 0.2), back: false), 'chest');
    expect(muscleAt(const Offset(0.5, 0.35), back: false), 'abdominals');
    expect(muscleAt(const Offset(0.4, 0.6), back: false), 'quadriceps');
    expect(muscleAt(const Offset(0.4, 0.6), back: true), 'hamstrings');
    expect(muscleAt(const Offset(0.5, 0.38), back: true), 'lower back');
    expect(muscleAt(const Offset(0.02, 0.02), back: true), isNull);
  });

  testWidgets('tapping the body map filters the exercise list', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.text('Strength').last);
    await settle(tester);
    await tester.tap(find.text('Exercises'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('toggleBodyMap')));
    await settle(tester);
    final front = tester.getRect(find.byKey(const Key('bodyMapFront')));
    await tester.tapAt(Offset(front.left + front.width * 0.4, front.top + front.height * 0.2)); // chest
    await settle(tester);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Pullups'), findsNothing);
    await tearDownApp(tester, s);
  });
}
