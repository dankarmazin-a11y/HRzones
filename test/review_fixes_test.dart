import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/template_repository.dart';
import 'package:hrzones/ui/workout/active_workout_screen.dart';
import 'package:hrzones/workout/template_update.dart';

import 'test_helpers.dart';

void main() {
  test('a template with plain sets of a one-sided exercise: an unchanged workout asks nothing', () async {
    final s = await testServices();
    await s.exercises.setUnilateral('Barbell_Bench_Press', true);
    final id = await s.templates.save(
      name: 'Legs',
      slots: [
        TemplateSlot(
          exerciseId: 'Barbell_Bench_Press',
          targetSets: 2,
          sets: const [TemplateSet(weightKg: 20, reps: 10), TemplateSet(weightKg: 20, reps: 10)],
        ),
      ],
    );
    final t = (await s.templates.byId(id))!;
    await s.session.startFromTemplate(t);
    final e = s.session.active!.exercises.single;
    expect(e.sets.length, 4); // 1L 1R 2L 2R
    for (final set in e.sets) {
      s.session.toggleDone(e, set);
    }
    s.session.stopTimer();
    final done = (await s.session.finish())!.workout;
    expect(compareToTemplate(t, done), TemplateChange.none);

    // Values only keeps one row per side.
    await s.session.startFromTemplate(t);
    final e2 = s.session.active!.exercises.single;
    s.session.setWeight(e2.sets.first, 22.5);
    for (final set in e2.sets) {
      s.session.toggleDone(e2, set);
    }
    s.session.stopTimer();
    final w2 = (await s.session.finish())!.workout;
    expect(compareToTemplate(t, w2), TemplateChange.valuesOnly);
    final slots = templateWithNewValues(t, w2);
    expect(slots.single.sets.map((x) => x.side), [Side.left, Side.right, Side.left, Side.right]);
    expect(slots.single.sets.first.weightKg, 22.5);
    await s.close();
  });

  test('"previous" lines up when an exercise switches to left/right', () async {
    final s = await testServices();
    await s.exercises.setUnilateral('Barbell_Bench_Press', false);
    await s.session.startEmpty();
    await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
    var e = s.session.active!.exercises.single;
    s.session.addSet(e);
    s.session.setWeight(e.sets[0], 40);
    s.session.setWeight(e.sets[1], 50);
    for (final set in e.sets) {
      s.session.setReps(set, 8);
      s.session.toggleDone(e, set);
    }
    s.session.stopTimer();
    await s.session.finish();

    await s.exercises.setUnilateral('Barbell_Bench_Press', true);
    await s.session.startEmpty();
    await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
    e = s.session.active!.exercises.single;
    s.session.addSet(e);
    expect([for (var i = 0; i < 4; i++) e.previousFor(i)?.weightKg], [40, 40, 50, 50]);
    await s.session.discard();
    await s.close();
  });

  testWidgets('keyboard Next skips buttons and goes to the next number field', (tester) async {
    final a = TextEditingController(text: '60'), b = TextEditingController(text: '8');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SetNumberField(controller: a, hint: '', onChanged: (_) {}),
              IconButton(onPressed: () {}, icon: const Icon(Icons.check)),
              InkWell(onTap: () {}, child: const Text('RPE')),
              SetNumberField(controller: b, hint: '', onChanged: (_) {}),
              Builder(
                builder: (c) => TextButton(onPressed: () => focusNextNumberField(c), child: const Text('Next')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    focusNextNumberField(tester.element(find.text('Next')));
    await tester.pump();
    final focused = FocusManager.instance.primaryFocus!.context!;
    // ignore: avoid_print
    expect(focused.findAncestorWidgetOfExactType<TextField>()?.controller, b);
  });
}
