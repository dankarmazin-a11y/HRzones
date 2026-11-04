import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/hr/simulated_hr_source.dart';

import 'test_helpers.dart';

/// Lets real async work (database queries) run, then rebuilds.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Unmounts the app so drift stream subscriptions are cancelled.
/// (The in-memory DB is not closed: closing inside the fake clock hangs.)
Future<void> tearDownApp(WidgetTester tester, AppServices s) async {
  await tester.pumpWidget(const SizedBox());
  await settle(tester);
  s.hr.stop();
}

void main() {
  testWidgets('shows 5 tabs and switches between them', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);

    expect(find.textContaining('streak'), findsOneWidget);
    for (final (tab, title) in [
      ('Strength', 'Strength'),
      ('Run', 'Run'),
      ('Tools', 'Tools'),
      ('Profile', 'Profile'),
      ('Home', 'Good'),
    ]) {
      await tester.tap(find.text(tab).last);
      await settle(tester);
      expect(find.descendant(of: find.byType(AppBar), matching: find.textContaining(title)), findsWidgets);
    }
    await tearDownApp(tester, s);
  });

  testWidgets('start an empty workout, add an exercise, log a set', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);

    await tester.tap(find.byKey(const Key('startStrength')));
    await settle(tester);
    expect(find.text('Finish'), findsOneWidget);

    await tester.tap(find.text('Exercises'));
    await settle(tester);
    await tester.tap(find.text('Barbell Bench Press'));
    await settle(tester);
    await tester.tap(find.text('Add 1'));
    await settle(tester);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('PREVIOUS'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '60');
    await tester.enterText(fields.at(1), '8');
    await tester.tap(find.byIcon(Icons.check_box_outline_blank));
    await settle(tester);
    expect(find.textContaining('Rest '), findsOneWidget);
    expect(s.session.active!.completedSets.single.weightKg, 60);

    await tester.tap(find.text('Skip'));
    await tester.tap(find.text('Finish'));
    await settle(tester);
    await settle(tester);
    expect(find.text('Workout complete'), findsOneWidget);
    expect(find.text('480 kg'), findsOneWidget);
    await tearDownApp(tester, s);
  });

  testWidgets('hold an exercise name → compact list → drag to reorder', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.runAsync(() async {
      await s.session.startEmpty();
      await s.session.addExercises([
        (await s.exercises.byId('Barbell_Bench_Press'))!,
        (await s.exercises.byId('Pullups'))!,
      ]);
    });
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    // The running-workout bar above the tabs opens the workout.
    expect(find.byKey(const Key('runningWorkoutBar')), findsOneWidget);
    expect(find.textContaining('0% done'), findsOneWidget);
    await tester.tap(find.byKey(const Key('runningWorkoutBar')));
    await settle(tester);
    expect(s.session.active!.exercises.map((e) => e.exercise.name), ['Barbell Bench Press', 'Pullups']);

    await tester.longPress(find.text('Barbell Bench Press'));
    await settle(tester);
    expect(find.text('Drag to reorder'), findsOneWidget);
    final handle = find.byIcon(Icons.drag_handle).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await settle(tester);
    expect(s.session.active!.exercises.map((e) => e.exercise.name), ['Pullups', 'Barbell Bench Press']);
    await tester.tap(find.text('Done'));
    await settle(tester);
    await tester.runAsync(s.session.discard);
    await tearDownApp(tester, s);
  });

  testWidgets('measure-type button cycles weight × reps → reps → time', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.runAsync(() async {
      await s.session.startEmpty();
      await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
    });
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.byKey(const Key('runningWorkoutBar')));
    await settle(tester);
    expect(find.text('kg×reps'), findsOneWidget);
    for (final next in ['reps', 'time', 'kg×reps']) {
      await tester.tap(find.byKey(const Key('trackingToggle')));
      await settle(tester);
      expect(find.text(next), findsOneWidget);
    }
    await tester.runAsync(s.session.discard);
    await tearDownApp(tester, s);
  });

  testWidgets('rest bar grows on tap; stretch timer opens full screen', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.runAsync(() async {
      await s.session.startEmpty();
      await s.session.addExercises([(await s.exercises.byId('Hamstring_Stretch'))!]);
    });
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.byKey(const Key('runningWorkoutBar')));
    await settle(tester);

    s.session.startRest(90);
    await tester.pump();
    final small = tester.getSize(find.byKey(const Key('timerBar'))).height;
    await tester.tap(find.byKey(const Key('timerBar')));
    await settle(tester);
    expect(tester.getSize(find.byKey(const Key('timerBar'))).height, greaterThan(small));
    s.session.stopTimer();
    await tester.pump();

    final card = s.session.active!.exercises.single;
    s.session.startSetTimer(card, card.sets.single);
    await tester.pump();
    await tester.tap(find.byKey(const Key('timerBar')));
    await settle(tester);
    expect(find.byKey(const Key('closeFullScreen')), findsOneWidget);
    expect(find.text('Standing Hamstring Stretch'), findsWidgets);
    await tester.tap(find.byKey(const Key('closeFullScreen')));
    await settle(tester);
    s.session.stopTimer();
    s.session.stopTimer();
    await tester.runAsync(s.session.discard);
    await tearDownApp(tester, s);
  });

  testWidgets('monitoring shows simulated bpm and the status', (tester) async {
    final beeper = SilentBeeper();
    final s = (await tester.runAsync(() => testServices(beeper: beeper, source: SimulatedHrSource(bpm: 200))))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);

    await tester.runAsync(() async {
      await s.hr.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.tap(find.text('Tools').last);
    await settle(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('toolZones')), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('toolZones')));
    await settle(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('bpm')), 200);
    expect(tester.widget<Text>(find.byKey(const Key('bpm'))).data, '200');
    expect(find.text('Above range · Zone 5'), findsOneWidget);
    expect(beeper.calls, contains('start'));

    await tester.runAsync(s.hr.stop);
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('bpm'))).data, '--');
    await tearDownApp(tester, s);
  });
}
