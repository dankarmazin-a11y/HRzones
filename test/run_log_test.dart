import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/run_repository.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/notify/rest_notifier.dart';
import 'package:hrzones/run/geo.dart';
import 'package:hrzones/run/run_session.dart';
import 'package:hrzones/ui/run/edit_run_screen.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'run_test.dart' show FakeLocation, lat0, lon0, t0;
import 'test_helpers.dart';

void main() {
  late FakeLocation gps;
  late RunSession run;
  late RunRepository repo;
  late SilentRestNotifier notifier;
  late DateTime clock;

  setUp(() {
    gps = FakeLocation();
    clock = t0;
    repo = RunRepository(memoryDb());
    notifier = SilentRestNotifier();
    run = RunSession(
      runs: repo,
      hr: HrMonitor(beeper: SilentBeeper()),
      location: gps,
      clock: () => clock,
    )..notifier = notifier;
  });

  var pos = 0.0;
  Future<void> move(double mps, int seconds, {required int from}) async {
    if (from == 0) pos = 0;
    for (var i = from + 1; i <= from + seconds; i++) {
      clock = t0.add(Duration(seconds: i));
      pos += mps;
      gps.emit(GeoFix(time: clock, lat: lat0 + pos / 111195, lon: lon0, accuracy: 5));
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('treadmill run: no GPS, the distance is typed in at the end, no records', () async {
    await run.start(treadmill: true);
    expect(gps.starts, 0);
    expect(run.gps, GpsStatus.off);
    clock = t0.add(const Duration(minutes: 30));
    final id = await run.finish(distanceM: 5200);
    final r = (await repo.byId(id!))!;
    expect(r.kind, RunKind.treadmill);
    expect(r.distanceM, 5200);
    expect(r.durationS, 1800);
    expect(await repo.bestsFor(r), isEmpty);
  });

  test('"Still running?": no movement for 20 min; keep going; finish where you stopped', () async {
    await run.start();
    gps.emit(GeoFix(time: t0, lat: lat0, lon: lon0, accuracy: 5));
    await move(3, 300, from: 0); // 900 m in 5 min
    await run.flush();
    expect(notifier.runIdleScheduled.last.$1, const Duration(minutes: 20), reason: '20 min after the last move');
    // Standing still (GPS jitter only) for 25 minutes.
    for (var i = 301; i <= 1800; i += 30) {
      clock = t0.add(Duration(seconds: i));
      gps.emit(GeoFix(time: clock, lat: lat0 + (pos + (i.isEven ? 1 : -1)) / 111195, lon: lon0, accuracy: 5));
      await Future<void>.delayed(Duration.zero);
    }
    expect(run.idleFor, greaterThanOrEqualTo(RunSession.idleAfter));
    await run.keepGoing();
    expect(run.idleFor, Duration.zero);

    final stoppedAt = t0.add(const Duration(seconds: 300));
    final id = await run.finish(endAt: stoppedAt);
    final r = (await repo.byId(id!))!;
    expect(r.endedAt, stoppedAt);
    expect(r.durationS, 300);
    expect(r.distanceM, closeTo(900, 10));
    expect((await repo.points(id)).last.time.isAfter(stoppedAt), isFalse);
    expect(notifier.runIdleCancelled, 1);
  });

  test('paused for 30 min counts as forgotten; keep going snoozes it', () async {
    await run.start();
    await run.pause();
    expect(notifier.runIdleScheduled.last, (const Duration(minutes: 30), true));
    clock = t0.add(const Duration(minutes: 31));
    expect(run.idleFor, greaterThan(Duration.zero));
    await run.keepGoing();
    expect(run.idleFor, Duration.zero);
    clock = t0.add(const Duration(minutes: 62));
    expect(run.idleFor, greaterThan(Duration.zero));
  });

  test('log a run by hand, edit it, cut the end of a recorded run', () async {
    final id = await repo.logRun(startedAt: t0, durationS: 1500, distanceM: 5000, avgHr: 150);
    var r = (await repo.byId(id))!;
    expect(r.endedAt, t0.add(const Duration(minutes: 25)));
    expect(await repo.bestsFor(r), isEmpty, reason: 'no records for runs logged by hand');
    await repo.updateRun(r, distanceM: 5100, durationS: 1530, kind: RunKind.treadmill);
    r = (await repo.byId(id))!;
    expect((r.distanceM, r.durationS, r.kind), (5100, 1530, RunKind.treadmill));
    await repo.updateNotes(id, effort: 7, weather: 'sunny,wind', notes: 'Felt good');
    r = (await repo.byId(id))!;
    expect((r.effort, r.weather, r.notes), (7, 'sunny,wind', 'Felt good'));

    // A recorded run: 600 m in 200 s, then it kept recording another 600 m.
    await run.start();
    gps.emit(GeoFix(time: t0, lat: lat0, lon: lon0, accuracy: 5));
    await move(3, 400, from: 0);
    final rid = (await run.finish())!;
    final rec = (await repo.byId(rid))!;
    expect(rec.distanceM, closeTo(1200, 10));
    await repo.trimEnd(rec, t0.add(const Duration(seconds: 200)));
    final cut = (await repo.byId(rid))!;
    expect(cut.distanceM, closeTo(600, 10));
    expect(cut.durationS, 200);
    expect(cut.bestsJson, isNull, reason: 'worked out again');
  });

  testWidgets('log a run from the Run tab, then rate how it felt', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.text('Run').last);
    await settle(tester);
    await tester.tap(find.byKey(const Key('logRun')));
    await settle(tester);
    expect(find.byType(EditRunScreen), findsOneWidget);
    await tester.tap(find.text('Treadmill').last);
    await tester.tap(find.byKey(const Key('saveRun')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle(tester);
    expect(find.text('Treadmill run – no route'), findsOneWidget);
    await tester.tap(find.byKey(const Key('effort_6')));
    await tester.tap(find.byKey(const Key('weather_rain')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle(tester);
    final r = (await tester.runAsync(() => s.runs.watchFinished().first))!.single;
    expect(r.kind, RunKind.treadmill);
    expect(r.distanceM, 5000);
    expect(r.effort, 6);
    expect(r.weather, 'rain');
    await tearDownApp(tester, s);
  });
}
