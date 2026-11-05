import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/run_repository.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/run/geo.dart';
import 'package:hrzones/run/location_source.dart';
import 'package:hrzones/run/run_session.dart';
import 'package:hrzones/ui/run/run_map.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

/// GPS fixes are pushed by the test.
class FakeLocation extends LocationSource {
  FakeLocation({this.access = LocationAccess.granted});

  LocationAccess access;
  StreamController<GeoFix>? _out;
  int starts = 0;

  bool get listening => _out != null;

  @override
  Future<LocationAccess> ensureAccess() async => access;

  @override
  Stream<GeoFix> start() {
    starts++;
    _out = StreamController<GeoFix>();
    return _out!.stream;
  }

  @override
  Future<void> stop() async {
    await _out?.close();
    _out = null;
  }

  void emit(GeoFix f) => _out?.add(f);
}

final t0 = DateTime(2026, 11, 5, 7);

/// Lets the 3-2-1 countdown before a run run out.
Future<void> countdown(WidgetTester tester) async {
  await settle(tester);
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await settle(tester);
}

const lat0 = 32.1, lon0 = 34.8;

/// A fix [metres] north of the start, [s] seconds after t0.
GeoFix north(double metres, int s, {double accuracy = 5}) => GeoFix(
  time: t0.add(Duration(seconds: s)),
  lat: lat0 + metres / 111195,
  lon: lon0,
  accuracy: accuracy,
);

