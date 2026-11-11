import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/workout/stats.dart';
import 'package:hrzones/workout/training_stats.dart';
import 'package:hrzones/ui/screens/home_screen.dart';
import 'package:hrzones/ui/stats/stats_screen.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  test('sets per muscle: main muscle 1, helpers ½, no warm-ups / stretches / right sides', () async {
    final s = await testServices();
    final byId = {for (final e in await s.exercises.all()) e.id: e};
    const bench = 'Barbell_Bench_Press';
    final sets = [
      const SetStat(exerciseId: bench, type: SetType.normal, weightKg: 60, reps: 8),
      const SetStat(exerciseId: bench, type: SetType.normal, weightKg: 60, reps: 8),
      const SetStat(exerciseId: bench, type: SetType.warmup, weightKg: 20, reps: 10),
      const SetStat(exerciseId: 'Pullups', type: SetType.normal, reps: 8),
      const SetStat(exerciseId: 'Pullups', type: SetType.normal, reps: 8, right: true),
      const SetStat(exerciseId: 'Hamstring_Stretch', type: SetType.normal, durationS: 30),
    ];
    final m = setsPerMuscle(sets, (id) => byId[id]);
    expect(m['chest'], 2);
    expect(m['triceps'], 1);
    expect(m['lats'], 1, reason: 'a left + right pair is one set');
    expect(m['biceps'], 0.5);
    expect(m.containsKey('hamstrings'), isFalse, reason: 'stretches are not training load');
    expect(muscleHeat({'chest': 5, 'lats': 20}, days: 7), {'chest': 0.5, 'lats': 1.0});
    expect(topExercises(sets, (id) => byId[id]).first, (bench, 2));
    await s.close();
  });

  test('weekly summaries: 12 weeks from Sunday, strength + runs', () async {
    final s = await testServices();
    final now = DateTime(2026, 11, 11, 9); // Wednesday
    await s.runs.logRun(startedAt: DateTime(2026, 11, 8, 7), durationS: 1800, distanceM: 5000); // this Sunday
    await s.runs.logRun(startedAt: DateTime(2026, 11, 7, 7), durationS: 1200, distanceM: 3000); // last Saturday
    final runs = await s.runs.watchFinished().first;
    final weeks = weeklySummaries(workouts: const [], runs: runs, now: now);
    expect(weeks.length, 12);
    expect(weeks.last.start, DateTime(2026, 11, 8));
    expect((weeks.last.runs, weeks.last.runMinutes, weeks.last.metres), (1, 30, 5000.0));
    expect(weeks[10].runs, 1);
    final t = periodTotals(workouts: const [], runs: runs, from: DateTime(2026, 11, 5));
    expect((t.workouts, t.minutes, t.metres), (2, 50, 8000.0));
    await s.close();
  });

  testWidgets('Stats opens from Home and shows totals, weeks and muscles', (tester) async {
    final s = (await tester.runAsync(() async {
      final s = await testServices();
      await s.session.startEmpty();
      await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
      final e = s.session.active!.exercises.single;
      final set = e.sets.first;
      s.session.setWeight(set, 60);
      s.session.setReps(set, 8);
      s.session.toggleDone(e, set);
      s.session.stopTimer();
      await s.session.finish();
      await s.runs.logRun(
        startedAt: DateTime.now().subtract(const Duration(hours: 3)),
        durationS: 1500,
        distanceM: 4000,
      );
      return s;
    }))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('openStats')),
      100,
      scrollable: find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.ensureVisible(find.byKey(const Key('openStats')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('openStats')));
    await settle(tester);
    expect(find.byType(StatsScreen), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('totalWorkouts')), matching: find.text('2')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('totalKm')), matching: find.text('4.00')), findsOneWidget);
    expect(find.byKey(const Key('statsWeeks')), findsOneWidget);
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('muscleHeat')),
      200,
      scrollable: find.descendant(of: find.byKey(const Key('statsList')), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('Chest'), findsWidgets);
    await tester.dragUntilVisible(find.text('90 days'), find.byKey(const Key('statsList')), const Offset(0, 300));
    await tester.tap(find.text('90 days'));
    await settle(tester);
    await tearDownApp(tester, s);
  });
}
