import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/ui/screens/tools_screen.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/exercise_repository.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  test('a weight fills the following sets (empty or still the old value), not done ones', () async {
    final s = await testServices();
    await s.session.startEmpty();
    final bench = (await s.exercises.byId('Barbell_Bench_Press'))!;
    await s.session.addExercises([bench]);
    final e = s.session.active!.exercises.single;
    for (var i = 0; i < 4; i++) {
      s.session.addSet(e);
    }
    final sets = e.sets; // 5 sets
    sets[0].type = SetType.warmup; // first one is a warm-up
    expect(sets[0].type, SetType.warmup);

    // Typing "6" then "60" in set 2: sets 3–5 follow, the warm-up doesn't.
    s.session.setWeight(sets[1], 6);
    s.session.setWeight(sets[1], 60);
    expect(sets.map((x) => x.weightKg), [null, 60, 60, 60, 60]);

    // A hand-typed pyramid isn't overwritten.
    s.session.setWeight(sets[3], 70);
    s.session.setWeight(sets[1], 62.5);
    expect(sets.map((x) => x.weightKg), [null, 62.5, 62.5, 70, 70]);

    // Done sets keep their weight.
    s.session.setReps(sets[2], 5);
    s.session.toggleDone(e, sets[2]);
    s.session.setWeight(sets[1], 65);
    expect(sets[2].weightKg, 62.5);

    // Warm-up weights only go to later warm-ups.
    s.session.setWeight(sets[0], 40);
    expect(sets.map((x) => x.weightKg), [40, 65, 62.5, 70, 70]);
    s.session.stopTimer();
    await s.session.discard();
    await s.close();
  });

  test('the rest timer ends with a ding', () async {
    final beeper = SilentBeeper();
    final s = await testServices(beeper: beeper);
    await s.session.startEmpty();
    s.session.startRest(1);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    expect(beeper.calls, contains('ding'));
    await s.session.discard();
    await s.close();
  });

  testWidgets('Home has an add-goal button once a goal exists', (tester) async {
    final s = (await tester.runAsync(() async {
      final s = await testServices();
      await s.goals.addLift('Barbell_Bench_Press', 100);
      return s;
    }))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    expect(find.byKey(const Key('addGoalHome'), skipOffstage: false), findsOneWidget);
    await tearDownApp(tester, s);
  });

  testWidgets('Tools shows a guide; closing it is remembered', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await openTools(tester);
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('How the tools work'),
      200,
      scrollable: find.descendant(of: find.byType(ToolsScreen), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('How the tools work'), findsOneWidget);
    expect(find.textContaining('3 high beeps', skipOffstage: false), findsWidgets); // open the first time
    await tester.ensureVisible(find.text('How the tools work'));
    await settle(tester);
    await tester.tap(find.text('How the tools work'));
    await settle(tester);
    expect(await tester.runAsync(() => s.db.getSetting('toolsGuideClosed')), '1');
    await tearDownApp(tester, s);
  });
}
