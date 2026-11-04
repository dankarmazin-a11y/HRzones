import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  testWidgets('each tab keeps its own scroll position; tapping the tab again scrolls to the top', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.text('Profile').last);
    await settle(tester);
    expect(find.textContaining('streak'), findsWidgets);

    // Scroll Profile to the bottom.
    await tester.drag(find.byType(ListView).last, const Offset(0, -3000));
    await settle(tester);
    expect(find.text('Export to spreadsheet'), findsOneWidget);
    expect(find.textContaining('week streak'), findsNothing);

    // Home is not scrolled by that.
    await tester.tap(find.text('Home').last);
    await settle(tester);
    expect(find.textContaining('week streak'), findsOneWidget);

    // Back on Profile it is still at the bottom; a second tap goes to the top.
    await tester.tap(find.text('Profile').last);
    await settle(tester);
    expect(find.text('Export to spreadsheet'), findsOneWidget);
    await tester.tap(find.text('Profile').last);
    await settle(tester);
    expect(find.textContaining('week streak'), findsOneWidget);
    await tearDownApp(tester, s);
  });
}
