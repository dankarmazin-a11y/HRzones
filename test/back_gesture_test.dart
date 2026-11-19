import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/platform/phone_system.dart';
import 'package:hrzones/ui/workout/active_workout_screen.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

/// Android back button / back gesture (docs/ANDROID.md rule 27).
void main() {
  testWidgets('back while editing a past workout asks before dropping the changes', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    final edit = WorkoutSession(workouts: s.workouts, exercises: s.exercises, hr: s.hr, editMode: true)
      ..startManual(DateTime(2026, 11, 1, 18), const Duration(minutes: 30));
    await tester.runAsync(() async => edit.addExercises([(await s.exercises.byId('Pullups'))!]));
    edit.setReps(edit.active!.exercises.single.sets.single, 10);
    expect(edit.hasUnsavedEdits, isTrue);

    await tester.pumpWidget(
      Services(
        services: s,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => ActiveWorkoutScreen(session: edit))),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    expect(find.byType(ActiveWorkoutScreen), findsOneWidget);

    // Back: the question, and the editor stays.
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byKey(const Key('discardEdits')), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await settle(tester);
    expect(find.byType(ActiveWorkoutScreen), findsOneWidget);
    expect(edit.active, isNotNull);

    // Back again and discard: the editor closes.
    await tester.binding.handlePopRoute();
    await settle(tester);
    await tester.tap(find.text('Discard'));
    await settle(tester);
    expect(find.byType(ActiveWorkoutScreen), findsNothing);
    await tearDownApp(tester, s);
    edit.dispose();
  });

  testWidgets('back on another tab goes to Home first', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    NavigationBar bar() => tester.widget<NavigationBar>(find.byType(NavigationBar));

    await tester.tap(find.text('Profile').last);
    await settle(tester);
    expect(bar().selectedIndex, 4);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(bar().selectedIndex, 0, reason: 'back from Profile goes Home instead of closing the app');
    await tearDownApp(tester, s);
  });

  testWidgets('Android: back on Home puts the app in the background instead of closing it', (tester) async {
    const channel = MethodChannel('hrzones/system');
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return true;
    });
    PhoneSystem.hasNative = true;
    addTearDown(() {
      PhoneSystem.hasNative = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);

    final closed = await tester.binding.handlePopRoute();
    await settle(tester);
    expect(calls, ['toBack'], reason: 'closing the app would stop a running workout and leave its card');
    expect(closed, isTrue, reason: 'Back was handled by the app (no SystemNavigator.pop)');
    expect(find.byType(HomeShell), findsOneWidget);
    await tearDownApp(tester, s);
  });
}
