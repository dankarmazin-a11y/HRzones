import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/ui/run/share_run.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'runs_everywhere_test.dart' show recordRun;
import 'test_helpers.dart';

void main() {
  testWidgets('the share picture shows the route and the numbers', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    final id = (await tester.runAsync(() => recordRun(s, DateTime(2026, 11, 5, 7), km: 2.1)))!;
    final run = (await tester.runAsync(() => s.runs.byId(id)))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    Navigator.of(tester.element(find.byType(NavigationBar)))
        .push(MaterialPageRoute(builder: (_) => ShareRunScreen(run: run)));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);
    expect(find.byKey(const Key('shareCard')), findsOneWidget);
    expect(find.textContaining(' km'), findsWidgets);
    expect(find.text('HR Zones'), findsOneWidget);
    expect(find.byKey(const Key('shareRunNow')), findsOneWidget);
    await tearDownApp(tester, s);
  });
}
