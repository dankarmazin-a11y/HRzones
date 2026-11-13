import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/data/exercise_repository.dart' show SettingsAccess;
import 'package:hrzones/feedback/problem_log.dart';
import 'package:hrzones/feedback/rating.dart';
import 'package:hrzones/ui/feedback/report_problem.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  tearDown(ProblemLog.instance.reset);

  group('rating schedule', () {
    final first = DateTime(2026, 11, 1);
    test('not in the first week', () {
      expect(RatingSchedule.due(now: DateTime(2026, 11, 7), firstOpen: first), isFalse);
      expect(RatingSchedule.due(now: DateTime(2026, 11, 8), firstOpen: first), isTrue);
    });
    test('then once a month after the last question', () {
      final asked = DateTime(2026, 11, 8);
      expect(RatingSchedule.due(now: DateTime(2026, 12, 7), firstOpen: first, lastAsked: asked), isFalse);
      expect(RatingSchedule.due(now: DateTime(2026, 12, 8), firstOpen: first, lastAsked: asked), isTrue);
    });
    test('ratings are saved; "Not now" waits a month too', () async {
      final s = await testServices();
      await s.db.setSetting('firstOpenAt', DateTime(2026, 1, 1).toIso8601String());
      expect(await s.ratingDue(now: DateTime(2026, 2, 1)), isTrue);
      await s.answerRating(null, now: DateTime(2026, 2, 1));
      expect(await s.ratingDue(now: DateTime(2026, 2, 15)), isFalse);
      await s.answerRating(4, now: DateTime(2026, 3, 3));
      expect((await s.ratings()).single.stars, 4);
      await s.close();
    });
  });

  group('problem log', () {
    test('keeps the last 30, counts a repeating error once a minute, and is saved', () async {
      String? saved;
      final log = ProblemLog.instance..attach(saved: null, save: (j) async => saved = j);
      for (var i = 0; i < 40; i++) {
        log.record(StateError('boom $i'), StackTrace.current);
      }
      log.record(StateError('boom 39'));
      expect(log.entries, hasLength(ProblemLog.maxEntries));
      expect(log.entries.first.message, contains('boom 39'), reason: 'newest first');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(saved, contains('boom 39'));

      // Opened again: the saved errors come back.
      log.reset();
      log.attach(saved: saved, save: (j) async {});
      expect(log.entries, hasLength(ProblemLog.maxEntries));
    });

    test('errors from before the database opened are kept', () async {
      final log = ProblemLog.instance..record(Exception('early'));
      log.attach(saved: '[]', save: (j) async {});
      expect(log.entries.single.message, contains('early'));
    });
  });

  test('a report holds the text, the area and the noticed errors, but only with details on', () {
    final errors = [ProblemEntry(at: DateTime(2026, 11, 13, 9), message: 'Bad state: x', where: '#0 main')];
    final full = buildReport(text: 'Beeps stopped', area: ReportArea.heartRate, details: true, errors: errors);
    expect(full, contains('About: Heart rate'));
    expect(full, contains('Beeps stopped'));
    expect(full, contains('Bad state: x'));
    expect(full, contains('Version: '));
    final plain = buildReport(text: 'Beeps stopped', details: false, errors: errors);
    expect(plain, isNot(contains('Bad state')));
  });

  testWidgets('Settings › Help › Report a problem', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    ProblemLog.instance.record(StateError('saving failed'));
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.text('Profile').last);
    await settle(tester);
    await tester.tap(find.byKey(const Key('openSettings')));
    await settle(tester);
    expect(find.textContaining('the app noticed 1 problem'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reportProblem')));
    await settle(tester);
    final send = find.byKey(const Key('sendReport'));
    expect(tester.widget<FilledButton>(send).onPressed, isNull, reason: 'nothing written yet');
    await tester.tap(find.byKey(const Key('area_run')));
    await tester.enterText(find.byKey(const Key('reportText')), 'GPS lost in the park');
    await settle(tester);
    expect(tester.widget<FilledButton>(send).onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('showErrors')));
    await settle(tester);
    expect(find.textContaining('saving failed'), findsOneWidget);
    await tearDownApp(tester, s);
  });

  testWidgets('a week after the first open the app asks for stars; 1–3 stars offers Report a problem', (tester) async {
    final s = (await tester.runAsync(() async {
      final s = await testServices();
      await s.db.setSetting('firstOpenAt', DateTime.now().subtract(const Duration(days: 8)).toIso8601String());
      return s;
    }))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle(tester);
    expect(find.byKey(const Key('rateDialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('star_2')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('rateSubmit')));
    await settle(tester);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle(tester);
    await tester.tap(find.byKey(const Key('rateTellUs')));
    await settle(tester);
    expect(find.byType(ReportProblemScreen), findsOneWidget);
    expect(find.text('I gave 2/5 because '), findsOneWidget);
    expect((await tester.runAsync(s.ratings))!.single.stars, 2);
    expect((await tester.runAsync(() => s.ratingDue()))!, isFalse, reason: 'next time in a month');
    await tearDownApp(tester, s);
  });

  testWidgets('no star question during the first week', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle(tester);
    expect(find.byKey(const Key('rateDialog')), findsNothing);
    await tearDownApp(tester, s);
  });
}
