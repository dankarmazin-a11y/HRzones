import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/data/workout_repository.dart';
import 'package:hrzones/workout/ab_workouts.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  test('every move exists in the exercise list, with a start and end picture', () async {
    final repo = ExerciseRepository(memoryDb());
    await repo.seedIfNeeded(() async => File('assets/exercises.json').readAsString());
    for (final w in abWorkouts) {
      for (final m in w.moves) {
        final e = await repo.byId(m.exerciseId);
        expect(e, isNotNull, reason: '${w.id}: ${m.exerciseId}');
        expect(e!.hidden, isFalse, reason: m.exerciseId);
        expect(moveImage(e, second: true), endsWith('1.jpg'));
      }
    }
  });

  test('timing: move, rest, …, round break, no rest at the very end', () {
    final ten = abWorkouts.firstWhere((w) => w.id == 'abs10');
    final p = ten.plan();
    expect(p.steps.where((s) => s.work), hasLength(10));
    expect(p.steps.where((s) => !s.work), hasLength(9));
    expect(p.steps.last.work, isTrue);
    expect(ten.minutes, 10);
    final core = abWorkouts.firstWhere((w) => w.id == 'core15');
    expect(core.plan().steps.where((s) => s.label == 'Round break'), hasLength(1));
    expect(core.plan().moves.whereType<AbMove>(), hasLength(14));
    for (final w in abWorkouts) {
      expect(w.minutes, inInclusiveRange(5, 21), reason: w.id);
    }
  });

  test('a finished workout is saved to the history', () async {
    final db = memoryDb();
    final exercises = ExerciseRepository(db);
    await exercises.seedIfNeeded(() async => File('assets/exercises.json').readAsString());
    final workouts = WorkoutRepository(db, exercises);
    final w = abWorkouts.firstWhere((w) => w.id == 'abs10');
    final start = DateTime(2026, 11, 10, 8);
    await saveAbWorkout(w, exercises, workouts, startedAt: start, endedAt: start.add(const Duration(minutes: 10)));
    final saved = (await workouts.watchFinished().first).single;
    expect(saved.workout.name, '10-minute abs');
    final detail = (await workouts.loadById(saved.workout.id))!;
    expect(detail.exercises, hasLength(9), reason: 'side plank left + right = one exercise');
    final side = detail.exercises.firstWhere((e) => e.exercise.id == 'Side_Bridge');
    expect(side.sets.map((s) => s.durationS), [40, 40]);
  });

  testWidgets('Tools › Ab workouts: follow along to the end, ✓, saved, back', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await openTools(tester);
    await settle(tester);
    await tester.tap(find.byKey(const Key('toolAbs')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('ab_abs5')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('startAbWorkout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Get ready'), findsOneWidget);
    // Skip through every step.
    for (var i = 0; i < 40 && find.byKey(const Key('skipAbStep')).evaluate().isNotEmpty; i++) {
      await tester.tap(find.byKey(const Key('skipAbStep')));
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(find.text('Saved to your history'), findsOneWidget);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(find.byKey(const Key('closeAbWorkout')), findsNothing, reason: 'closed by itself');
    final done = (await tester.runAsync(() => s.workouts.watchFinished().first))!;
    expect(done.single.workout.name, 'Quick abs');
    await tearDownApp(tester, s);
  });
}
