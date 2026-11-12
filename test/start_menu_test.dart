import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/ui/screens/profile_screen.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  testWidgets('Start opens the menu; during a workout it goes back to the workout', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    expect(find.text('Start'), findsOneWidget);
    // No Tools tab any more.
    expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Tools')), findsNothing);

    await tester.tap(find.byKey(const Key('startButton')));
    await settle(tester);
    for (final k in ['startStrength', 'startRunHome', 'startEmpty', 'startTimer']) {
      expect(find.byKey(Key(k)), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('startEmpty')));
    await settle(tester);
    expect(s.session.active, isNotNull);

    // Leave the workout screen; the Start button now says Back and returns to it.
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await settle(tester);
    expect(find.text('Back'), findsOneWidget);
    await tester.tap(find.byKey(const Key('startButton')));
    await settle(tester);
    expect(find.byKey(const Key('startStrength')), findsNothing);
    await tester.runAsync(s.session.discard);
    await tearDownApp(tester, s);
  });

  testWidgets('Tools live on Home (row) and in Profile (list)', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    for (final id in ['zones', 'timers', 'abs', 'plates']) {
      expect(find.byKey(Key('homeTool_$id')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('homeTool_timers')));
    await settle(tester);
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Timers')), findsOneWidget);
    await tester.pageBack();
    await settle(tester);

    await tester.tap(find.text('Profile').last);
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('profileTool_plates')),
      200,
      scrollable: find.descendant(of: find.byType(ProfileScreen), matching: find.byType(Scrollable)).first,
    );
    expect(find.byKey(const Key('profileTool_zones')), findsOneWidget);
    expect(find.byKey(const Key('openSettings')), findsOneWidget);
    await tearDownApp(tester, s);
  });
}
