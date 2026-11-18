import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/ui/timer_style.dart';
import 'package:hrzones/ui/workout/running_workout_bar.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

/// Owner's workout notes (2026-11-18).
void main() {
  test('screen-on holds are counted, and the app never lets go of a hold it never took', () async {
    screenHolds = 0;
    await keepScreenOn(false);
    expect(screenHolds, 0, reason: 'closing without opening must not touch the phone setting');
    await keepScreenOn(true); // full-screen timer
    await keepScreenOn(true); // interval screen on top
    await keepScreenOn(false);
    expect(screenHolds, 1, reason: 'one screen still wants it on');
    await keepScreenOn(false);
    expect(screenHolds, 0);
  });

  test('the timer line knows what is left to the millisecond (smooth, not once a second)', () {
    final t = RunningTimer(kind: TimerKind.rest, total: 60);
    expect(t.fractionLeft, closeTo(1, 0.01));
    expect(t.fractionLeft, lessThanOrEqualTo(1));
    expect(RunningTimer(kind: TimerKind.stopwatch, total: 0).fractionLeft, 1);
  });

  testWidgets('tapping the set number shows no grey box', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.runAsync(() async {
      await s.session.startEmpty();
      await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
    });
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.byType(RunningWorkoutBar));
    await settle(tester);
    final set = s.session.active!.exercises.single.sets.first;
    final ink = tester.widget<InkWell>(find.byKey(Key('setNumber_${set.id}')));
    expect(ink.highlightColor, Colors.transparent);
    expect(ink.splashFactory, NoSplash.splashFactory);
    await tester.runAsync(s.session.discard);
    await tearDownApp(tester, s);
  });
}
