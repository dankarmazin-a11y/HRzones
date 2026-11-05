import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/ui/screens/run_screen.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'run_test.dart' show FakeLocation, countdown, north;
import 'runs_everywhere_test.dart' show recordRun;
import 'test_helpers.dart';

void main() {
  test('km per pair: start km + runs; default; retire; delete keeps the runs', () async {
    final s = await testServices();
    final a = await s.shoes.save(name: 'Pegasus', startKm: 100, limitKm: 102);
    final b = await s.shoes.save(name: 'Trail');
    expect((await s.shoes.defaultShoe())!.id, a, reason: 'the first pair is the default');

    final run = await recordRun(s, DateTime(2026, 11, 4, 7), km: 2.1);
    await s.shoes.setRunShoe(run, a);
    final list = await s.shoes.all();
    final peg = list.firstWhere((x) => x.shoe.id == a);
    expect(peg.km, closeTo(102.1, 0.05));
    expect(peg.wornOut, isTrue);
    expect(list.first.shoe.id, a, reason: 'default first');

    await s.shoes.setDefault(b);
    expect((await s.shoes.defaultShoe())!.id, b);
    await s.shoes.setRetired(b, true);
    expect(await s.shoes.defaultShoe(), isNull, reason: 'a retired pair is no default');
    expect((await s.shoes.all()).last.shoe.id, b, reason: 'retired last');

    await s.shoes.delete(a);
    expect((await s.runs.byId(run))!.shoeId, isNull);
    expect((await s.runs.byId(run))!.distanceM, greaterThan(2000));
    await s.close();
  });

  testWidgets('add shoes on the Run tab; the default pair is picked for the next run', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    final gps = FakeLocation();
    s.run.location = gps;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.text('Run').last);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('shoesCard')),
      200,
      scrollable: find.descendant(of: find.byType(RunScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.tap(find.byKey(const Key('shoesCard')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('addShoe')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('shoeName')), 'Pegasus 41');
    await tester.tap(find.byKey(const Key('saveShoe')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);
    expect(find.text('Pegasus 41'), findsOneWidget);
    expect(find.text('Used for new runs'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('startRun')),
      -200,
      scrollable: find.descendant(of: find.byType(RunScreen), matching: find.byType(Scrollable)).first,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('startRun')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);
    final shoe = (await tester.runAsync(s.shoes.defaultShoe))!;
    expect(tester.widget<ChoiceChip>(find.byKey(Key('runShoe_${shoe.id}'))).selected, isTrue);
    await tester.tap(find.byKey(const Key('goRun')));
    await countdown(tester);
    gps.emit(north(0, 0));
    expect(s.run.shoeId, shoe.id);
    await tester.runAsync(s.run.discard);
    await tearDownApp(tester, s);
  });
}
