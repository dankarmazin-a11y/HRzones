import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/data/template_repository.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  testWidgets('Home › Strength offers the templates, or an empty workout', (tester) async {
    final s = (await tester.runAsync(() async {
      final s = await testServices();
      await s.templates.save(
        name: 'Back bicep',
        folder: 'Split',
        slots: [TemplateSlot(exerciseId: 'Barbell_Bench_Press', targetSets: 3)],
      );
      return s;
    }))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);

    await tapStartTile(tester, 'startStrength');
    await settle(tester);
    expect(find.byKey(const Key('quickStartSheet')), findsOneWidget);
    expect(find.text('Split'), findsOneWidget, reason: 'folder heading');
    expect(find.text('1 exercise'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byKey(const Key('quickStartSheet')), matching: find.text('Back bicep')));
    await settle(tester);
    expect(s.session.active?.name, 'Back bicep');
    expect(s.session.active!.exercises.single.sets, hasLength(3));
    await tester.runAsync(s.session.discard);
    await settle(tester);
    await tearDownApp(tester, s);
  });
}
