import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/notify/rest_notifier.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

Future<AppServices> services(SilentRestNotifier n) => AppServices.open(
  loadExercises: () async => testExercisesJson,
  db: memoryDb(),
  hr: HrMonitor(beeper: SilentBeeper()),
  restNotifier: n,
);

void main() {
  test('a workout with no change for 90 min counts as forgotten; a reminder is scheduled', () async {
    final n = SilentRestNotifier();
    final s = await services(n);
    await s.session.startEmpty();
    await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
    await s.session.flush();
    expect(n.idleScheduled.last.inMinutes, closeTo(90, 1)); // 90 min after the last change
    expect(s.session.idleFor, lessThan(WorkoutSession.idleAfter));

    // Saving when the app goes to the background is not a change.
    final w = s.session.active!;
    w.lastChangeAt = DateTime.now().subtract(const Duration(hours: 3));
    await s.session.flush();
    final reloaded = await s.workouts.loadActive();
    expect(DateTime.now().difference(reloaded!.lastChangeAt).inHours, 3);
    expect(s.session.idleFor, greaterThanOrEqualTo(WorkoutSession.idleAfter));

    // A running timer means you're still training.
    s.session.startRest(60);
    expect(s.session.idleFor, Duration.zero);
    s.session.stopTimer();

    await s.session.keepGoing();
    expect(s.session.idleFor, lessThan(const Duration(minutes: 1)));

    final cancelled = n.idleCancelled;
    await s.session.discard();
    expect(n.idleCancelled, cancelled + 1);
    await s.close();
  });

  test('the reminder can be turned off', () async {
    final n = SilentRestNotifier();
    final s = await services(n);
    await s.setIdleReminder(false);
    await s.session.startEmpty();
    await s.session.flush();
    expect(n.idleScheduled, isEmpty);
    expect(
      await s.db
          .customSelect("SELECT value FROM settings WHERE key = 'idleReminder'")
          .getSingle()
          .then((r) => r.read<String>('value')),
      '0',
    );
    await s.session.discard();
    await s.close();
  });

  testWidgets('back in the app: "Still working out?" → finish at the last set', (tester) async {
    final n = SilentRestNotifier();
    final lastSet = DateTime.now().subtract(const Duration(hours: 9, minutes: 50));
    final s = (await tester.runAsync(() async {
      final s = await services(n);
      await s.session.startEmpty();
      await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
      final e = s.session.active!.exercises.single;
      s.session.setWeight(e.sets.single, 60);
      s.session.setReps(e.sets.single, 5);
      s.session.toggleDone(e, e.sets.single);
      s.session.stopTimer();
      e.sets.single.completedAt = lastSet;
      s.session.active!.lastChangeAt = lastSet;
      await s.session.flush();
      return s;
    }))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    expect(find.byKey(const Key('forgottenWorkout')), findsOneWidget);
    await tester.tap(find.byKey(const Key('finishAtLastSet')));
    await settle(tester);
    await settle(tester);
    expect(find.text('Workout complete'), findsOneWidget);
    expect(s.session.active, isNull);
    final row = (await tester.runAsync(() => s.workouts.watchFinished().first))!.single.workout;
    expect(row.endedAt!.difference(lastSet).inMinutes, 1); // ended at the last set, not now
    await tearDownApp(tester, s);
  });
}
