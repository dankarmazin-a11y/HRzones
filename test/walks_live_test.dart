import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/data/run_repository.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/hr/zones.dart';
import 'package:hrzones/run/gait.dart';
import 'package:hrzones/run/geo.dart';
import 'package:hrzones/run/run_session.dart';
import 'package:hrzones/run/run_voice.dart';
import 'package:hrzones/ui/run/run_start.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'run_test.dart' show FakeLocation, lat0, lon0, t0;
import 'test_helpers.dart';

void main() {
  late SilentBeeper beeper;
  late FakeLocation gps;
  late RunSession run;
  late RunRepository repo;
  late DateTime clock;
  var pos = 0.0;
  var sec = 0;

  setUp(() {
    beeper = SilentBeeper();
    gps = FakeLocation();
    clock = t0;
    pos = 0;
    sec = 0;
    repo = RunRepository(memoryDb());
    run = RunSession(
      runs: repo,
      hr: HrMonitor(beeper: beeper),
      location: gps,
      clock: () => clock,
    )..voice = RunVoice(beeper.speak);
  });

  /// [seconds] at [mps] metres per second (no step counter: pace decides).
  Future<void> go(double mps, int seconds) async {
    for (var i = 0; i < seconds; i++) {
      sec++;
      clock = t0.add(Duration(seconds: sec));
      pos += mps;
      gps.emit(GeoFix(time: clock, lat: lat0 + pos / 111195, lon: lon0, accuracy: 5));
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('during a run the app notices a walk break: label, no "speed up", walk pace beep', () async {
    run.paceAlert = const HrRange(min: 300, max: 360); // 5:00–6:00
    await run.start();
    gps.emit(GeoFix(time: t0, lat: lat0, lon: lon0, accuracy: 5));
    await go(3.1, 60); // 5:23 /km
    expect(run.liveGait, Gait.run);
    await go(1.5, 60); // 11:07 /km – walking
    expect(run.liveGait, Gait.walk);
    expect(beeper.spoken.where((t) => t.endsWith('Speed up.')), isEmpty, reason: 'a walk break never says speed up');
    // with a walk pace limit of 10:00 /km, walking at 11:07 beeps "too slow"
    run.walkPaceAlert = 600;
    await go(1.5, 40);
    expect(beeper.calls, contains('beep 400x1'));
    // running again
    await go(3.1, 40);
    expect(run.liveGait, Gait.run);
    await run.discard();
  });

  test('"Walking" / "Running again" is said only when switched on', () async {
    await run.start();
    gps.emit(GeoFix(time: t0, lat: lat0, lon: lon0, accuracy: 5));
    await go(3.1, 40);
    await go(1.5, 60);
    expect(beeper.spoken, isNot(contains('Walking.')));
    run.voice!.gaitChanges = true;
    await go(3.1, 60);
    expect(beeper.spoken, contains('Running again.'));
    await run.discard();
  });

  test('picked Walk: voice says "Walk"; mostly running → saved as a run, and the owner is told', () async {
    await run.start(activity: RunActivity.walk);
    expect(beeper.spoken.first, 'Walk started.');
    expect(run.liveGait, Gait.walk);
    gps.emit(GeoFix(time: t0, lat: lat0, lon: lon0, accuracy: 5));
    await go(3.2, 300);
    final id = await run.finish();
    expect((await repo.byId(id!))!.activity, RunActivity.run);
    expect(run.takeLabelNote(), contains('saved as a run'));
    expect(run.takeLabelNote(), isNull, reason: 'read once');
  });

  test('a hike stays a hike; detection off keeps the pick', () async {
    await run.start(activity: RunActivity.hike);
    gps.emit(GeoFix(time: t0, lat: lat0, lon: lon0, accuracy: 5));
    await go(3.2, 120);
    expect((await repo.byId((await run.finish())!))!.activity, RunActivity.hike);

    run.autoDetect = false;
    await run.start(activity: RunActivity.walk);
    gps.emit(GeoFix(time: clock, lat: lat0 + pos / 111195, lon: lon0, accuracy: 5));
    await go(3.2, 120);
    expect((await repo.byId((await run.finish())!))!.activity, RunActivity.walk);
  });

  testWidgets('Ready sheet: Run · Walk · Hike; Walk starts a walk', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    runCountdownSeconds = 0;
    addTearDown(() => runCountdownSeconds = 3);
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    startRun(tester.element(find.byType(NavigationBar)));
    await settle(tester);
    expect(find.byKey(const Key('activity_run')), findsOneWidget);
    expect(find.byKey(const Key('activity_hike')), findsOneWidget);
    await tester.tap(find.byKey(const Key('activity_walk')));
    await settle(tester);
    expect(find.text('Ready to walk'), findsOneWidget);
    expect(find.byKey(const Key('autoDetectWalk')), findsNothing, reason: 'folded');
    await tester.tap(find.byKey(const Key('walkingOptions')));
    await settle(tester);
    expect(find.byKey(const Key('autoDetectWalk')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('goRun')));
    await tester.tap(find.byKey(const Key('goRun')));
    await settle(tester);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);
    expect(s.run.active, isTrue);
    expect(s.run.chosen, RunActivity.walk);
    expect(find.text('Walk'), findsWidgets, reason: 'live screen title');
    expect(await tester.runAsync(() => s.db.getSetting('runActivity')), 'walk', reason: 'remembered');
    await tester.runAsync(s.run.discard);
    await tearDownApp(tester, s);
  });
}
