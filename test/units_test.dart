import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/data/body_repository.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/run/geo.dart';
import 'package:hrzones/run/run_voice.dart';
import 'package:hrzones/run/splits.dart';
import 'package:hrzones/ui/screens/settings_screen.dart';
import 'package:hrzones/ui/workout/active_workout_screen.dart';
import 'package:hrzones/ui/workout/running_workout_bar.dart';
import 'package:hrzones/units/units.dart';
import 'package:hrzones/workout/stats.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  // Units are global: every test starts and ends in kg / cm / km.
  setUp(() => Units.notifier.value = const UnitPrefs());
  tearDown(() => Units.notifier.value = const UnitPrefs());

  void imperial() =>
      Units.notifier.value = const UnitPrefs(weight: WeightUnit.lb, length: LengthUnit.inch, distance: DistanceUnit.mi);

  test('the setting is saved as "kg,cm,km" and survives bad values', () {
    const u = UnitPrefs(weight: WeightUnit.lb, length: LengthUnit.cm, distance: DistanceUnit.mi);
    expect(u.encode(), 'lb,cm,mi');
    expect(UnitPrefs.decode('lb,cm,mi'), u);
    expect(UnitPrefs.decode(null), const UnitPrefs());
    expect(UnitPrefs.decode('stone'), const UnitPrefs());
  });

  test('stored kg / cm / metres show in the chosen units', () {
    expect(formatWeight(60), '60 kg');
    expect(formatKm(5000), '5.00');
    expect(formatPace(300), '5:00');
    imperial();
    expect(formatWeight(60), '132.3 lb');
    expect(formatW(Units.fromW(135)), '135', reason: 'typed pounds come back exactly');
    expect(formatKm(1609.344), '1.00');
    expect(formatPace(300), '8:03', reason: '5:00 per km is about 8:03 per mile');
    expect(Units.paceIn(Units.paceOut(300)!), closeTo(300, 0.001));
    expect(kindOf('waist').shownUnit, 'in');
    expect(kindOf('waist').toShown(81.28), closeTo(32, 0.001));
    expect(kindOf('weight').shownUnit, 'lb');
    expect(kindOf('bodyFat').shownUnit, '%');
    expect(spokenKm(1609.344), '1 mile');
    expect(spokenPace(300), '8 minutes 3 per mile');
  });

  test('mile splits', () {
    SplitPoint pt(double metres, int s) => (
      time: DateTime(2026, 1, 1).add(Duration(seconds: s)),
      lat: 32 + metres / 111320,
      lon: 34.0,
      accuracy: 5.0,
      segment: 0,
      hr: null,
    );
    // 2 miles at 4 m/s, then 400 m more.
    final pts = [for (var i = 0; i <= 900; i++) pt(i * 4.0, i)];
    final splits = computeSplits(pts, splitM: Units.metresPerMile);
    expect(splits, hasLength(3));
    expect(splits[0].distanceM, closeTo(1609.344, 0.5));
    expect(splits[0].partial, isFalse);
    expect(splits[0].seconds, closeTo(402, 2));
    expect(splits[2].partial, isTrue);
  });

  testWidgets('Settings › Units switches to pounds and miles; weights typed in lb are stored in kg', (tester) async {
    final s = (await tester.runAsync(() async {
      final s = await testServices();
      await s.session.startEmpty();
      await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
      return s;
    }))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Services(services: s, child: const SettingsScreen()),
      ),
    );
    await settle(tester);
    await tester.tap(find.descendant(of: find.byKey(const Key('unitsWeight')), matching: find.text('lb')));
    await settle(tester);
    await tester.tap(find.descendant(of: find.byKey(const Key('unitsDistance')), matching: find.text('mile')));
    await settle(tester);
    expect(Units.lb, isTrue);
    expect(Units.mi, isTrue);
    expect(await tester.runAsync(() => s.db.getSetting('units')), 'lb,cm,mi');

    // The workout now asks for pounds.
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.byType(RunningWorkoutBar));
    await settle(tester);
    expect(find.text('LB'), findsWidgets);
    await tester.enterText(find.byType(SetNumberField).first, '135');
    await tester.pump();
    expect(s.session.active!.exercises.single.sets.first.weightKg, closeTo(61.235, 0.001));
    await tester.runAsync(s.session.discard);
    await tearDownApp(tester, s);
  });
}
