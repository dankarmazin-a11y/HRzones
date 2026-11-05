import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/export/export_data.dart';
import 'package:hrzones/run/geo.dart';
import 'package:hrzones/run/run_session.dart';
import 'package:hrzones/ui/history/history_screen.dart';
import 'package:hrzones/ui/screens/run_screen.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'run_test.dart' show FakeLocation, lat0, lon0;
import 'test_helpers.dart';

/// Records a finished run of [km] at [mps] m/s starting at [start].
Future<String> recordRun(AppServices s, DateTime start, {double km = 1.2, double mps = 3}) async {
  var clock = start;
  final gps = FakeLocation();
  final run = RunSession(runs: s.runs, hr: s.hr, location: gps, clock: () => clock);
  await run.start();
  gps.emit(GeoFix(time: start, lat: lat0, lon: lon0, accuracy: 5));
  for (var i = 1; i <= km * 1000 / mps; i++) {
    clock = start.add(Duration(seconds: i));
    gps.emit(GeoFix(time: clock, lat: lat0 + i * mps / 111195, lon: lon0, accuracy: 5));
    await Future<void>.delayed(Duration.zero);
  }
  final id = (await run.finish())!;
  run.dispose();
  return id;
}

void main() {
  test('runs and their km splits are in the spreadsheet', () async {
    final s = await testServices();
    await recordRun(s, DateTime(2026, 11, 3, 7), km: 2.1);
    final zip = ZipDecoder().decodeBytes(await exportWorkbook(s.db));
    String file(String n) => utf8.decode(zip.findFile(n)!.content as List<int>);
    expect(file('xl/workbook.xml'), allOf(contains('Runs'), contains('Run splits')));
    final runs = file('xl/worksheets/sheet3.xml');
    expect(runs, contains('Best 1 km (min)'));
    expect(RegExp(r'<v>2\.\d+</v>').hasMatch(runs), isTrue, reason: 'distance in km');
    final splits = file('xl/worksheets/sheet4.xml');
    expect(RegExp(r'r="B4"').hasMatch(splits), isTrue, reason: 'header + 3 splits (1, 2, 0.1 km)');
    await s.close();
  });

  test('running goals: km this week, one long run, a time at a distance', () async {
    final s = await testServices();
    final now = DateTime.now();
    await s.goals.addRun(GoalType.runKmPerWeek, 10);
    await s.goals.addRun(GoalType.runDistance, 5);
    await s.goals.addRun(GoalType.runTime, 5, distanceM: 1000); // 1 km under 5:00
    await recordRun(s, now.subtract(const Duration(minutes: 30)), km: 2, mps: 4); // 1 km in ~4:10
    final goals = await s.goals.watchAll().first;
    final p = {for (final g in goals) g.type: await s.goals.progress(g)};
    expect(p[GoalType.runKmPerWeek]!.current, closeTo(2, 0.05));
    expect(p[GoalType.runKmPerWeek]!.progress, closeTo(0.2, 0.01));
    expect(p[GoalType.runDistance]!.progress, closeTo(0.4, 0.01));
    expect(p[GoalType.runTime]!.title, '1 km under 5:00');
    expect(p[GoalType.runTime]!.achieved, isTrue);
    await s.close();
  });

  testWidgets('History lists runs with strength workouts; filter by kind', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.runAsync(() => recordRun(s, DateTime.now().subtract(const Duration(hours: 2))));
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.text('Strength').last);
    await settle(tester);
    final nav = Navigator.of(tester.element(find.byType(NavigationBar)));
    nav.push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle(tester);
    final inHistory = find.descendant(of: find.byType(HistoryScreen), matching: find.byType(RunTile));
    expect(inHistory, findsOneWidget);
    await tester.tap(find.descendant(of: find.byKey(const Key('historyFilter')), matching: find.text('Strength')));
    await settle(tester);
    expect(inHistory, findsNothing);
    expect(find.text('No workouts yet'), findsOneWidget);
    await tearDownApp(tester, s);
  });
}
