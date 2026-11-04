import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/data/goal_repository.dart';
import 'package:hrzones/workout/streak.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'test_helpers.dart';

void main() {
  test('template built in the workout view keeps target sets, folder and stretches', () async {
    final s = await testServices();
    final t = WorkoutSession(workouts: s.workouts, exercises: s.exercises, hr: s.hr, templateMode: true);
    await t.loadTemplate(null);
    expect(t.active!.name, 'New template');
    t.rename('Push A');
    t.setTemplateFolder('PPL');
    await t.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!, (await s.exercises.byId('Plank'))!]);
    final bench = t.active!.exercises.firstWhere((e) => e.exercise.id == 'Barbell_Bench_Press');
    t.setWeight(bench.sets.single, 60);
    t.setReps(bench.sets.single, 8);
    t.addSet(bench); // 60 × 8 again
    t.cycleSetType(bench.sets.first); // drop → warm-up? normal → drop
    t.startRest(60);
    expect(t.timer, isNull); // no timers while planning
    await t.saveTemplate(s.templates);

    final saved = (await s.templates.watchAll().first).single;
    expect(saved.template.name, 'Push A');
    expect(saved.template.folder, 'PPL');
    final slot = saved.slots.firstWhere((x) => x.exerciseId == 'Barbell_Bench_Press');
    expect(slot.sets.map((x) => '${x.type.name} ${x.weightKg}×${x.reps}'), ['drop 60.0×8', 'normal 60.0×8']);
    expect(saved.slots.firstWhere((x) => x.exerciseId == stretchingSessionId).subExerciseIds, ['Plank']);

    // Starting it prefills the planned values (not ticked yet).
    await s.session.startFromTemplate(saved);
    final live = s.session.active!.exercises.firstWhere((e) => e.exercise.id == 'Barbell_Bench_Press');
    expect(live.sets.map((x) => x.weightKg), [60, 60]);
    expect(live.sets.every((x) => !x.done), isTrue);

    // Editing the template again and saving keeps the same template.
    final t2 = WorkoutSession(workouts: s.workouts, exercises: s.exercises, hr: s.hr, templateMode: true);
    await t2.loadTemplate(saved);
    t2.rename('Push A v2');
    await t2.saveTemplate(s.templates);
    final all = await s.templates.watchAll().first;
    expect(all.map((x) => x.template.name), ['Push A v2']);
    await s.session.discard();
    t.dispose();
    t2.dispose();
    await s.close();
  });

  group('weekly streak', () {
    final now = DateTime(2026, 11, 4, 12); // Wednesday
    DateTime d(int y, int m, int day) => DateTime(y, m, day, 18);

    test('counts weeks in a row that reached the target', () {
      final w = [
        d(2026, 11, 2), // this week (1)
        d(2026, 10, 27), d(2026, 10, 29), // last week (2)
        d(2026, 10, 20), d(2026, 10, 22), d(2026, 10, 24), // (3)
        d(2026, 10, 6), d(2026, 10, 7), // gap week before
      ];
      final info = weeklyStreak(w, target: 2, now: now);
      expect(info.weeks, 2); // this week not reached yet, but doesn't break the streak
      expect(info.thisWeek, 1);
      expect(info.daysThisWeek, [true, false, false, false, false, false, false]);
      expect(weeklyStreak([...w, d(2026, 11, 3)], target: 2, now: now).weeks, 3);
    });

    test('no workouts → 0', () => expect(weeklyStreak([], target: 3, now: now).weeks, 0));
  });

  test('goal progress works up and down', () {
    expect(progressBetween(80, 100, 90), 0.5); // bench 80 → 100
    expect(progressBetween(90, 80, 85), 0.5); // weight 90 → 80
    expect(progressBetween(90, 80, 95), 0); // went the wrong way
    expect(progressBetween(90, 80, 79), 1);
  });

  test('lift and measurement goals, measurements', () async {
    final s = await testServices();
    // A finished bench workout: 80 kg.
    await s.session.startEmpty();
    await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
    final e = s.session.active!.exercises.single;
    s.session.setWeight(e.sets.single, 80);
    s.session.setReps(e.sets.single, 5);
    s.session.toggleDone(e, e.sets.single);
    s.session.stopTimer();
    await s.session.finish();

    await s.goals.addLift('Barbell_Bench_Press', 100);
    await s.body.add('weight', 90, date: DateTime(2026, 10, 1));
    await s.goals.addMeasurement('weight', 80);
    await s.body.add('weight', 85);

    final goals = await s.goals.watchAll().first;
    final lift = await s.goals.progress(goals[0]);
    expect(lift.title, 'Barbell Bench Press 100 kg');
    expect(lift.current, 80);
    expect(lift.progress, 0); // started at 80
    final weight = await s.goals.progress(goals[1]);
    expect(weight.current, 85);
    expect(weight.progress, 0.5);
    expect((await s.body.history('weight')).map((m) => m.value), [85, 90]);
    await s.close();
  });

  test('duplicates are hidden from the list', () async {
    final s = await testServices();
    await s.db.setSetting('exerciseSeedVersion', '0');
    await s.exercises.seedIfNeeded(() async => File('assets/exercises.json').readAsStringSync());
    final names = (await s.exercises.search()).all.map((e) => e.name).toSet();
    expect(names, isNot(contains('Squats (Band)')));
    expect(names, isNot(contains('Barbell Full Squat (ATG)')));
    expect(names, contains('Barbell Squat'));
    expect((await s.exercises.byId('Barbell_Full_Squat'))!.hidden, isTrue); // still there for old workouts
    expect(titleCase('abductors'), 'Outer thighs');
    await s.close();
  });

  test('a workout left open can end at the last set', () async {
    final s = await testServices();
    await s.session.startEmpty();
    s.session.active!.startedAt = DateTime.now().subtract(const Duration(hours: 48));
    await s.session.addExercises([(await s.exercises.byId('Pullups'))!]);
    final e = s.session.active!.exercises.single;
    s.session.setReps(e.sets.single, 10);
    s.session.toggleDone(e, e.sets.single);
    e.sets.single.completedAt = s.session.active!.startedAt.add(const Duration(minutes: 40));
    s.session.stopTimer();
    final last = s.session.lastSetAt!;
    final summary = (await s.session.finish(endedAt: last.add(const Duration(minutes: 1))))!;
    expect(summary.duration, const Duration(minutes: 41));
    await s.close();
  });
}
