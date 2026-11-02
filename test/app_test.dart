import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/hr/simulated_hr_source.dart';

import 'test_helpers.dart';

/// Lets real async work (database queries) run, then rebuilds.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Unmounts the app so drift stream subscriptions are cancelled.
/// (The in-memory DB is not closed: closing inside the fake clock hangs.)
Future<void> tearDownApp(WidgetTester tester, AppServices s) async {
  await tester.pumpWidget(const SizedBox());
  await settle(tester);
  s.hr.stop();
}

void main() {
  testWidgets('shows 4 tabs and switches between them', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);

    expect(find.text('HR Zones'), findsOneWidget);
    for (final tab in ['Workouts', 'Progress', 'Profile']) {
      await tester.tap(find.text(tab).last);
      await settle(tester);
      expect(find.widgetWithText(AppBar, tab), findsOneWidget);
    }
    await tearDownApp(tester, s);
  });

  testWidgets('start an empty workout, add an exercise, log a set', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);

    await tester.tap(find.text('Start strength workout'));
    await settle(tester);
    expect(find.text('Finish'), findsOneWidget);

    await tester.tap(find.text('Add exercises'));
    await settle(tester);
    await tester.tap(find.text('Barbell Bench Press'));
    await settle(tester);
    await tester.tap(find.text('Add 1'));
    await settle(tester);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('PREVIOUS'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '60');
    await tester.enterText(fields.at(1), '8');
    await tester.tap(find.byIcon(Icons.check_box_outline_blank));
    await settle(tester);
    expect(find.textContaining('Rest '), findsOneWidget);
    expect(s.session.active!.completedSets.single.weightKg, 60);

    await tester.tap(find.text('Skip'));
    await tester.tap(find.text('Finish'));
    await settle(tester);
    await settle(tester);
    expect(find.text('Workout complete'), findsOneWidget);
    expect(find.text('480 kg'), findsOneWidget);
    await tearDownApp(tester, s);
  });

  testWidgets('monitoring shows simulated bpm and the status', (tester) async {
    final beeper = SilentBeeper();
    final s = (await tester.runAsync(() => testServices(beeper: beeper, source: SimulatedHrSource(bpm: 200))))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);

    await tester.runAsync(() async {
      await s.hr.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.scrollUntilVisible(find.byKey(const Key('bpm')), 200);
    expect(tester.widget<Text>(find.byKey(const Key('bpm'))).data, '200');
    expect(find.text('Above range · Zone 5'), findsOneWidget);
    expect(beeper.calls, contains('start'));

    await tester.runAsync(s.hr.stop);
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('bpm'))).data, '--');
    await tearDownApp(tester, s);
  });
}
