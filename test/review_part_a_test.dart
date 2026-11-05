import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/ui/workout/active_workout_screen.dart';
import 'package:hrzones/ui/workout/workout_editor.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'test_helpers.dart';

Future<String> logBench(AppServices s, double kg, int reps) async {
  await s.session.startEmpty();
  final bench = (await s.exercises.byId('Barbell_Bench_Press'))!;
  await s.session.addExercises([bench]);
  final e = s.session.active!.exercises.single;
  s.session.setWeight(e.sets.single, kg);
  s.session.setReps(e.sets.single, reps);
  s.session.toggleDone(e, e.sets.single);
  s.session.stopTimer();
  final summary = await s.session.finish();
  return summary!.workout.id;
}

void main() {
  test('tapping the set number cycles number → F → W → D', () async {
    final s = await testServices();
    await s.session.startEmpty();
    await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
    final set = s.session.active!.exercises.single.sets.single;
    final seen = <SetType>[set.type];
    for (var i = 0; i < 4; i++) {
      s.session.cycleSetType(set);
      seen.add(set.type);
    }
    expect(seen, [SetType.normal, SetType.failure, SetType.warmup, SetType.drop, SetType.normal]);
    s.session.setSetType(set, SetType.drop); // long-press menu
    expect(set.type, SetType.drop);
    await s.session.discard();
    await s.close();
  });

  test('a record is detected when a set is ticked (not on the first workout)', () async {
    final s = await testServices();
    await logBench(s, 60, 5);
    await s.session.startEmpty();
    await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
    final e = s.session.active!.exercises.single;
    s.session.addSet(e);
    final (a, b) = (e.sets[0], e.sets[1]);
    s.session.setWeight(a, 50);
    s.session.setReps(a, 5);
    s.session.toggleDone(e, a);
    expect(await s.session.isRecord(e, a), isFalse); // lighter
    s.session.setWeight(b, 65);
    s.session.setReps(b, 3);
    s.session.toggleDone(e, b);
    expect(await s.session.isRecord(e, b), isTrue); // heavier than ever
    s.session.stopTimer();
    await s.session.discard();
    await s.close();
  });

  test('repeat an old workout now, or save it as a template', () async {
    final s = await testServices();
    final id = await logBench(s, 80, 5);
    expect(await s.session.startFromWorkout(id), isTrue);
    final e = s.session.active!.exercises.single;
    expect(e.sets.single.weightKg, 80);
    expect(e.sets.single.done, isFalse); // a target, not ticked
    await s.session.discard();

    final old = (await s.workouts.loadById(id))!;
    await s.templates.save(name: old.name, slots: WorkoutSession.slotsFrom(old));
    final t = (await s.templates.watchAll().first).single;
    expect(t.slots.single.sets.single.weightKg, 80);
    await s.close();
  });

  test('goals can be edited', () async {
    final s = await testServices();
    await s.goals.addLift('Barbell_Bench_Press', 100);
    final g = (await s.goals.watchAll().first).single;
    await s.goals.updateGoal(g.id, target: 110, deadline: DateTime(2027, 6, 1));
    final edited = (await s.goals.watchAll().first).single;
    expect(edited.target, 110);
    expect(edited.deadline, DateTime(2027, 6, 1));
    await s.close();
  });

  test('templates use the saved default rest, not 1:30', () async {
    final s = await testServices();
    await s.session.setDefaultRest(60);
    final t = templateSession(s);
    await t.loadTemplate(null);
    await t.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
    expect(t.active!.exercises.single.restSeconds, 60);
    t.dispose();
    await s.close();
  });

  testWidgets('tapping a number selects it all, so typing replaces it', (tester) async {
    final c = TextEditingController(text: '62.5');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SetNumberField(controller: c, hint: '', onChanged: (_) {}, decimal: true),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump();
    expect(c.selection, const TextSelection(baseOffset: 0, extentOffset: 4));
  });
}
