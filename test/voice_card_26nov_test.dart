import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/live/live_activity.dart';
import 'package:hrzones/run/run_session.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'run_test.dart' show FakeLocation;
import 'test_helpers.dart';

/// Owner (2026-11-26): the voice lowered, stopped or raised the music; no
/// lock-screen card on cardio.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the voice plays over the music unless "Lower music while speaking" is on', () async {
    final sent = <Map<Object?, Object?>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('hrzones/beeper'),
      (call) async {
        if (call.method == 'speak') sent.add(call.arguments as Map<Object?, Object?>);
        return null;
      },
    );
    final b = NativeBeeper();
    expect(b.duckMusic, isFalse);
    await b.speak('1 kilometre');
    b.duckMusic = true;
    await b.speak('2 kilometres');
    expect(sent.map((m) => m['duck']), [false, true]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('hrzones/beeper'),
      null,
    );

    final s = await testServices();
    expect(s.hr.beeper.duckMusic, isFalse);
    await s.setVoiceDuck(true);
    expect(await s.db.getSetting('voiceDuck'), '1');
    await s.close();
  });

  test('the card name matches between the countdown and the run', () {
    expect(RunSession.cardName(), 'Run');
    expect(RunSession.cardName(activity: RunActivity.walk), 'Walk');
    expect(RunSession.cardName(treadmill: true), 'Treadmill run');
    expect(RunSession.cardName(treadmill: true, activity: RunActivity.ride), 'Indoor ride');
    expect(RunSession.cardName(plan: '6 × 400 m', activity: RunActivity.walk), '6 × 400 m');
  });

  testWidgets('the cardio card goes up at the countdown (app on screen) and away if cancelled', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    s.run.location = FakeLocation();
    final live = s.live as NoLiveActivity;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);

    await tapStartTile(tester, 'startRunHome');
    await settle(tester);
    await tester.tap(find.byKey(const Key('goRun')));
    await tester.pump();
    await tester.pump();
    expect(s.run.active, isFalse);
    final first = live.calls.lastWhere((c) => c.$1 == 'start');
    expect(first.$2['kind'], 'run');
    expect(first.$2['name'], 'Run');
    expect((first.$2['state'] as Map)['title'], 'Get ready');

    await tester.tap(find.byKey(const Key('cancelCountdown')));
    await settle(tester);
    expect(live.calls.last.$1, 'end', reason: 'cancelled: no card left behind');
    expect(live.kind, isNull);

    await tapStartTile(tester, 'startRunHome');
    await settle(tester);
    await tester.tap(find.byKey(const Key('goRun')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byKey(const Key('startNow')));
    await settle(tester);
    expect(s.run.active, isTrue);
    final starts = live.calls.where((c) => c.$1 == 'start').toList();
    // The run starts the card with the same name, so iOS only updates the countdown's card.
    expect(starts.last.$2['name'], starts[starts.length - 2].$2['name']);
    expect(live.kind, 'run');
    await tester.pump(const Duration(seconds: 4));
    await tester.runAsync(s.run.discard);
    await tearDownApp(tester, s);
  });
}
