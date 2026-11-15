import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/run/motion_source.dart';
import 'package:hrzones/ui/steps/steps_card.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

/// A phone that counted these steps (oldest first, today last).
class StepsMotion extends NoMotionSource {
  StepsMotion(this.week);
  final List<int> week;

  @override
  Future<List<int>?> dailySteps(int days) async => week.sublist(week.length - days);
}

void main() {
  testWidgets('Home shows today\'s steps towards the goal; tap to change the goal', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    s.run.motion = StepsMotion([9000, 4000, 12000, 8000, 3000, 8500, 7420]);
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);
    expect(find.byKey(const Key('stepsToday')), findsOneWidget);
    expect(find.text('7,420'), findsOneWidget);
    expect(find.text('580 to go'), findsOneWidget);
    expect(find.text('Goal reached 4 of 7 days'), findsOneWidget);
    await tester.tap(find.byKey(const Key('stepsToday')));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, '7000');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(s.stepGoal.value, 7000);
    expect(await tester.runAsync(() => s.db.getSetting('stepGoal')), '7000');
    expect(find.text('Goal reached'), findsOneWidget);
    await tearDownApp(tester, s);
  });

  testWidgets('no step counter (or goal 0): no card', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    expect(find.byType(StepsTodayCard), findsOneWidget);
    expect(find.byKey(const Key('stepsToday')), findsNothing);
    await tearDownApp(tester, s);
  });
}
