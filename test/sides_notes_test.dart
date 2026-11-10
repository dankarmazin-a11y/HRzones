import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/ui/exercises/exercise_detail_screen.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/template_repository.dart';
import 'package:hrzones/ui/workout/running_workout_bar.dart';
import 'package:hrzones/ui/workout/active_workout_screen.dart';
import 'package:hrzones/workout/template_update.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  test('each side: sets come in left/right pairs; rest only after the right side', () async {
    final s = await testServices();
    await s.session.startEmpty();
    final bench = (await s.exercises.byId('Barbell_Bench_Press'))!;
    await s.session.addExercises([bench]);
    final e = s.session.active!.exercises.single;
    s.session.setWeight(e.sets.single, 20);
    await s.session.setUnilateral(e, true);
    expect(e.sets.map((x) => x.side), [Side.left, Side.right]);
    expect(e.sets.map((x) => x.weightKg), [20, 20]);
    expect((await s.exercises.byId('Barbell_Bench_Press'))!.unilateral, isTrue); // remembered

    s.session.addSet(e);
    expect(e.sets.map((x) => x.side), [Side.left, Side.right, Side.left, Side.right]);

    s.session.setReps(e.sets[0], 8);
    s.session.toggleDone(e, e.sets[0]);
    expect(s.session.timer, isNull); // left done → right next, no rest
    s.session.setReps(e.sets[1], 8);
    s.session.toggleDone(e, e.sets[1]);
    expect(s.session.timer?.kind, TimerKind.rest);
    s.session.stopTimer();

    s.session.removeSet(e, e.sets[3]); // removing one side removes the pair
    expect(e.sets.length, 2);

    final summary = await s.session.finish();
    expect(summary!.setCount, 1); // a pair is one set
    expect(summary.volume, 2 * 20 * 8); // both sides count

    await s.session.startEmpty();
    await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
    final e2 = s.session.active!.exercises.single;
    expect(e2.sets.map((x) => x.side), [Side.left, Side.right]); // new workouts start split
    await s.session.setUnilateral(e2, false);
    expect(e2.sets.map((x) => x.side), [null]);
    await s.session.discard();
    await s.close();
  });

  test('timed holds: left, 5 s switch, then right starts by itself', () async {
    final beeper = SilentBeeper();
    final s = await testServices(beeper: beeper);
    await s.session.startEmpty();
    final plank = (await s.exercises.byId('Plank'))!;
    await s.exercises.setUnilateral(plank.id, true);
    await s.session.addExercises([(await s.exercises.byId(plank.id))!]);
    final card = s.session.active!.exercises.single; // stretching card in the test data
    expect(card.sets.map((x) => x.side), [Side.left, Side.right]);
    s.session.setDuration(card.sets[0], 1);
    s.session.setDuration(card.sets[1], 1);
    s.session.startSetTimer(card, card.sets[0]);
    expect(s.session.timer!.label, endsWith('left'));
    await wait(1300);
    expect(s.session.timer!.label, 'Switch sides');
    expect(s.session.timer!.total, WorkoutSession.switchSidesSeconds);
    expect(s.session.nextUpLabel, isNotNull);
    s.session.stopTimer(); // (don't wait 5 s in a test)
    expect(card.sets[0].done, isTrue);
    await s.session.discard();
    await s.close();
  });

  test('template update: nothing / values / structure, and values-only keeps the exercises', () async {
    final s = await testServices();
    await s.exercises.setUnilateral('Barbell_Bench_Press', false);
    final id = await s.templates.save(
      name: 'Push',
      slots: [
        TemplateSlot(
          exerciseId: 'Barbell_Bench_Press',
          targetSets: 2,
          sets: const [TemplateSet(weightKg: 60, reps: 8), TemplateSet(weightKg: 60, reps: 8)],
        ),
        TemplateSlot(exerciseId: 'Pullups', targetSets: 1, sets: const [TemplateSet(reps: 8)]),
      ],
    );
    final t = (await s.templates.byId(id))!;

    Future<TemplateChange> run(void Function(dynamic e1, dynamic e2) edit) async {
      await s.session.startFromTemplate(t);
      final w = s.session.active!;
      edit(w.exercises[0], w.exercises[1]);
      for (final e in w.exercises) {
        for (final set in e.sets) {
          s.session.toggleDone(e, set);
        }
      }
      s.session.stopTimer();
      final summary = await s.session.finish();
      return compareToTemplate(t, summary!.workout);
    }

    expect(await run((_, _) {}), TemplateChange.none);
    expect(await run((b, _) => s.session.setWeight(b.sets[1], 62.5)), TemplateChange.valuesOnly);
    expect(await run((_, p) => s.session.addSet(p)), TemplateChange.structure);

    // Values only: pull-ups keep 1 set even though 2 were done.
    await s.session.startFromTemplate(t);
    final w = s.session.active!;
    s.session.setWeight(w.exercises[0].sets[0], 65);
    s.session.addSet(w.exercises[1]);
    for (final e in w.exercises) {
      for (final set in e.sets) {
        s.session.toggleDone(e, set);
      }
    }
    s.session.stopTimer();
    final done = (await s.session.finish())!.workout;
    final slots = templateWithNewValues(t, done);
    expect(slots[0].sets.map((x) => x.weightKg), [65, 65]);
    expect(slots[1].sets.length, 1);
    await s.close();
  });

  testWidgets('a permanent note shows as a sticky note in the workout', (tester) async {
    final s = (await tester.runAsync(() async {
      final s = await testServices();
      await s.exercises.setNote('Barbell_Bench_Press', 'Seat on 4, grip outside the rings');
      await s.session.startEmpty();
      await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
      s.session.setWorkoutNote(s.session.active!.exercises.single, 'Felt the left shoulder');
      return s;
    }))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.byType(RunningWorkoutBar)); // open the running workout
    await settle(tester);
    expect(find.byKey(const Key('stickyNote')), findsOneWidget);
    expect(find.text('Seat on 4, grip outside the rings'), findsOneWidget);
    expect(find.byKey(const Key('noteBadge')), findsOneWidget, reason: 'yellow label next to the name');
    expect(find.textContaining('Note from '), findsOneWidget);
    expect(find.text('Felt the left shoulder'), findsOneWidget);
    await tester.tap(find.byTooltip('Hide for this workout'));
    await settle(tester);
    expect(find.byKey(const Key('stickyNote')), findsNothing);
    await tester.runAsync(s.session.discard);
    await tearDownApp(tester, s);
  });

  testWidgets('a one-sided set is one row: values fill both sides, a tick for each side', (tester) async {
    final s = (await tester.runAsync(() async {
      final s = await testServices();
      await s.session.startEmpty();
      await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
      final e = s.session.active!.exercises.single;
      await s.session.setUnilateral(e, true);
      return s;
    }))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.byType(RunningWorkoutBar));
    await settle(tester);
    final e = s.session.active!.exercises.single;
    final pairs = e.sets.length ~/ 2;
    expect(find.byType(SetRow), findsNWidgets(pairs), reason: 'one row per L+R pair');
    expect(find.text('1L'), findsNothing);

    await tester.enterText(find.byType(SetNumberField).first, '20');
    await tester.pump();
    expect(e.sets[0].weightKg, 20);
    expect(e.sets[1].weightKg, 20, reason: 'the right side gets the same weight');

    expect(find.byKey(const Key('rightRow_0')), findsOneWidget, reason: 'the right side, collapsed under the left');
    // Tap the right side's weight: it opens as a normal full-size field.
    await tester.tap(find.byKey(const Key('rightFirst_0')));
    await settle(tester);
    expect(find.byKey(const Key('rightFirstField_0')), findsOneWidget);
    expect(find.byKey(const Key('rightSecondField_0')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('rightFirstField_0')), '17.5');
    await tester.pump();
    expect(e.sets[1].weightKg, 17.5);
    expect(e.sets[0].weightKg, 20, reason: 'left unchanged');
    // Leaving the field folds the right side back into its small line.
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester);
    expect(find.byKey(const Key('rightFirstField_0')), findsNothing);
    expect(find.byKey(const Key('rightFirst_0')), findsOneWidget);

    // Only the right side failed: tap R.
    await tester.tap(find.byKey(const Key('rightType_0')));
    await settle(tester);
    expect(e.sets[1].type, SetType.failure);
    expect(e.sets[0].type, SetType.normal, reason: 'left stays a normal set');
    expect(find.text('FR'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rightType_0')));
    await settle(tester);
    expect(e.sets[1].type, SetType.normal);
    // Typing on the left again doesn't overwrite the right side's own number.
    await tester.enterText(find.byType(SetNumberField).first, '22');
    await tester.pump();
    expect(e.sets[0].weightKg, 22);
    expect(e.sets[1].weightKg, 17.5);

    await tester.tap(find.byKey(const Key('tickL_0')));
    await settle(tester);
    expect(e.sets[0].done, isTrue);
    expect(e.sets[1].done, isFalse);
    expect(s.session.timer, isNull, reason: 'no rest after the left side');
    await tester.tap(find.byKey(const Key('tickR_0')));
    await settle(tester);
    expect(e.sets[1].done, isTrue);
    expect(s.session.restRemaining, isNotNull, reason: 'rest after the right side');
    s.session.stopTimer();
    await tester.runAsync(s.session.discard);
    await tearDownApp(tester, s);
  });

  testWidgets('the workout clock keeps ticking with no rest timer running', (tester) async {
    final s = (await tester.runAsync(() async {
      final s = await testServices();
      await s.session.startEmpty();
      return s;
    }))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.byType(RunningWorkoutBar));
    await settle(tester);
    String clock() => tester
        .widget<Text>(find.descendant(of: find.byKey(const Key('workoutClock')), matching: find.byType(Text)))
        .data!;
    final before = clock();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1100))); // real time passes
    await tester.pump(const Duration(seconds: 1)); // the clock's own 1 s timer
    expect(s.session.timer, isNull);
    expect(clock(), isNot(before), reason: 'the clock must tick on its own');
    await tester.runAsync(s.session.discard);
    await tearDownApp(tester, s);
  });

  testWidgets('a permanent note added on the exercise page stays and shows in the workout', (tester) async {
    final s = (await tester.runAsync(() async {
      final s = await testServices();
      await s.session.startEmpty();
      await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
      return s;
    }))!;
    final card = s.session.active!.exercises.single;
    final stale = card.exercise; // what the workout card hands to the page
    // Saved on the page (as the page does it).
    final updated = (await tester.runAsync(() => s.exercises.setNote(stale.id, 'Seat 3, 50 degrees')))!;
    s.session.refreshExercise(updated);
    expect(card.exercise.note, 'Seat 3, 50 degrees', reason: 'the workout card shows it now');

    // Opening the page again with the old copy still shows the saved note.
    await tester.pumpWidget(
      Services(
        services: s,
        child: MaterialApp(home: ExerciseDetailScreen(exercise: stale)),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    expect(find.text('Seat 3, 50 degrees'), findsOneWidget);
    await tester.runAsync(s.session.discard);
    await tearDownApp(tester, s);
  });
}
