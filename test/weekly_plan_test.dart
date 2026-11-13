import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/run/training_plan.dart';
import 'package:hrzones/ui/run/weekly_plan.dart';
import 'package:hrzones/ui/screens/run_screen.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  test('plan days: dates, today, done / missed, next', () {
    final start = DateTime(2026, 11, 1); // a Sunday: weeks start on Sunday
    const easy = PlanDay(week: 0, weekday: 1, kind: PlanDayKind.easy, distanceM: 5000);
    const long = PlanDay(week: 0, weekday: 6, kind: PlanDayKind.long, durationS: 3600);
    const tempo = PlanDay(week: 1, weekday: 3, kind: PlanDayKind.tempo, distanceM: 6500);
    final plan = WeeklyPlan(
      start: start,
      weeks: 2,
      days: decodePlanDays(encodePlanDays([easy, long, tempo])),
      runDates: [DateTime(2026, 11, 2, 18, 30)], // ran on Monday
    );
    final saturday = DateTime(2026, 11, 7, 9);
    expect(plan.dateOf(plan.days[1]), DateTime(2026, 11, 7));
    expect(plan.weekIndex(saturday), 0);
    expect(plan.weekIndex(DateTime(2026, 10, 31)), -1, reason: 'the day before the start');
    expect(plan.status(plan.days[0], saturday), DayStatus.done);
    expect(plan.status(plan.days[1], saturday), DayStatus.today);
    expect(plan.today(saturday)!.describe, 'Long run · 60 min');
    expect(plan.status(plan.days[1], DateTime(2026, 11, 8)), DayStatus.missed);
    expect(plan.next(DateTime(2026, 11, 8))!.describe, 'Tempo · 6.5 km');
    expect(plan.weekProgress(0, saturday), (1, 2));
    expect(plan.finishedBy(DateTime(2026, 11, 16)), isTrue);
    expect(goalSpecFor(plan.days[0])!.goal!.value, 5000);
  });

  test('saving a plan makes it the active one', () async {
    final s = await testServices();
    final first = await s.trainingPlans.save(name: 'A', start: DateTime(2026, 11, 4), weeks: 2, days: const []);
    expect((await s.trainingPlans.active())!.startDate, DateTime(2026, 11, 1), reason: 'starts on a Sunday');
    await s.trainingPlans.save(name: 'B', start: DateTime(2026, 11, 9), weeks: 3, days: const []);
    expect((await s.trainingPlans.active())!.name, 'B');
    await s.trainingPlans.delete((await s.trainingPlans.active())!.id);
    expect(await s.trainingPlans.active(), isNull, reason: 'A is not active any more');
    expect(first, isNotEmpty);
    await s.close();
  });

  testWidgets('make a plan on the Run tab; today\'s run shows with Start, then done after a run', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.text('Run').last);
    await settle(tester);
    final runList = find.descendant(of: find.byType(RunScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.byKey(const Key('weeklyPlanCard')), 100, scrollable: runList);
    await tester.tap(find.byKey(const Key('weeklyPlanCard')));
    await settle(tester);

    // Today: an easy 5 km.
    final wd = DateTime.now().weekday;
    await tester.ensureVisible(find.byKey(Key('planDay_$wd'), skipOffstage: false));
    await settle(tester);
    await tester.tap(find.byKey(Key('planDay_$wd')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('kind_easy')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('dayAmount')));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, '5');
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('saveDay')));
    await settle(tester);
    expect(find.text('Easy run · 5 km'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('copyWeek')),
      100,
      scrollable: find.descendant(of: find.byType(WeeklyPlanEditor), matching: find.byType(Scrollable)).first,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('copyWeek')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('savePlan')));
    await settle(tester);

    final plan = (await tester.runAsync(s.trainingPlans.active))!;
    expect(decodePlanDays(plan.daysJson), hasLength(4), reason: 'copied to all 4 weeks');
    await tester.scrollUntilVisible(find.byKey(const Key('todayRun')), 100, scrollable: runList);
    expect(find.text('Today: Easy run · 5 km'), findsOneWidget);
    expect(find.byKey(const Key('startPlanRun')), findsOneWidget);

    // A run today ticks the day off.
    await tester.runAsync(() => s.runs.logRun(startedAt: DateTime.now(), durationS: 1800, distanceM: 5000));
    await settle(tester);
    expect(find.textContaining('Today\'s run done'), findsOneWidget);
    await tearDownApp(tester, s);
  });
}
