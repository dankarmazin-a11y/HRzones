import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/ui/onboarding/onboarding_screen.dart';
import 'package:hrzones/workout/training_level.dart';
import 'package:hrzones/workout/training_place.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  testWidgets('first launch: the walk-through sets level, place, age, weekly target, weight and a goal', (
    tester,
  ) async {
    final s = (await tester.runAsync(testServices))!;
    s.needsOnboarding.value = true;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Welcome to HR Zones'), findsOneWidget);

    Future<void> next() async {
      await tester.tap(find.byKey(const Key('onboardingNext')));
      await settle(tester);
    }

    Future<void> choose(String key) async {
      await tester.tap(find.byKey(Key(key)));
      await settle(tester);
    }

    await next();
    await choose('choice__Focus.both');
    await next();
    await choose('choice_TrainingLevel.beginner');
    await next();
    await choose('choice_TrainingPlace.home');
    await next();
    // Age: type 35.
    await choose('ageValue');
    await tester.enterText(find.byType(TextField).last, '35');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.textContaining('Max heart rate about 185'), findsOneWidget);
    await next();
    await choose('weekly_4');
    await next();
    await choose('enterWeight');
    await tester.enterText(find.byType(TextField).last, '82');
    await tester.tap(find.text('OK'));
    await settle(tester);
    await choose('enterGoalWeight');
    await tester.enterText(find.byType(TextField).last, '78');
    await tester.tap(find.text('OK'));
    await settle(tester);
    await next();
    expect(find.text('You\'re all set'), findsOneWidget);
    expect(find.textContaining('Beginner · Home · 4× a week · age 35'), findsOneWidget);
    await next(); // Start training
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle(tester);

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(s.level.value, TrainingLevel.beginner);
    expect(s.place.value, TrainingPlace.home);
    expect(s.hr.age, 35);
    expect(s.weeklyTarget.value, 4);
    expect(await tester.runAsync(() => s.body.latest('weight')), 82);
    expect(await tester.runAsync(() => s.db.getSetting('onboarded')), '1');
    expect(await tester.runAsync(() => s.db.getSetting('focus')), 'both');
    expect(find.byKey(const Key('closestGoal')), findsOneWidget, reason: 'the goal weight is on Home');
    await tearDownApp(tester, s);
  });

  testWidgets('Skip keeps the defaults and opens the app', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    s.needsOnboarding.value = true;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.byKey(const Key('skipOnboarding')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(s.level.value, TrainingLevel.intermediate);
    expect(await tester.runAsync(() => s.db.getSetting('onboarded')), '1');
    await tearDownApp(tester, s);
  });
}
