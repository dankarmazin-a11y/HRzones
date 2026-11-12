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
    expect(find.byKey(const Key('strengthRecords')), findsOneWidget);
    expect(find.byKey(const Key('allTime')), findsNothing);

    await tester.tap(find.byKey(const Key('profileTab_body')));
    await settle(tester);
    expect(find.text('Body measurements'), findsOneWidget);
    await tearDownApp(tester, s);
  });
}
