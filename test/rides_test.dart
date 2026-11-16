import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/data/run_repository.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/run/geo.dart';
import 'package:hrzones/run/run_session.dart';
import 'package:hrzones/run/run_voice.dart';
import 'package:hrzones/ui/run/run_start.dart';
import 'package:hrzones/ui/run/run_summary_screen.dart';
import 'package:hrzones/ui/run/running_run_bar.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'run_test.dart' show FakeLocation, lat0, lon0, t0;
import 'test_helpers.dart';

void main() {
  test('speed: km/h from a pace; ride calories by speed', () {
    expect(formatSpeed(120), '30.0 km/h'); // 2:00 /km
    expect(formatSpeed(null), '– km/h');
    expect(formatSpeed(133.33, unit: false), '27.0');
    // 1 h at 27 km/h, 70 kg: MET 12
    expect(rideCalories(durationS: 3600, distanceM: 27000, weightKg: 70), closeTo(840, 1));
    expect(rideCalories(durationS: 3600, distanceM: 27000), isNull);
  });

  test('a ride: stays a ride, top speed, 20 km best effort, voice in km/h, own records', () async {
    var clock = t0;
    final gps = FakeLocation();
    final beeper = SilentBeeper();
    final repo = RunRepository(memoryDb());
    final ride = RunSession(
      runs: repo,
      hr: HrMonitor(beeper: beeper),
      location: gps,
      clock: () => clock,
    )..voice = RunVoice(beeper.speak);
    // an earlier long run: rides must not take running records
    final runId = await repo.logRun(startedAt: t0.subtract(const Duration(days: 1)), distanceM: 15000, durationS: 4500);
    await ride.start(activity: RunActivity.ride);
    expect(beeper.spoken.first, 'Ride started.');
    expect(ride.riding, isTrue);
    var m = 0.0;
    for (var s = 0; s <= 2700; s++) {
      clock = t0.add(Duration(seconds: s));
      gps.emit(GeoFix(time: clock, lat: lat0 + m / 111195, lon: lon0, accuracy: 5));
      m += s > 600 && s < 660 ? 11 : 8; // a fast minute: 39.6 km/h
      await Future<void>.delayed(Duration.zero);
    }
    expect(beeper.spoken.any((t) => t.startsWith('5 kilometres.') && t.contains('kilometres per hour')), isTrue);
    expect(beeper.spoken.any((t) => t.startsWith('1 kilometre.')), isFalse, reason: 'rides: every 5 km');
    final id = await ride.finish();
    final r = (await repo.byId(id!))!;
    expect(r.activity, RunActivity.ride);
    expect(r.maxSpeedMs, closeTo(11, 0.6));
    final bests = await repo.bestsFor(r);
    expect(bests.keys, contains(20000));
    expect(bests.keys, isNot(contains(1000)), reason: 'rides use 20 / 40 km');
    expect((await repo.records()).longest!.run.id, runId);
    final rideRecords = await repo.records(activity: RunActivity.ride);
    expect(rideRecords.longest!.run.id, id);
    expect(rideRecords.topSpeed!.value, closeTo(11, 0.6));
  });

  test('auto-pause: a ride stops by itself at a red light and goes on when you ride', () async {
    var clock = t0;
    final gps = FakeLocation();
    final beeper = SilentBeeper();
    final repo = RunRepository(memoryDb());
    final ride = RunSession(
      runs: repo,
      hr: HrMonitor(beeper: beeper),
      location: gps,
      clock: () => clock,
    )..voice = RunVoice(beeper.speak);
    await ride.start(activity: RunActivity.ride);
    var m = 0.0;
    Future<void> second(int s, double speed) async {
      clock = t0.add(Duration(seconds: s));
      m += speed;
      gps.emit(GeoFix(time: clock, lat: lat0 + m / 111195, lon: lon0, accuracy: 5));
      await Future<void>.delayed(Duration.zero);
      ride.checkAutoPauseForTest();
    }

    for (var s = 1; s <= 60; s++) {
      await second(s, 8); // 28.8 km/h
    }
    expect(ride.autoPaused, isFalse);
    for (var s = 61; s <= 90; s++) {
      await second(s, 0); // waiting at the lights
    }
    expect(ride.autoPaused, isTrue);
    expect(ride.paused, isTrue);
    expect(beeper.spoken, contains('Auto-paused.'));
    final movingAtStop = ride.moving;
    expect(movingAtStop.inSeconds, inInclusiveRange(59, 62), reason: 'the stop does not count');
    final km = ride.distanceM;
    for (var s = 91; s <= 120; s++) {
      await second(s, 6);
    }
    expect(ride.autoPaused, isFalse);
    expect(ride.paused, isFalse);
    expect(beeper.spoken, contains('Ride resumed.'));
    expect(ride.distanceM, greaterThan(km + 150), reason: 'riding off counts');
    expect(ride.moving.inSeconds, lessThan(95));

    // off: no auto-pause
    ride.autoPauseRide = false;
    for (var s = 121; s <= 150; s++) {
      await second(s, 0);
    }
    expect(ride.paused, isFalse);
    await ride.discard();
  });

  testWidgets('live screen: tap a small number to make it the big one (remembered per activity)', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.runAsync(() => s.run.start(activity: RunActivity.ride));
    await settle(tester);
    await tester.tap(find.byType(RunningRunBar));
    await settle(tester);
    expect(find.byKey(const Key('rideSpeed')), findsOneWidget);
    await tester.tap(find.byKey(const Key('stat_distance')));
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
    expect(s.bigStats.value['ride'], 'distance');
    expect(find.byKey(const Key('stat_speed')), findsOneWidget, reason: 'speed moved to the small row');
    expect(await tester.runAsync(() => s.db.getSetting('bigStats')), contains('"ride":"distance"'));
    await tester.runAsync(s.run.discard);
    await tearDownApp(tester, s);
  });

  testWidgets('Ready sheet: Ride tile, Indoor instead of Treadmill, no walking options', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    startRun(tester.element(find.byType(NavigationBar)));
    await settle(tester);
    await tester.tap(find.byKey(const Key('activity_ride')));
    await settle(tester);
    expect(find.text('Ready to ride'), findsOneWidget);
    expect(find.text('Indoor'), findsOneWidget);
    expect(find.byKey(const Key('walkingOptions')), findsNothing);
    expect(find.byKey(const Key('paceAlertRow')), findsNothing);
    expect(find.byKey(const Key('autoPauseRide')), findsOneWidget);
    expect(find.byKey(const Key('rideScreenOn')), findsOneWidget);
    await tearDownApp(tester, s);
  });
}
