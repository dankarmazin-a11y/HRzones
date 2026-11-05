import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/beep/sounds.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/hr/zone_alert_engine.dart';
import 'package:hrzones/notify/rest_notifier.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  test('each event plays its chosen sound; classic keeps the old sounds; choices are saved', () async {
    final beeper = SilentBeeper();
    final s = await testServices(beeper: beeper);
    await beeper.alert(ZoneAlert.high);
    await beeper.play(SoundEvent.restOver);
    expect(beeper.calls, ['beep 1200x3', 'ding']);

    await s.setSound(SoundEvent.zoneHigh, SoundChoice.whistle);
    await s.setSound(SoundEvent.restOver, SoundChoice.buzz);
    beeper.calls.clear();
    await beeper.alert(ZoneAlert.high);
    await beeper.play(SoundEvent.restOver);
    expect(beeper.calls, ['sound whistlex3', 'sound buzzx1']);

    beeper.choices.clear(); // forget in memory → read back from the settings
    await s.reloadAfterRestore();
    expect(s.sounds[SoundEvent.zoneHigh], SoundChoice.whistle);
    await s.setSound(SoundEvent.zoneHigh, SoundChoice.classic);
    expect(s.sounds.containsKey(SoundEvent.zoneHigh), isFalse);
    await s.close();
  });

  test('rest over: light vibration (can be turned off) and an optional notification', () async {
    final notifier = SilentRestNotifier();
    final s = await AppServices.open(
      loadExercises: () async => testExercisesJson,
      db: memoryDb(),
      hr: HrMonitor(beeper: SilentBeeper()),
      restNotifier: notifier,
    );
    await s.session.startEmpty();

    // Notifications are off by default.
    s.session.startRest(60);
    expect(notifier.scheduled, isEmpty);
    s.session.stopTimer();

    expect(await s.setRestNotify(true), isTrue);
    s.session.startRest(60);
    expect(notifier.scheduled.single.inSeconds, 60);
    s.session.adjustTimer(30); // moved to the new end
    expect(notifier.scheduled.last.inSeconds, 90);
    final cancelled = notifier.cancelled;
    s.session.stopTimer(); // skipped rest → no notification
    expect(notifier.cancelled, cancelled + 1);

    s.session.startRest(1);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    expect(s.session.restVibrations, 1);
    await s.setRestVibrate(false);
    s.session.startRest(1);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    expect(s.session.restVibrations, 1);
    await s.session.discard();
    await s.close();
  });

  testWidgets('Settings opens from Profile and lists every sound', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    await tester.tap(find.text('Profile').last);
    await settle(tester);
    await tester.tap(find.byKey(const Key('openSettings')));
    await settle(tester);
    expect(find.byKey(const Key('levelPicker')), findsOneWidget);
    expect(find.byKey(const Key('placePicker')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('sound-intervalDone')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const Key('sound-intervalDone')), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    await tearDownApp(tester, s);
  });
}
