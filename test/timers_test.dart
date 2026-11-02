import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'test_helpers.dart';

Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  test('default rest applies to all exercises (not stretches) and is saved', () async {
    final s = await testServices();
    await s.session.startEmpty();
    final bench = (await s.exercises.byId('Barbell_Bench_Press'))!;
    final plank = (await s.exercises.byId('Plank'))!; // stretching category in the test data
    await s.session.addExercises([bench, plank]);
    final w = s.session.active!;
    expect(w.exercises[0].restSeconds, 90);
    expect(w.exercises[1].restSeconds, WorkoutSession.stretchRestSeconds);

    await s.session.setDefaultRest(120);
    expect(w.exercises[0].restSeconds, 120);
    expect(w.exercises[1].restSeconds, WorkoutSession.stretchRestSeconds);
    expect(await s.db.getSetting('defaultRestS'), '120');

    // Per-exercise override still works.
    s.session.setRestSeconds(w.exercises[0], 45);
    expect(w.exercises[0].restSeconds, 45);
    await s.session.discard();
    await s.close();
  });

  test('timed sets count down, beep, rest, then start the next one by themselves', () async {
    final beeper = SilentBeeper();
    final s = await testServices(beeper: beeper);
    await s.session.startEmpty();
    final plank = (await s.exercises.byId('Plank'))!;
    await s.session.addExercises([plank]);
    final e = s.session.active!.exercises.single;
    s.session.addSet(e);
    s.session.setRestSeconds(e, 1);
    s.session.setDuration(e.sets[0], 1);
    s.session.setDuration(e.sets[1], 1);

    s.session.startSetTimer(e, e.sets[0]);
    expect(s.session.timer!.kind, TimerKind.setTimer);
    await wait(1400);
    expect(e.sets[0].done, isTrue);
    expect(s.session.timer!.kind, TimerKind.rest);
    await wait(1200);
    expect(s.session.timer?.kind, TimerKind.setTimer);
    expect(s.session.timer!.set, e.sets[1]);
    await wait(1300);
    expect(e.sets[1].done, isTrue);
    expect(beeper.calls.where((c) => c.startsWith('beep 880x2')).length, 2);
    s.session.stopTimer();
    await s.session.discard();
    await s.close();
  });

  test('stopping a running timed set saves the time held', () async {
    final s = await testServices();
    await s.session.startEmpty();
    await s.session.addExercises([(await s.exercises.byId('Plank'))!]);
    final e = s.session.active!.exercises.single;
    s.session.setDuration(e.sets[0], 60);
    s.session.startSetTimer(e, e.sets[0]);
    await wait(1100);
    s.session.stopTimer(); // "Done" in the timer bar
    expect(e.sets[0].done, isTrue);
    expect(e.sets[0].durationS, 1);
    s.session.stopTimer(); // skip the rest that started
    await s.session.discard();
    await s.close();
  });

  test('standalone countdown and stopwatch', () async {
    final beeper = SilentBeeper();
    final s = await testServices(beeper: beeper);
    await s.session.startEmpty();
    s.session.startCountdown(1);
    expect(s.session.timer!.label, 'Timer');
    await wait(1300);
    expect(s.session.timer, isNull);
    expect(beeper.calls, contains('beep 880x3'));

    s.session.startStopwatch();
    await wait(1100);
    expect(s.session.timer!.elapsed, greaterThanOrEqualTo(1));
    s.session.stopTimer();
    expect(s.session.timer, isNull);
    await s.session.discard();
    await s.close();
  });

  test('tracking type can be switched inside a workout', () async {
    final s = await testServices();
    await s.session.startEmpty();
    await s.session.addExercises([(await s.exercises.byId('Pullups'))!]);
    final e = s.session.active!.exercises.single;
    await s.session.setTrackingType(e, TrackingType.weightReps);
    expect(e.exercise.trackingType, TrackingType.weightReps);
    expect((await s.exercises.byId('Pullups'))!.trackingType, TrackingType.weightReps);
    await s.session.discard();
    await s.close();
  });
}
