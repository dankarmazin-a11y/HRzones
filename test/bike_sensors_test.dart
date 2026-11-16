import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/bike/bike_sensors.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/data/run_repository.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/run/run_session.dart';
import 'package:hrzones/ui/run/run_start.dart';
import 'package:hrzones/ui/run/run_summary_screen.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'run_test.dart' show FakeLocation, t0;
import 'test_helpers.dart';

/// A CSC notification with wheel and crank data.
List<int> csc({required int wheelRevs, required int wheelTime, required int crankRevs, required int crankTime}) => [
  0x03,
  wheelRevs & 0xFF,
  (wheelRevs >> 8) & 0xFF,
  (wheelRevs >> 16) & 0xFF,
  (wheelRevs >> 24) & 0xFF,
  wheelTime & 0xFF,
  (wheelTime >> 8) & 0xFF,
  crankRevs & 0xFF,
  (crankRevs >> 8) & 0xFF,
  crankTime & 0xFF,
  (crankTime >> 8) & 0xFF,
];

/// A power notification: watts + crank data (flags bit 5).
List<int> power(int watts, {required int crankRevs, required int crankTime}) => [
  0x20,
  0x00,
  watts & 0xFF,
  (watts >> 8) & 0xFF,
  crankRevs & 0xFF,
  (crankRevs >> 8) & 0xFF,
  crankTime & 0xFF,
  (crankTime >> 8) & 0xFF,
];

void main() {
  test('decodes speed/cadence and power notifications', () {
    final r = parseCsc(csc(wheelRevs: 70000, wheelTime: 1024, crankRevs: 300, crankTime: 2048))!;
    expect(r.wheel, (revs: 70000, time: 1024));
    expect(r.crank, (revs: 300, time: 2048));
    expect(parseCsc([0x01, 1, 2]), isNull, reason: 'too short');
    final p = parsePower(power(250, crankRevs: 10, crankTime: 512))!;
    expect(p.power, 250);
    expect(p.crank, (revs: 10, time: 512));
    // pedal balance + torque fields are skipped before the crank data
    expect(parsePower([0x25, 0x00, 100, 0, 50, 0, 0, 7, 0, 0, 4])!.crank, (revs: 7, time: 1024));
    expect(parsePower([0x00, 0x00, 0xFF, 0xFF])!.power, 0, reason: 'negative watts read as 0');
  });

  test('speed and cadence from the counters; counters roll over; zero when nothing turns', () {
    var clock = t0;
    final hub = BikeSensorHub(clock: () => clock)..wheelMm = 2000;
    // 4 wheel turns and 1.5 pedal turns per second
    for (var s = 0; s <= 10; s++) {
      clock = t0.add(Duration(seconds: s));
      final time = (65000 + s * 1024) & 0xFFFF; // the 1/1024 s clock rolls over
      hub.onCsc(
        csc(wheelRevs: 100 + s * 4, wheelTime: time, crankRevs: (65530 + s * 3 ~/ 2) & 0xFFFF, crankTime: time),
      );
    }
    expect(hub.speedMs, closeTo(8.0, 0.01));
    expect(hub.cadence, closeTo(90, 31), reason: 'about 90 rpm (whole turns per update)');
    expect(hub.wheelDistanceM, closeTo(80, 0.1));
    clock = clock.add(const Duration(seconds: 5));
    expect(hub.speedMs, 0, reason: 'stopped');
    expect(hub.cadence, 0);
    expect(hub.power, isNull, reason: 'no power meter');
  });

  test('indoor ride with sensors: distance from the wheel, watts, rpm, W/kg – saved', () async {
    var clock = t0;
    final hub = BikeSensorHub(clock: () => clock);
    final repo = RunRepository(memoryDb());
    final ride =
        RunSession(
            runs: repo,
            hr: HrMonitor(beeper: SilentBeeper()),
            location: FakeLocation(),
            clock: () => clock,
          )
          ..bike = hub
          ..riderWeight = (() async => 80);
    await ride.start(activity: RunActivity.ride, treadmill: true);
    for (var s = 0; s <= 600; s++) {
      clock = t0.add(Duration(seconds: s));
      final time = (s * 1024) & 0xFFFF;
      hub.onCsc(csc(wheelRevs: s * 4, wheelTime: time, crankRevs: (s * 3) ~/ 2, crankTime: time)); // 8.4 m/s
      hub.onPower(power(s < 300 ? 200 : 240, crankRevs: (s * 3) ~/ 2, crankTime: time));
      ride.sampleBikeForTest();
    }
    expect(ride.speedMs, closeTo(8.42, 0.05));
    expect(ride.distanceM, closeTo(600 * 8.42, 30));
    expect(ride.powerW, 240);
    expect(ride.wattsPerKg, closeTo(3.0, 0.01));
    final id = (await ride.finish())!;
    final r = (await repo.byId(id))!;
    expect(r.activity, RunActivity.ride);
    expect(r.avgPowerW, closeTo(220, 1));
    expect(r.maxPowerW, 240);
    expect(r.avgCadence, closeTo(90, 5));
    expect(r.distanceM, closeTo(5050, 40));
    expect(powerCalories(avgW: 220, durationS: 3600), 792);
  });

  testWidgets('Ready sheet › Bike sensors: wheel size is saved', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    startRun(tester.element(find.byType(NavigationBar)));
    await settle(tester);
    await tester.tap(find.byKey(const Key('activity_ride')));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('bikeSensorsRow')));
    await tester.tap(find.byKey(const Key('bikeSensorsRow')));
    await settle(tester);
    expect(find.text('Bike sensors'), findsWidgets);
    await tester.tap(find.byKey(const Key('wheelSize')));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, '2136');
    await tester.tap(find.text('OK').last);
    await settle(tester);
    expect(s.bike.wheelMm, 2136);
    expect(await tester.runAsync(() => s.db.getSetting('wheelMm')), '2136');
    await tearDownApp(tester, s);
  });
}
