import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/hr/simulated_hr_source.dart';

void main() {
  testWidgets('shows 4 tabs and switches between them', (tester) async {
    final monitor = HrMonitor(beeper: SilentBeeper());
    await tester.pumpWidget(HrZonesApp(monitor: monitor));

    expect(find.text('HR Zones'), findsOneWidget);
    for (final tab in ['Workouts', 'Progress', 'Profile']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, tab), findsOneWidget);
    }
    monitor.dispose();
  });

  testWidgets('monitoring shows simulated bpm and beeps when above range', (tester) async {
    final beeper = SilentBeeper();
    final source = SimulatedHrSource(bpm: 200);
    final monitor = HrMonitor(source: source, beeper: beeper);
    await tester.pumpWidget(HrZonesApp(monitor: monitor));

    await tester.runAsync(() async {
      await monitor.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(find.text('200'), findsOneWidget);
    expect(find.text('Above range · Zone 5'), findsOneWidget);
    expect(beeper.calls, ['start']);

    await tester.runAsync(monitor.stop);
    await tester.pump();
    expect(find.text('--'), findsOneWidget);
    monitor.dispose();
  });
}
