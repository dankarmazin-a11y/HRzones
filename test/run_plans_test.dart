import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/run_repository.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/run/geo.dart';
import 'package:hrzones/run/run_plan.dart';
import 'package:hrzones/run/run_session.dart';
import 'package:hrzones/run/run_voice.dart';
import 'package:hrzones/ui/run/run_plans.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'run_test.dart' show FakeLocation, countdown, lat0, lon0, north, t0;
import 'test_helpers.dart';

const intervals = PlanSpec(
  warmup: PlanStep(StepKind.warmup, byDistance: false, value: 60),
  repeats: 2,
  work: PlanStep(StepKind.work, byDistance: true, value: 400),
  recover: PlanStep(StepKind.recover, byDistance: true, value: 200),
  cooldown: PlanStep(StepKind.cooldown, byDistance: false, value: 60),
);

void main() {
  test('steps in order; description; JSON round trip', () {
    expect(intervals.steps.map((s) => s.kind), [
      StepKind.warmup,
      StepKind.work,
      StepKind.recover,
      StepKind.work,
      StepKind.cooldown,
    ]);
    expect(intervals.description, 'Warm-up 1 min · 2 × 400 m / 200 m easy · Cool-down 1 min');
    final back = PlanSpec.fromJson(intervals.toJson());
    expect(back.steps.length, 5);
    expect(back.work!.value, 400);
    expect(defaultPlans.map((p) => p.$1), contains('6 × 400 m'));
  });

  test('the runner moves through the steps by distance and time and records laps', () {
    final r = PlanRunner(intervals);
    expect(r.update(100, 59), isNull);
    expect(r.update(180, 60), PlanEvent.nextStep); // warm-up done (60 s)
    expect(r.current!.kind, StepKind.work);
    expect(r.repeat, 1);
    expect(r.left(380, 130), closeTo(200, 0.1));
    expect(r.update(580, 140), PlanEvent.nextStep); // 400 m fast
    expect(r.current!.kind, StepKind.recover);
    expect(r.update(780, 220), PlanEvent.nextStep);
    expect(r.repeat, 2);
    expect(r.update(1180, 300), PlanEvent.nextStep);
    expect(r.current!.kind, StepKind.cooldown);
    expect(r.update(1300, 360), PlanEvent.done);
    expect(r.laps.map((l) => l.distanceM.round()), [180, 400, 200, 400, 120]);
    expect(r.laps[1].seconds, 80);
    final back = decodeLaps(encodeLaps(r.laps));
    expect(back.length, 5);
    expect(back[1].step.kind, StepKind.work);
  });

  test('a distance goal says "Halfway" and when it is reached', () {
    final r = PlanRunner(const PlanSpec(goal: PlanStep(StepKind.goal, byDistance: true, value: 5000)));
    expect(r.update(2400, 700), isNull);
    expect(r.update(2510, 730), PlanEvent.halfway);
    expect(r.update(2600, 750), isNull, reason: 'only once');
    expect(r.update(5001, 1500), PlanEvent.done);
  });

  test('during a run: beeps, vibration and voice for every step; laps saved', () async {
    final beeper = SilentBeeper();
    var clock = t0;
    final gps = FakeLocation();
    final repo = RunRepository(memoryDb());
    final run = RunSession(
      runs: repo,
      hr: HrMonitor(beeper: beeper),
      location: gps,
      clock: () => clock,
    )..voice = RunVoice(beeper.speak);
    final plan = RunPlan(id: 'p1', name: 'Test', specJson: intervals.toJson(), position: 0, updatedAt: t0);
    await run.start(plan: plan);
    expect(beeper.spoken.last, 'Warm-up 1 minute.');
    gps.emit(GeoFix(time: t0, lat: lat0, lon: lon0, accuracy: 5));
    var pos = 0.0;
    for (var i = 1; i <= 400; i++) {
      clock = t0.add(Duration(seconds: i));
      pos += 4;
      gps.emit(GeoFix(time: clock, lat: lat0 + pos / 111195, lon: lon0, accuracy: 5));
      await Future<void>.delayed(Duration.zero);
    }
    expect(beeper.spoken, contains('Run 400 metres. Repeat 1 of 2.'));
    expect(beeper.spoken, contains('Recover 200 metres.'));
    expect(beeper.spoken, contains('Run 400 metres. Repeat 2 of 2.'));
    expect(beeper.spoken.last, startsWith('Workout complete'));
    expect(beeper.calls, contains('beep 1100x2'), reason: 'work starts: 2 high beeps');
    expect(beeper.calls, contains('beep 550x1'), reason: 'recovery: 1 low beep');
    final id = await run.finish();
    final r = (await repo.byId(id!))!;
    expect(r.planId, 'p1');
    final laps = decodeLaps(r.lapsJson);
    expect(laps.length, 5);
    expect(laps[1].distanceM, closeTo(400, 8));
  });

  testWidgets('make an interval plan, start it, the banner shows the step', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    final gps = FakeLocation();
    s.run.location = gps;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.text('Run').last);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);
    expect(find.text('Easy 5 km'), findsOneWidget, reason: 'built-in examples');
    await tester.tap(find.byKey(const Key('newPlan')));
    await settle(tester);
    await tester.tap(find.text('Intervals'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('planName')), 'Hills');
    await tester.tap(find.byKey(const Key('savePlan')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);
    final plans = (await tester.runAsync(() => s.runPlans.watchAll().first))!;
    final hills = plans.firstWhere((p) => p.name == 'Hills');
    expect(PlanSpec.fromJson(hills.specJson).isIntervals, isTrue);

    await tester.ensureVisible(find.byKey(Key('startPlan_${hills.id}')));
    await settle(tester);
    await tester.tap(find.byKey(Key('startPlan_${hills.id}')));
    await settle(tester);
    expect(find.byKey(const Key('planInfo')), findsOneWidget);
    await tester.tap(find.byKey(const Key('goRun')));
    await countdown(tester);
    expect(find.byKey(const Key('planBanner')), findsOneWidget);
    expect(find.textContaining('Warm-up'), findsWidgets);
    gps.emit(north(0, 0));
    expect(s.run.planId, hills.id);
    expect(find.byType(PlanBanner), findsOneWidget);
    await tester.runAsync(s.run.discard);
    await tearDownApp(tester, s);
  });
}
