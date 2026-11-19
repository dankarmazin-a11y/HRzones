import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/ui/workout/workout_summary_screen.dart';
import 'package:hrzones/ui/workout/timer_widgets.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

import 'package:hrzones/workout/stats.dart';

/// Owner's workout notes (2026-11-18/19): end-of-workout records.
void main() {
  PersonalRecord r(String ex, RecordKind k, double v, double was) =>
      PersonalRecord(exerciseId: ex, kind: k, value: v, previous: was);

  test('records: one per exercise (heaviest first), sorted by how much was beaten, at most 5', () {
    final all = [
      r('ohp', RecordKind.est1RM, 50.67, 44.33),
      r('ohp', RecordKind.maxWeight, 40, 35), // +14 %
      r('ohp', RecordKind.setVolume, 320, 280),
      r('face', RecordKind.maxWeight, 18.5, 17.5), // +6 %
      r('bss', RecordKind.maxWeight, 14, 12), // +17 %
      r('lat', RecordKind.maxReps, 12, 10), // +20 %
      r('calf', RecordKind.setVolume, 200, 160), // +25 %
      r('row', RecordKind.maxWeight, 61, 60), // +2 %
    ];
    final top = topRecords(all);
    expect(top, hasLength(5));
    expect(top.map((x) => x.exerciseId), ['calf', 'lat', 'bss', 'ohp', 'face']);
    expect(top.firstWhere((x) => x.exerciseId == 'ohp').kind, RecordKind.maxWeight);
    for (final k in RecordKind.values) {
      expect(k.short.split(' ').length, lessThanOrEqualTo(3), reason: 'max 3 words');
    }
    expect(formatRecordGain(r('ohp', RecordKind.maxWeight, 40, 35)), '+5 kg');
    expect(formatRecordGain(r('lat', RecordKind.maxReps, 12, 10)), '+2');
  });

  testWidgets('summary: 3 × 3 grey stat grid, the best record highlighted, 5 shown, "+n more"', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.runAsync(() async {
      await s.session.startEmpty();
      await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
    });
    final w = s.session.active!;
    final ids = ['a', 'b', 'c', 'd', 'e', 'f', 'g'];
    final summary = WorkoutSummary(
      workout: w,
      endedAt: w.startedAt.add(const Duration(minutes: 50)),
      records: [
        r('Barbell_Bench_Press', RecordKind.maxWeight, 100, 80), // +25 %: the best
        for (final (i, id) in ids.indexed) r(id, RecordKind.maxWeight, 50 + i.toDouble(), 49 + i.toDouble()),
      ],
    );
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => WorkoutSummaryScreen(summary: summary, justFinished: true)));
    await settle(tester);
    final grid = tester.widget<GridView>(find.byKey(const Key('summaryStats')));
    expect((grid.childrenDelegate as SliverChildListDelegate).children, hasLength(9), reason: 'always 3 × 3');
    expect(find.descendant(of: find.byKey(const Key('topRecord')), matching: find.text('100 kg')), findsOneWidget);
    expect(find.byKey(const Key('moreRecords')), findsOneWidget, reason: '8 records → 5 shown + "3 more"');
    expect(find.text('+3 more'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('moreRecords')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('moreRecords')));
    await settle(tester);
    expect(find.byKey(const Key('moreRecords')), findsNothing);
    await tester.runAsync(s.session.discard);
    await tearDownApp(tester, s);
  });

  test('the rest bar floats with big round corners (option B)', () {
    expect(timerBarRadius, greaterThanOrEqualTo(28));
  });
}
