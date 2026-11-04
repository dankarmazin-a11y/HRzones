import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/data/preset_repository.dart';
import 'package:hrzones/ui/plate_calculator.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'test_helpers.dart';

void main() {
  test('interval timers are exercises in their own "Timers" group, kept in sync', () async {
    final s = await testServices();
    final presets = await s.intervals.watchAll().first;
    final timers = (await s.exercises.search(group: ExerciseGroup.timers)).all;
    expect(timers.map((e) => e.name).toSet(), presets.map((p) => p.name).toSet());
    expect(timers.every((e) => e.isInterval && e.isTimed), isTrue);
    // Not mixed into the normal list (only when searching by name).
    expect((await s.exercises.search()).all.where((e) => e.isInterval), isEmpty);
    expect((await s.exercises.search(query: 'tabata')).all.single.isInterval, isTrue);

    final id = await s.intervals.save(
      name: 'My circuit',
      rounds: 2,
      segments: const [
        IntervalSegment(label: 'Go', seconds: 40),
        IntervalSegment(label: 'Rest', seconds: 20, work: false),
      ],
    );
    expect((await s.exercises.byId('$intervalExercisePrefix$id'))!.name, 'My circuit');
    await s.intervals.save(
      id: id,
      name: 'My circuit v2',
      rounds: 2,
      segments: const [IntervalSegment(label: 'Go', seconds: 40)],
    );
    expect((await s.exercises.byId('$intervalExercisePrefix$id'))!.name, 'My circuit v2');
    await s.intervals.delete(id);
    expect((await s.exercises.byId('$intervalExercisePrefix$id'))!.hidden, isTrue); // old workouts keep it
    await s.close();
  });

  test('an interval timer in a workout: one round, done when it ran to the end, then rest', () async {
    final s = await testServices();
    final id = await s.intervals.save(
      name: 'Finisher',
      rounds: 3,
      segments: const [
        IntervalSegment(label: 'Work', seconds: 30),
        IntervalSegment(label: 'Rest', seconds: 15, work: false),
      ],
    );
    final ex = (await s.exercises.byId('$intervalExercisePrefix$id'))!;
    await s.session.startEmpty();
    await s.session.addExercises([ex]);
    final e = s.session.active!.exercises.single;
    expect(e.sets.single.durationS, 3 * 30 + 2 * 15); // last rest dropped
    s.session.completeInterval(e, e.sets.single, seconds: 120);
    expect(e.sets.single.done, isTrue);
    expect(s.session.timer?.kind, TimerKind.rest);
    s.session.stopTimer();
    final summary = await s.session.finish();
    expect(summary!.records, isEmpty); // no "records" for a timer
    await s.close();
  });

  testWidgets('plate calculator: your plates and the bar per exercise are remembered', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    Future<void> show(String? exerciseId) async {
      await tester.pumpWidget(
        Services(
          services: s,
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [PlateCalculator(key: UniqueKey(), initialKg: 62.5, exerciseId: exerciseId)],
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
    }

    await show('Barbell_Bench_Press');
    // 62.5 on a 20 kg bar: 20 + 1.25 per side.
    expect(find.byType(PlateView), findsNWidgets(2));
    await tester.tap(find.widgetWithText(FilterChip, '1.25')); // our gym has no 1.25 kg plates
    await tester.pump();
    expect(find.textContaining("can't be made"), findsOneWidget);
    await tester.tap(find.text('EZ bar 10'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));

    expect(await tester.runAsync(() => s.db.getSetting('plates')), isNot(contains('1.25')));
    expect(await tester.runAsync(() => s.db.getSetting('bar.Barbell_Bench_Press')), 'EZ bar|10.0');

    // Reopened for the same exercise: EZ bar again.
    await show('Barbell_Bench_Press');
    final chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'EZ bar 10'));
    expect(chip.selected, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