void main() {
  group('distance', () {
    test('adds up real movement', () {
      final d = DistanceTracker();
      for (var i = 0; i <= 100; i++) {
        d.add(north(i * 3.0, i)); // 3 m/s for 100 s
      }
      expect(d.distanceM, closeTo(300, 1));
    });

    test('ignores inaccurate fixes, standing-still jitter and jumps', () {
      final d = DistanceTracker()..add(north(0, 0));
      d.add(north(500, 1, accuracy: 80)); // inaccurate
      for (var i = 1; i < 30; i++) {
        d.add(north(i.isEven ? 1.5 : -1.5, i)); // jitter while standing
      }
      expect(d.distanceM, 0);
      d.add(north(400, 31)); // 400 m in 1 s: a jump
      expect(d.distanceM, 0);
      d.add(north(10, 33));
      expect(d.distanceM, closeTo(10, 0.5));
    });

    test('a lasting jump moves the start point without counting it', () {
      final d = DistanceTracker()
        ..add(north(0, 0))
        ..add(north(1000, 2)) // GPS corrects itself by 1 km…
        ..add(north(1003, 3)) // …and stays there
        ..add(north(1013, 6));
      expect(d.distanceM, closeTo(10, 0.5));
    });

    test('a new segment does not count the gap', () {
      final d = DistanceTracker()
        ..add(north(0, 0))
        ..add(north(10, 3))
        ..newSegment()
        ..add(north(200, 120))
        ..add(north(210, 123));
      expect(d.distanceM, closeTo(20, 0.5));
    });

    test('pace and km formatting', () {
      expect(formatPace(paceSecPerKm(1000, 330)), '5:30');
      expect(formatPace(null), '–:––');
      expect(formatKm(5240), '5.24');
      expect(geoDistanceM(0, 0, 0, 1), closeTo(111195, 10));
    });
  });

  group('recording', () {
    late DateTime clock;
    late FakeLocation gps;
    late RunSession run;
    late RunRepository repo;
    late HrMonitor hr;

    setUp(() async {
      clock = t0;
      gps = FakeLocation();
      final db = memoryDb();
      repo = RunRepository(db);
      hr = HrMonitor(beeper: SilentBeeper());
      run = RunSession(runs: repo, hr: hr, location: gps, clock: () => clock);
    });

    /// Runs for [seconds] at [mps] m/s, one fix per second.
    Future<void> runFor(int seconds, double mps, {required double from, required int at}) async {
      for (var i = 1; i <= seconds; i++) {
        clock = t0.add(Duration(seconds: at + i));
        gps.emit(north(from + i * mps, at + i));
      }
      await Future<void>.delayed(Duration.zero);
    }

    test('time, distance and pace; pause stops GPS and the clock', () async {
      expect(await run.start(), LocationAccess.granted);
      expect(gps.listening, isTrue);
      expect(run.gps, GpsStatus.searching);
      gps.emit(north(0, 0));
      await runFor(100, 3, from: 0, at: 0); // 300 m in 100 s
      expect(run.distanceM, closeTo(300, 1));
      expect(run.moving, const Duration(seconds: 100));
      expect(run.gps, GpsStatus.good);
      expect(formatPace(run.currentPace), '5:33'); // 3 m/s
      expect(formatPace(run.avgPace), '5:33');

      await run.pause();
      expect(gps.listening, isFalse, reason: 'GPS off while paused (battery)');
      clock = t0.add(const Duration(seconds: 400)); // 5 min standing
      expect(run.moving, const Duration(seconds: 100));
      expect(run.currentPace, isNull);

      await run.resume();
      expect(gps.listening, isTrue);
      // Resumed 200 m further on: the gap is not counted.
      gps.emit(north(500, 400));
      await runFor(50, 4, from: 500, at: 400);
      expect(run.distanceM, closeTo(500, 1));
      expect(run.moving, const Duration(seconds: 150));

      final id = await run.finish();
      expect(run.active, isFalse);
      expect(gps.listening, isFalse);
      final saved = (await repo.byId(id!))!;
      expect(saved.endedAt, isNotNull);
      expect(saved.distanceM, closeTo(500, 1));
      expect(saved.durationS, 150);
      final points = await repo.points(id);
      expect(points.length, 152);
      expect(points.map((p) => p.segment).toSet(), {0, 1});
      expect(await repo.watchFinished().first, hasLength(1));
    });

    test('without a zone preset the HR monitor is not started; discard deletes the run', () async {
      final db = memoryDb();
      final s = RunSession(runs: RunRepository(db), hr: hr, location: gps, clock: () => clock);
      await s.start();
      expect(hr.running, isFalse, reason: 'no preset: no monitoring started');
      await s.discard();
      expect(await s.runs.loadActive(), isNull);
    });

    test('a run is restored after the app was closed', () async {
      await run.start();
      gps.emit(north(0, 0));
      await runFor(60, 3, from: 0, at: 0);
      await run.flush(); // what happens when the app goes to the background
      final id = run.runId;

      // The app is killed and opened again 30 s later.
      clock = t0.add(const Duration(seconds: 90));
      final gps2 = FakeLocation();
      final again = RunSession(runs: repo, hr: hr, location: gps2, clock: () => clock);
      await again.restore();
      expect(again.active, isTrue);
      expect(again.runId, id);
      expect(again.distanceM, closeTo(180, 1));
      expect(again.moving, const Duration(seconds: 90));
      expect(gps2.listening, isTrue, reason: 'keeps recording');
      expect(again.route, hasLength(61));
    });

    test('no location permission: nothing starts', () async {
      gps.access = LocationAccess.denied;
      expect(await run.start(), LocationAccess.denied);
      expect(run.active, isFalse);
      expect(gps.starts, 0);
    });

    test('the simulated runner moves at its pace', () async {
      final sim = SimulatedLocationSource(paceSecPerKm: 300);
      final fixes = <GeoFix>[];
      final sub = sim.start().listen(fixes.add);
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      await sub.cancel();
      await sim.stop();
      expect(fixes.length, greaterThanOrEqualTo(3));
      final d = geoDistanceM(fixes[0].lat, fixes[0].lon, fixes[1].lat, fixes[1].lon);
      expect(d, closeTo(1000 / 300, 0.1));
    });
  });

  testWidgets('start a run from the Run tab, pause, finish and see it in the list', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    final gps = FakeLocation();
    s.run.location = gps;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);

    await tester.tap(find.text('Run').last);
    await settle(tester);
    expect(find.textContaining('Your runs will show up here'), findsOneWidget);
    await tester.tap(find.byKey(const Key('startRun')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('goRun')));
    await countdown(tester);
    expect(find.byKey(const Key('runDistance')), findsOneWidget);
    expect(find.text('Finding GPS…'), findsOneWidget);

    gps.emit(north(0, 0));
    for (var i = 1; i <= 400; i++) {
      gps.emit(north(i * 3.0, i));
    }
    await settle(tester);
    expect(find.text('1.20'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pauseRun')));
    await settle(tester);
    expect(find.text('Paused'), findsOneWidget);
    await tester.tap(find.byKey(const Key('finishRun')));
    await settle(tester);
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.byKey(const Key('summaryDistance')), findsOneWidget);
    expect(find.text('1.20'), findsOneWidget);

    await tester.pageBack();
    await settle(tester);
    expect(find.text('1.20 km'), findsWidgets);
    expect(find.byKey(const Key('runningRunBar')), findsNothing);
    await tearDownApp(tester, s);
  });

  testWidgets('a strength workout cannot start during a run', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    s.run.location = FakeLocation();
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.byKey(const Key('startRunHome')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('goRun')));
    await countdown(tester);
    await tester.tap(find.byKey(const Key('minimizeRun')));
    await settle(tester);
    expect(find.byKey(const Key('runningRunBar')), findsOneWidget);

    await tester.tap(find.byKey(const Key('startStrength')));
    await settle(tester);
    expect(find.text('Run in progress'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(s.session.active, isNull);
    await tester.runAsync(s.run.discard);
    await tearDownApp(tester, s);
  });

  testWidgets('Home › Run always offers the heart-rate zone; the choice is remembered', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    s.run.location = FakeLocation();
    final presetId = (await tester.runAsync(
      () => s.presets.save(name: 'Easy run', min: 130, max: 145, use: PresetUse.run),
    ))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);

    await tester.tap(find.byKey(const Key('startRunHome')));
    await settle(tester);
    expect(find.text('Ready to run'), findsOneWidget);
    expect(find.byKey(const Key('runZoneNew')), findsOneWidget);
    await tester.tap(find.byKey(Key('runZone_$presetId')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('goRun')));
    await countdown(tester);
    expect(s.run.presetId, presetId);
    expect(s.hr.running, isTrue, reason: 'zone beeps on');
    expect(s.hr.range.min, 130);
    await tester.tap(find.byKey(const Key('minimizeRun')));
    await settle(tester);
    await tester.runAsync(s.run.discard);
    expect(s.hr.running, isFalse);

    // Next time the same zone is already picked.
    await tester.tap(find.byKey(const Key('startRunHome')));
    await settle(tester);
    expect(tester.widget<ChoiceChip>(find.byKey(Key('runZone_$presetId'))).selected, isTrue);
    await tester.tap(find.byKey(const Key('runZoneNone')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('goRun')));
    await countdown(tester);
    expect(s.run.presetId, isNull);
    expect(s.hr.running, isFalse);
    await tester.runAsync(s.run.discard);
    await tearDownApp(tester, s);
  });

  testWidgets('swipe left/right between the tabs', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    NavigationBar bar() => tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar().selectedIndex, 0);
    await tester.fling(find.byKey(const Key('tabPages')), const Offset(-400, 0), 1000);
    await settle(tester);
    expect(bar().selectedIndex, 1);
    await tester.fling(find.byKey(const Key('tabPages')), const Offset(-400, 0), 1000);
    await settle(tester);
    expect(bar().selectedIndex, 2);
    await tester.fling(find.byKey(const Key('tabPages')), const Offset(400, 0), 1000);
    await settle(tester);
    expect(bar().selectedIndex, 1);
    // Tapping a tab still jumps straight there.
    await tester.tap(find.text('Profile').last);
    await settle(tester);
    expect(bar().selectedIndex, 4);
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Profile')), findsWidgets);
    await tearDownApp(tester, s);
  });

  testWidgets('3-2-1 countdown with ticks before the run starts; cancel or start now', (tester) async {
    final beeper = SilentBeeper();
    final s = (await tester.runAsync(() => testServices(beeper: beeper)))!;
    s.run.location = FakeLocation();
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);

    await tester.tap(find.byKey(const Key('startRunHome')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('goRun')));
    await tester.pump();
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    expect(s.run.active, isFalse, reason: 'the run starts after the countdown');
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancelCountdown')));
    await settle(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(s.run.active, isFalse, reason: 'cancelled');
    final ticks = beeper.calls.where((c) => c.startsWith('beep 880x1')).length;
    expect(ticks, 2);

    await tester.tap(find.byKey(const Key('startRunHome')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('goRun')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byKey(const Key('startNow')));
    await settle(tester);
    expect(s.run.active, isTrue);
    expect(find.byKey(const Key('runDistance')), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // the countdown timer is gone
    await tester.tap(find.byKey(const Key('pauseRun')));
    await settle(tester);
    expect(s.run.paused, isTrue);
    await tester.runAsync(s.run.discard);
    await tearDownApp(tester, s);
  });

  testWidgets('live map follows you; the summary shows the route from start to finish', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    final gps = FakeLocation();
    s.run.location = gps;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.byKey(const Key('startRunHome')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('goRun')));
    await countdown(tester);

    await tester.tap(find.byKey(const Key('toggleRunMap')));
    await settle(tester);
    expect(find.byKey(const Key('liveMap')), findsOneWidget);
    for (var i = 0; i <= 100; i++) {
      gps.emit(north(i * 3.0, i));
    }
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(find.byKey(const Key('mapMarker_current')), findsOneWidget);
    expect(find.text('0.30'), findsOneWidget, reason: 'distance strip under the map');

    // Dragging the map stops following; the button brings it back.
    await tester.drag(find.byKey(const Key('liveMap')), const Offset(0, 150));
    await settle(tester);
    expect(find.byKey(const Key('followMe')), findsOneWidget);
    await tester.tap(find.byKey(const Key('followMe')));
    await settle(tester);
    expect(find.byKey(const Key('followMe')), findsNothing);

    // Back to the numbers.
    await tester.tap(find.byKey(const Key('toggleRunMap')));
    await settle(tester);
    expect(find.byKey(const Key('liveMap')), findsNothing);

    await tester.tap(find.byKey(const Key('pauseRun')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('finishRun')));
    await settle(tester);
    await tester.tap(find.text('Save'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle(tester);
    expect(find.byKey(const Key('summaryMap')), findsOneWidget);
    expect(find.byKey(const Key('mapMarker_start')), findsOneWidget);
    expect(find.byKey(const Key('mapMarker_end')), findsOneWidget);
    await tester.tap(find.byKey(const Key('openRunMap')));
    await settle(tester);
    expect(find.byType(RunMapScreen), findsOneWidget);
    await tearDownApp(tester, s);
  });

  test('route segments split at pauses', () {
    final segs = routeSegments([
      (lat: 1.0, lon: 1.0, segment: 0),
      (lat: 1.1, lon: 1.0, segment: 0),
      (lat: 2.0, lon: 1.0, segment: 1),
      (lat: 2.1, lon: 1.0, segment: 1),
      (lat: 2.2, lon: 1.0, segment: 1),
    ]);
    expect(segs.map((s) => s.length), [2, 3]);
  });
}
