import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/run_repository.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/run/geo.dart';
import 'package:hrzones/run/run_session.dart';
import 'package:hrzones/run/run_voice.dart';
import 'package:hrzones/ui/run/run_progress.dart';
import 'package:hrzones/ui/run/run_summary_screen.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'run_test.dart' show FakeLocation, lat0, lon0, summaryList, t0;
import 'runs_everywhere_test.dart' show recordRun;
import 'test_helpers.dart';

void main() {
  test('same route: found for a run that starts and ends at the same places', () async {
    final s = await testServices();
    final a = await recordRun(s, DateTime(2026, 11, 1, 7), km: 2, mps: 3);
    final b = await recordRun(s, DateTime(2026, 11, 3, 7), km: 2, mps: 3.3);
    final c = await recordRun(s, DateTime(2026, 11, 4, 7), km: 3.5, mps: 3); // longer – another route
    expect((await s.runs.sameRoute((await s.runs.byId(b))!))?.id, a);
    expect(await s.runs.sameRoute((await s.runs.byId(a))!), isNull, reason: 'nothing earlier');
    expect(await s.runs.sameRoute((await s.runs.byId(c))!), isNull);
    await s.close();
  });

  test('racing an earlier run: ahead/behind at the same distance, said every km', () async {
    final s = await testServices();
    final old = await recordRun(s, DateTime(2026, 11, 1, 7), km: 2.2, mps: 3); // 1 km in ~333 s
    final ghost = await s.runs.ghostOf((await s.runs.byId(old))!);
    expect(ghost.timeAt(1000), closeTo(333, 4));

    final beeper = SilentBeeper();
    var clock = t0;
    final gps = FakeLocation();
    final run = RunSession(
      runs: RunRepository(memoryDb()),
      hr: HrMonitor(beeper: beeper),
      location: gps,
      clock: () => clock,
    )..voice = RunVoice(beeper.speak);
    await run.start(ghost: ghost);
    gps.emit(GeoFix(time: t0, lat: lat0, lon: lon0, accuracy: 5));
    for (var i = 1; i <= 260; i++) {
      clock = t0.add(Duration(seconds: i));
      gps.emit(GeoFix(time: clock, lat: lat0 + i * 4 / 111195, lon: lon0, accuracy: 5)); // 4 m/s – faster
      await Future<void>.delayed(Duration.zero);
    }
    expect(run.ghostDelta, lessThan(-70), reason: 'over a minute ahead after 1 km');
    expect(beeper.spoken.last, matches(RegExp(r'1 minute \d+ seconds ahead of last time\.$')));
    expect(spokenGhost(8), '8 seconds behind last time.');
    expect(spokenGhost(0.4), 'Level with last time.');
    await run.discard();
    await s.close();
  });

  testWidgets('progress charts and "same route" on the summary', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    final ids = (await tester.runAsync(() async {
      final now = DateTime.now();
      return [
        await recordRun(s, now.subtract(const Duration(days: 9)), km: 2, mps: 3),
        await recordRun(s, now.subtract(const Duration(days: 2)), km: 2, mps: 3.2),
      ];
    }))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    final nav = Navigator.of(tester.element(find.byType(NavigationBar)));
    nav.push(MaterialPageRoute(builder: (_) => const RunProgressScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);
    expect(find.byKey(const Key('weeklyKmChart')), findsOneWidget);
    expect(find.byKey(const Key('paceChart')), findsOneWidget);
    await tester.pageBack();
    await settle(tester);

    nav.push(MaterialPageRoute(builder: (_) => RunSummaryScreen(runId: ids[1])));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('runCompare')), 200, scrollable: summaryList());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle(tester);
    expect(find.textContaining('Same route as'), findsOneWidget);
    expect(find.byKey(const Key('compareTime')), findsOneWidget);
    expect(find.byKey(const Key('raceThisRun')), findsOneWidget);
    await tearDownApp(tester, s);
  });
}
