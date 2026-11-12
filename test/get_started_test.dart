import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  testWidgets('Empty Strength and Run tabs show the guided steps', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Strength')));
    await settle(tester);
    expect(find.byKey(const Key('strengthGuide')), findsOneWidget);
    expect(find.text('1 of 4'), findsOneWidget);
    // The first open step (program or template) shows its two buttons.
    expect(find.text('Starter programs'), findsWidgets);
    expect(find.byKey(const Key('guideAction_program_1')), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Run')));
    await settle(tester);
    expect(find.byKey(const Key('runGuide'), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const Key('guideAction_zone_0'), skipOffstage: false), findsOneWidget);
    await tearDownApp(tester, s);
  });
}
