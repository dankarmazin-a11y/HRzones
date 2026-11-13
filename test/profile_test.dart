import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/ui/profile/profile_widgets.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  test('milestones: earned and the next ones', () {
    final none = milestones(const TrainingData([], []));
    expect(none.where((m) => m.earned), isEmpty);
    expect(none.first.top, '10');
  });

  testWidgets('Profile: Overview, Records and Body & gear tabs', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.text('Profile').last);
    await settle(tester);
    expect(find.byKey(const Key('allTime')), findsOneWidget);
    expect(find.byKey(const Key('monthCalendar')), findsOneWidget);
    expect(find.byKey(Key('calDay_${DateTime.now().day}')), findsOneWidget);

    await tester.tap(find.byKey(const Key('profileTab_records')));
    await settle(tester);
    expect(find.byKey(const Key('strengthRecords'), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const Key('goalsReached')), findsOneWidget);
    expect(find.textContaining('Goals you reach show up here'), findsOneWidget, reason: 'no goal reached yet');
    expect(find.byKey(const Key('allTime')), findsNothing);

    await tester.tap(find.byKey(const Key('profileTab_body')));
    await settle(tester);
    expect(find.text('Body measurements'), findsOneWidget);
    await tearDownApp(tester, s);
  });

  testWidgets('a reached goal shows in Records with a check and the date it was reached', (tester) async {
    final s = (await tester.runAsync(() async {
      final s = await testServices();
      await s.body.add('weight', 82);
      await s.goals.addMeasurement('weight', 80);
      await s.body.add('weight', 79.5); // goal reached
      return s;
    }))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.text('Profile').last);
    await settle(tester);
    await tester.tap(find.byKey(const Key('profileTab_records')));
    await settle(tester);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle(tester);
    expect(
      find.descendant(of: find.byKey(const Key('goalsReached')), matching: find.byIcon(Icons.check_rounded)),
      findsOneWidget,
    );
    expect(find.textContaining('Reached'), findsOneWidget);
    final g = (await tester.runAsync(() => s.goals.watchAll().first))!.single;
    expect(g.achievedAt, isNotNull, reason: 'the day it was reached is saved');
    await tearDownApp(tester, s);
  });
}
