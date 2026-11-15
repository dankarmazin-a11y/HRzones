import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/data/run_plan_repository.dart';
import 'package:hrzones/data/run_repository.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/run/elevation.dart';
import 'package:hrzones/run/gait.dart';
import 'package:hrzones/run/geo.dart';
import 'package:hrzones/run/run_plan.dart';
import 'package:hrzones/run/run_session.dart';

import 'run_test.dart' show FakeLocation, lat0, lon0, t0;
import 'test_helpers.dart';
import 'walks_test.dart' show outing;

void main() {
  test('run/walk plan: breaks are called "Walk", saved and read back', () {
    expect(runWalkPlan.walkBreaks, isTrue);
    expect(runWalkPlan.description, '8 × run 4 min / walk 1 min');
    final back = PlanSpec.fromJson(runWalkPlan.toJson());
    expect(back.walkBreaks, isTrue);
    expect(back.steps[1].label, 'Walk');
    expect(back.steps[0].label, 'Run');
    final lap = decodeLaps(encodeLaps([Lap(step: back.steps[1], distanceM: 120, seconds: 60)])).single;
    expect(lap.step.walking, isTrue);
    // ordinary intervals keep "Recover"
    expect(PlanSpec.fromJson(defaultPlans[2].$2.toJson()).steps[2].label, 'Recover');
  });

  test('kept to the plan: walked breaks and extra walking', () {
    // run 4 min, walk 1 min, run 4 min (with 1.5 min of walking inside), walk 1 min, run 4 min
    final g = analyzeGait(
      outing([(240, 330, 165), (60, 650, 110), (150, 330, 165), (90, 650, 110), (60, 650, 110), (240, 330, 165)]),
    );
    final k = keptToPlan(g, [
      (walkStep: false, seconds: 240),
      (walkStep: true, seconds: 60),
      (walkStep: false, seconds: 240),
      (walkStep: true, seconds: 60),
      (walkStep: false, seconds: 240),
    ]);
    expect(k.breaks, 2);
    expect(k.walked, 2);
    expect(k.extra, 1, reason: 'the second run part had a long walk');
  });

  test('hike numbers: steepest stretch and highest point', () {
    // 1 km up 100 m (10 %), then 500 m flat
    final pts = [for (var m = 0; m <= 1500; m += 10) (m.toDouble(), m <= 1000 ? m / 10 : 100.0)];
    final h = hikeStats(pts);
    expect(h.steepestPct, closeTo(10, 1));
    expect(h.highestAboveStart, closeTo(100, 2));
  });

  test('a steep walk is saved as a hike', () async {
    var clock = t0;
    final gps = FakeLocation();
    final repo = RunRepository(memoryDb());
    final run = RunSession(
      runs: repo,
      hr: HrMonitor(beeper: SilentBeeper()),
      location: gps,
      clock: () => clock,
    );
    await run.start(activity: RunActivity.walk);
    var m = 0.0;
    for (var s = 0; s <= 1200; s++) {
      clock = t0.add(Duration(seconds: s));
      // 11:00 /km, climbing 60 m per km (GPS height)
      gps.emit(GeoFix(time: clock, lat: lat0 + m / 111195, lon: lon0, accuracy: 5, altitude: 50 + m * 0.06));
      m += 1000 / 660;
      await Future<void>.delayed(Duration.zero);
    }
    final id = await run.finish();
    expect((await repo.byId(id!))!.activity, RunActivity.hike);
    expect(run.takeLabelNote(), contains('hike'));
  });

  test('the run/walk plan is added once to older installs, never twice', () async {
    final db = memoryDb();
    final plans = RunPlanRepository(db);
    // an older install: the built-ins were added before run/walk existed
    await db.setSetting('runPlansSeeded', '1');
    await plans.seedRunWalk();
    await plans.seedRunWalk();
    expect((await plans.watchAll().first).where((p) => p.name.startsWith('Run/walk')), hasLength(1));
    // a new install: from the built-ins only
    final db2 = memoryDb();
    final fresh = RunPlanRepository(db2);
    await fresh.seedRunWalk();
    await fresh.seedDefaults();
    expect((await fresh.watchAll().first).where((p) => p.name.startsWith('Run/walk')), hasLength(1));
  });
}
