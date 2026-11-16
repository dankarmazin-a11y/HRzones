import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
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
}
