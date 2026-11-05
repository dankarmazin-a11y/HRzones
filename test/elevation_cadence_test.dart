import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/ui/run/run_summary_screen.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/run_repository.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/run/elevation.dart';
import 'package:hrzones/run/geo.dart';
import 'package:hrzones/run/motion_source.dart';
import 'package:hrzones/run/run_session.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'run_test.dart' show FakeLocation, lat0, lon0, summaryList, t0;
import 'test_helpers.dart';

/// Steps pushed by the test.
class FakeMotion extends MotionSource {
  int steps = 0;
  double? cadence;
  int starts = 0;
  bool available = true;

  @override
  Future<bool> start() async {
    starts++;
    steps = 0;
    return available;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<MotionReading?> read() async => available ? (steps: steps, cadence: cadence) : null;
}

void main() {
  test('climb and descent ignore GPS altitude noise', () {
    final rnd = math.Random(1);
    // Flat with ±2 m noise: nothing climbed.
    final flat = [for (var i = 0; i < 300; i++) 50 + (rnd.nextDouble() * 4 - 2)];
    final f = elevationGainLoss(flat);
    expect(f.climb, lessThan(3));
    // Up 40 m and down 25 m.
    final hill = [for (var i = 0; i <= 100; i++) 50 + i * 0.4, for (var i = 1; i <= 100; i++) 90 - i * 0.25];
    final h = elevationGainLoss(hill);
    // Smoothing rounds the hilltop off a little (a few metres).
    expect(h.climb, closeTo(40, 5));
    expect(h.descent, closeTo(25, 5));
  });

  test('steps, cadence and average cadence; a pause doesn\'t lose steps', () async {
    var clock = t0;
    final motion = FakeMotion();
    final gps = FakeLocation();
    final repo = RunRepository(memoryDb());
    final run = RunSession(
      runs: repo,
      hr: HrMonitor(beeper: SilentBeeper()),
      location: gps,
      motion: motion,
      clock: () => clock,
    );
    await run.start();
    expect(motion.starts, 1);
    // 5 minutes at 170 spm (read every 5 ticks – done by hand here).
    clock = t0.add(const Duration(minutes: 5));
    motion
      ..steps = 850
      ..cadence = 170;
    await run.flush();
    await run.pause();
    expect(run.steps, 850);
    expect(run.cadence, isNull, reason: 'paused');
    clock = t0.add(const Duration(minutes: 8));
    await run.resume();
    expect(motion.starts, 2, reason: 'counting starts again after the pause');
    clock = t0.add(const Duration(minutes: 13));
    motion.steps = 900; // since the resume
    gps.emit(GeoFix(time: clock, lat: lat0, lon: lon0, accuracy: 5));
    final id = await run.finish();
    final r = (await repo.byId(id!))!;
    expect(r.steps, 1750);
    expect(r.avgCadence, 175, reason: '1750 steps in 10 moving minutes');
  });

  test('no step counter: no steps or cadence saved', () async {
    final motion = FakeMotion()..available = false;
    final repo = RunRepository(memoryDb());
    final run = RunSession(
      runs: repo,
      hr: HrMonitor(beeper: SilentBeeper()),
      location: FakeLocation(),
      motion: motion,
    );
    await run.start();
    final id = await run.finish();
    final r = (await repo.byId(id!))!;
    expect(r.steps, isNull);
    expect(r.avgCadence, isNull);
  });

  testWidgets('the summary shows climb, descent, cadence and the height profile', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    final id = (await tester.runAsync(() async {
      var clock = t0;
      final gps = FakeLocation();
      final motion = FakeMotion();
      final run = RunSession(runs: s.runs, hr: s.hr, location: gps, motion: motion, clock: () => clock);
      await run.start();
      for (var i = 0; i <= 300; i++) {
        clock = t0.add(Duration(seconds: i));
        // 3 m/s, up 30 m over the first half, down 30 m over the second.
        final alt = 20 + (i <= 150 ? i * 0.2 : (300 - i) * 0.2);
        gps.emit(GeoFix(time: clock, lat: lat0 + i * 3 / 111195, lon: lon0, accuracy: 5, altitude: alt));
        await Future<void>.delayed(Duration.zero);
      }
      motion.steps = 850;
      final id = await run.finish();
      run.dispose();
      return id;
    }))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    Navigator.of(tester.element(find.byType(NavigationBar)))
        .push(MaterialPageRoute(builder: (_) => RunSummaryScreen(runId: id)));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('elevationChart')), 200, scrollable: summaryList());
    expect(find.textContaining('↑ '), findsOneWidget);
    expect(find.text('170'), findsOneWidget, reason: '850 steps in 5 minutes');
    expect(find.byKey(const Key('elevationChart')), findsOneWidget);
    await tearDownApp(tester, s);
  });
}
