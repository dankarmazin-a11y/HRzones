import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/run_repository.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/run/gait.dart';
import 'package:hrzones/run/geo.dart';
import 'package:hrzones/run/run_session.dart';
import 'package:hrzones/ui/history/history_screen.dart';
import 'package:hrzones/ui/run/run_summary_screen.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'elevation_cadence_test.dart' show FakeMotion;
import 'run_test.dart' show FakeLocation, lat0, lon0, t0;
import 'test_helpers.dart';

/// Points going north: [parts] = (seconds, seconds per km, steps per minute).
List<GaitPoint> outing(List<(int, double, int?)> parts) {
  final out = <GaitPoint>[];
  var s = 0, m = 0.0;
  for (final (secs, pace, cad) in parts) {
    for (var i = 0; i < secs; i++) {
      out.add((
        time: t0.add(Duration(seconds: s)),
        lat: lat0 + m / 111195,
        lon: lon0,
        accuracy: 5,
        segment: 0,
        cadence: cad,
      ));
      s++;
      m += 1000 / pace;
    }
  }
  return out;
}

void main() {
  test('walking or running: pace and steps per minute (owner\'s limits)', () {
    expect(classifyGait(paceS: 330, cadence: 165), Gait.run);
    expect(classifyGait(paceS: 630, cadence: 112), Gait.walk);
    // a slow jog: slow pace but running steps
    expect(classifyGait(paceS: 560, cadence: 150), Gait.run);
    // a fast walk: under 9:00 /km but walking steps → the grey zone, steps decide
    expect(classifyGait(paceS: 500, cadence: 120), Gait.walk);
    expect(classifyGait(paceS: 470, cadence: 120), Gait.run, reason: 'faster than 8:00 is running');
    // no step counter: pace 8:30 is the line
    expect(classifyGait(paceS: 520), Gait.walk);
    expect(classifyGait(paceS: 500), Gait.run);
    // standing at a traffic light
    expect(classifyGait(paceS: null, cadence: 0), Gait.still);
  });

  test('a run with a walk break: ran / walked split, short slow bits ignored', () {
    final g = analyzeGait(
      outing([
        (180, 330, 165), // 3 min running
        (90, 630, 112), // 1.5 min walking
        (120, 330, 165),
        (8, 630, 112), // 8 s of walking around a corner – not a break
        (120, 330, 165),
      ]),
    );
    expect(g.walkBreaks, 1);
    expect(g.walkedM, closeTo(90 * 1000 / 630, 40));
    expect(g.ranM, greaterThan(1200));
    expect(g.isWalk, isFalse);
    expect(g.walkPaceS, closeTo(630, 80));
    final split = g.walkedPerSplit(1000);
    expect(split.first, greaterThan(0), reason: 'the walk break was in the first km');
  });

  test('mostly walking is a walk', () {
    final g = analyzeGait(outing([(600, 660, 110), (40, 330, 165), (300, 660, 110)]));
    expect(g.isWalk, isTrue);
    expect(isWalkByAverages(distanceM: 5000, durationS: 3300, avgCadence: 112), isTrue);
    expect(isWalkByAverages(distanceM: 5000, durationS: 1650, avgCadence: 168), isFalse);
  });

  test('a recorded walk is saved as a walk and keeps its own records', () async {
    var clock = t0;
    final motion = FakeMotion();
    final gps = FakeLocation();
    final repo = RunRepository(memoryDb());
    final session = RunSession(
      runs: repo,
      hr: HrMonitor(beeper: SilentBeeper()),
      location: gps,
      motion: motion,
      clock: () => clock,
    );
    // An earlier fast run: a walk must not count against running records.
    final runId = await repo.logRun(startedAt: t0.subtract(const Duration(days: 2)), distanceM: 5000, durationS: 1500);
    await session.start();
    motion.cadence = 112;
    var m = 0.0;
    for (var s = 0; s <= 900; s++) {
      clock = t0.add(Duration(seconds: s));
      if (s % 5 == 0) {
        motion.steps = (s * 112 / 60).round();
        await session.readMotion();
      }
      gps.emit(GeoFix(time: clock, lat: lat0 + m / 111195, lon: lon0, accuracy: 5));
      m += 1000 / 650; // 10:50 /km
      await Future<void>.delayed(Duration.zero);
    }
    final id = await session.finish();
    final walk = (await repo.byId(id!))!;
    expect(walk.activity, RunActivity.walk);
    expect(walk.walkedM, greaterThan(1200));
    final pts = await repo.points(id);
    expect(pts.where((p) => p.cadence == 112), isNotEmpty, reason: 'steps per minute saved at each point');
    // records: walks have their own; running records only see runs
    expect((await repo.records()).longest!.run.id, runId);
    expect((await repo.records(activity: RunActivity.walk)).longest!.run.id, id);
    // the owner can change it
    await repo.setActivity(id, RunActivity.run);
    expect((await repo.byId(id))!.activity, RunActivity.run);
  });

  testWidgets('summary says "Saved as a walk"; Change to run; History has a Walk filter', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    final walkId = (await tester.runAsync(() async {
      final id = await s.runs.logRun(startedAt: t0, distanceM: 4000, durationS: 2700);
      await s.runs.setActivity(id, RunActivity.walk);
      await s.runs.logRun(startedAt: t0.add(const Duration(days: 1)), distanceM: 6000, durationS: 1900);
      return id;
    }))!;
    Future<void> wait() async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await settle(tester);
    }

    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    final nav = Navigator.of(tester.element(find.byType(NavigationBar)));
    nav.push(MaterialPageRoute(builder: (_) => RunSummaryScreen(runId: walkId)));
    await wait();
    expect(find.textContaining('walk'), findsWidgets);
    expect(find.byKey(const Key('savedAsWalk')), findsOneWidget);
    await tester.tap(find.byKey(const Key('changeActivity')));
    await wait();
    expect((await tester.runAsync(() => s.runs.byId(walkId)))!.activity, RunActivity.run);
    await tester.runAsync(() => s.runs.setActivity(walkId, RunActivity.walk));
    await tester.pageBack();
    await settle(tester);

    nav.push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
    await wait();
    await tester.tap(find.byKey(const Key('historyWalk')));
    await wait();
    expect(find.textContaining('4.00'), findsOneWidget);
    expect(find.textContaining('6.00'), findsNothing);
    await tearDownApp(tester, s);
  });
}
