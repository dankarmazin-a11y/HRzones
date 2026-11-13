import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  testWidgets('type filter shows only stretches', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.text('Strength').last);
    await settle(tester);
    await tester.ensureVisible(find.text('Exercises', skipOffstage: false));
    await settle(tester);
    await tester.tap(find.text('Exercises'));
    await settle(tester);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    await tester.tap(find.text('Stretching'));
    await settle(tester);
    expect(find.text('Plank'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsNothing);
    await tearDownApp(tester, s);
  });
}
