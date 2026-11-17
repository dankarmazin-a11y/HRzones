import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/ui/workout/active_workout_screen.dart' show platePreview;
import 'package:hrzones/beep/sounds.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/workout/workout_session.dart';
import 'package:hrzones/ui/workout/running_workout_bar.dart';
import 'package:hrzones/ui/workout/timer_widgets.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

/// Owner's workout notes (2026-11-16).
void main() {
  testWidgets('▶ on a timed set (crunch 60 s, plank) opens the full-screen timer by itself', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.runAsync(() async {
      await s.session.startEmpty();
      await s.session.addExercises([(await s.exercises.byId('Plank'))!]);
    });
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.byType(RunningWorkoutBar));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.play_circle).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(FullScreenTimer), findsOneWidget);
    expect(s.session.timer, isNotNull);
    s.session.stopTimer();
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(find.byType(FullScreenTimer), findsNothing, reason: 'closes by itself when the chain is over');
    await tester.runAsync(s.session.discard);
    await tearDownApp(tester, s);
  });

  test('end-of-workout stats: reps, working vs resting, heaviest set, calories', () async {
    final s = await testServices();
    await s.session.startEmpty();
    await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
    final e = s.session.active!.exercises.single;
    s.session.setWeight(e.sets.first, 60);
    s.session.setReps(e.sets.first, 8);
    s.session.toggleDone(e, e.sets.first);
    s.session.addSet(e);
    s.session.setWeight(e.sets.last, 70);
    s.session.setReps(e.sets.last, 5);
    s.session.toggleDone(e, e.sets.last);
    final sum = (await s.session.finish(endedAt: s.session.active!.startedAt.add(const Duration(minutes: 30))))!;
    expect(sum.reps, 13);
    expect(sum.working, const Duration(seconds: 39), reason: '13 reps × 3 s');
    expect(sum.resting, const Duration(minutes: 30) - const Duration(seconds: 39));
    expect(sum.heaviestSet!.weightKg, 70);
    expect(sum.calories(), isNull, reason: 'no body weight');
    expect(sum.calories(weightKg: 80)!.round(), 200, reason: 'MET 5 × 80 kg × ½ h');
    expect(strengthCalories(durationS: 1800, weightKg: 80, avgHr: 130, age: 35)!, greaterThan(200));
    await s.close();
  });

  test('mute silences the app sounds; tapping the set number switches number ↔ F', () async {
    final b = SilentBeeper();
    await b.play(SoundEvent.restOver);
    b.muted.value = true;
    await b.play(SoundEvent.restOver);
    expect(b.calls.where((c) => c.startsWith('ding') || c.startsWith('sound') || c.startsWith('beep')), hasLength(1));
    b.muted.value = false;
    expect(WorkoutSession.setTypeCycle, hasLength(4), reason: 'the long-press menu keeps every type');
  });

  testWidgets('Settings › Sounds has one volume slider for all the sounds', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.text('Profile').last);
    await settle(tester);
    await tester.tap(find.byKey(const Key('openSettings')));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('soundVolume')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byKey(const Key('soundVolume')), const Offset(-400, 0));
    await settle(tester);
    expect(s.hr.volume, lessThan(0.5));
    await tearDownApp(tester, s);
  });

  testWidgets('typing a barbell weight shows its plates above the keyboard', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.runAsync(() async {
      await s.session.startEmpty();
      await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
    });
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.byType(RunningWorkoutBar));
    await settle(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300); // the keyboard is up
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    final kg = find.byType(TextField).first;
    await tester.tap(kg);
    await tester.pump();
    await tester.enterText(kg, '72.5');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    expect(platePreview.value?.kg, 72.5);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50))); // bar + plates settings
    await tester.pump();
    expect(find.byKey(const Key('platePreview')), findsOneWidget);
    expect(find.text('25 · 1.25'), findsOneWidget, reason: '72.5 kg on a 20 kg bar = 26.25 a side');
    await tester.runAsync(s.session.discard);
    await tearDownApp(tester, s);
  });
}
