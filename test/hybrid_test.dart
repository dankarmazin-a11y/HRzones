import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/template_repository.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/run/geo.dart';
import 'package:hrzones/workout/starter_programs.dart';
import 'package:hrzones/workout/workout_session.dart';
import 'package:hrzones/ui/screens/workouts_screen.dart' show openActiveWorkout;

import 'app_test.dart' show settle, tearDownApp;
import 'run_test.dart' show FakeLocation, lat0, lon0;
import 'test_helpers.dart';

/// Services with the real exercise list (the hybrid exercises are in it).
Future<AppServices> hybridServices() => AppServices.open(
  loadExercises: () => File('assets/exercises.json').readAsString(),
  db: memoryDb(),
  hr: HrMonitor(beeper: SilentBeeper()),
);

void main() {
  test('Run and HYROX stations are logged as metres + time', () async {
    final s = await hybridServices();
    for (final id in ['hz_run', 'hz_ski_erg', 'hz_sled_pull', 'hz_burpee_broad_jump', 'hz_sandbag_lunge']) {
      expect((await s.exercises.byId(id))!.trackingType, TrackingType.distance, reason: id);
    }
    expect(
      (await s.exercises.byId('hz_wall_ball'))!.trackingType,
      TrackingType.weightReps,
      reason: 'ball weight × reps',
    );
    await s.close();
  });

  test('a GPS-measured run set ends at its distance, saves metres + time and starts the rest', () async {
    final s = await hybridServices();
    final gps = FakeLocation();
    s.run.location = gps;
    await s.session.startEmpty();
    await s.session.addExercises([(await s.exercises.byId('hz_run'))!]);
    final e = s.session.active!.exercises.single;
    final set = e.sets.first;
    s.session.setDistance(set, 200);
    expect(await s.session.startSetRun(e, set), isNotNull);
    expect(s.session.setRun, isNotNull);
    final t0 = DateTime.now();
    for (var i = 0; i <= 60; i++) {
      gps.emit(
        GeoFix(
          time: t0.add(Duration(seconds: i)),
          lat: lat0 + i * 4 / 111195,
          lon: lon0,
          accuracy: 5,
        ),
      );
      await Future<void>.delayed(Duration.zero);
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(s.session.setRun, isNull, reason: 'stopped by itself at 200 m');
    expect(set.done, isTrue);
    expect(set.distanceM, 200);
    expect(set.durationS, isNotNull);
    expect(s.session.timer?.kind, TimerKind.rest);
    expect((s.hr.beeper as SilentBeeper).calls, contains('beep 880x2'), reason: 'set-done sound');

    // Saved and loaded with the metres.
    await s.session.flush();
    final again = await s.workouts.loadActive();
    expect(again!.exercises.single.sets.first.distanceM, 200);
    s.session.stopTimer();
    await s.session.discard();
    await s.close();
  });

  test('templates and the hybrid starter program keep distance targets', () async {
    const t = TemplateSet(distanceM: 1000);
    expect(TemplateSet.fromJson(t.toJson()).distanceM, 1000);
    final p = starterPrograms.firstWhere((p) => p.name == 'Hybrid Race Prep');
    final slot = p.workouts.first.exercises.first.toSlot();
    expect(slot.exerciseId, 'hz_run');
    expect(slot.sets.single.distanceM, 1000);
    expect(p.workouts.first.exercises[1].scheme, '1 × 1000 m');
  });

  testWidgets('a Run row shows METRES and the GPS button', (tester) async {
    final s = (await tester.runAsync(hybridServices))!;
    s.run.location = FakeLocation();
    await tester.runAsync(() async {
      await s.session.startEmpty();
      await s.session.addExercises([(await s.exercises.byId('hz_run'))!]);
    });
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    openActiveWorkout(tester.element(find.byType(NavigationBar)));
    await settle(tester);
    expect(find.text('METRES'), findsOneWidget);
    expect(find.byKey(const Key('setRun_0')), findsOneWidget);
    await tester.runAsync(s.session.discard);
    await tearDownApp(tester, s);
  });
}
