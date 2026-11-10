import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/data/goal_repository.dart';
import 'package:hrzones/ui/goals_section.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  testWidgets('Home shows the unfinished goal you are closest to, and it updates', (tester) async {
    final s = (await tester.runAsync(() async {
      final s = await testServices();
      await s.body.add('weight', 90);
      await s.body.add('waist', 100);
      await s.goals.addMeasurement('weight', 80); // starts at 90
      await s.goals.addMeasurement('waist', 90); // starts at 100
      await s.body.add('waist', 95); // waist 50 % of the way, weight 0 %
      return s;
    }))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    final card = find.byKey(const Key('closestGoal'));
    expect(card, findsOneWidget);
    expect(find.descendant(of: card, matching: find.textContaining('Waist')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('50%')), findsOneWidget);

    // Weight moves closer than the waist → the card switches.
    await tester.runAsync(() => s.body.add('weight', 82));
    await settle(tester);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle(tester);
    expect(find.descendant(of: card, matching: find.textContaining('weight')), findsOneWidget);
    await tearDownApp(tester, s);
  });

  test('achieved goals are skipped', () {
    expect(ClosestGoalCard.pick(const <GoalProgress>[]), isNull);
  });
}
