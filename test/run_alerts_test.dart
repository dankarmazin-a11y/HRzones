import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/data/run_repository.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/hr/zone_alert_engine.dart';
import 'package:hrzones/hr/zones.dart';
import 'package:hrzones/run/geo.dart';
import 'package:hrzones/run/run_session.dart';
import 'package:hrzones/run/run_voice.dart';
import 'package:hrzones/ui/screens/settings_screen.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'run_test.dart' show FakeLocation, lat0, lon0, t0;
import 'test_helpers.dart';

void main() {
  late SilentBeeper beeper;
  late HrMonitor hr;
  late FakeLocation gps;
  late RunSession run;
  late DateTime clock;

  setUp(() {
    beeper = SilentBeeper();
    hr = HrMonitor(beeper: beeper);
    gps = FakeLocation();
    clock = t0;
    run = RunSession(runs: RunRepository(memoryDb()), hr: hr, location: gps, clock: () => clock)
      ..voice = RunVoice(beeper.speak);
  });

  var pos = 0.0; // metres north of the start

  Future<void> runAt(double mps, int seconds, {int from = 0}) async {
    if (from == 0) pos = 0;
    for (var i = from + 1; i <= from + seconds; i++) {
      clock = t0.add(Duration(seconds: i));
      pos += mps;
      gps.emit(GeoFix(time: clock, lat: lat0 + pos / 111195, lon: lon0, accuracy: 5));
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('too fast for the target pace: beeps and "Slow down" after 10 s', () async {
    run.paceAlert = const HrRange(min: 300, max: 330); // 5:00–5:30
    await run.start();
    gps.emit(GeoFix(time: t0, lat: lat0, lon: lon0, accuracy: 5));
    await runAt(4, 15); // 4:10 /km – but the pace needs ~8 s to settle
    expect(beeper.calls.where((c) => c == 'beep 1500x2'), isEmpty, reason: 'grace period');
    await runAt(4, 20, from: 15);
    expect(beeper.calls.where((c) => c == 'beep 1500x2'), hasLength(1));
    expect(beeper.spoken.last, matches(RegExp(r'^Pace 4 minutes 1[01] per kilometre\. Slow down\.$')));
    await runAt(4, 10, from: 35);
    expect(beeper.calls.where((c) => c == 'beep 1500x2'), hasLength(1), reason: '30 s cooldown');
  });

  test('too slow: "Speed up"; within the range: quiet; no alert without a range', () async {
    run.paceAlert = const HrRange(min: 300, max: 330);
    await run.start();
    gps.emit(GeoFix(time: t0, lat: lat0, lon: lon0, accuracy: 5));
    await runAt(3.2, 40); // 5:12 /km – inside
    expect(beeper.spoken.where((t) => t.startsWith('Pace')), isEmpty);
    await runAt(2.5, 40, from: 40); // 6:40 /km
    expect(beeper.calls, contains('beep 400x1'));
    expect(beeper.spoken.last, endsWith('Speed up.'));
    await run.discard();

    run.paceAlert = null;
    beeper.spoken.clear();
    await run.start();
    await runAt(5, 40);
    expect(beeper.spoken.where((t) => t.startsWith('Pace')), isEmpty);
  });

  test('heart-rate beeps during a run are said out loud (can be switched off)', () async {
    await run.start();
    expect(hr.onAlert, isNotNull);
    hr.onAlert!(ZoneAlert.high, 171);
    expect(beeper.spoken.last, 'Heart rate 171. Slow down.');
    hr.onAlert!(ZoneAlert.low, 118);
    expect(beeper.spoken.last, 'Heart rate 118. Speed up.');
    run.voice!.spokenAlerts = false;
    hr.onAlert!(ZoneAlert.high, 175);
    expect(beeper.spoken.last, 'Heart rate 118. Speed up.');
    await run.finish();
    expect(hr.onAlert, isNull, reason: 'only during runs');
  });

  test('the km update says only the chosen items, in the chosen voice', () {
    final said = <(String, String)>[];
    final v = RunVoice((t, {voice = 'default'}) async => said.add((t, voice)))
      ..items = {VoiceItem.heartRate, VoiceItem.currentPace}
      ..kind = 'female';
    v.started();
    v.progress(1005, const Duration(minutes: 5), bpm: 150, currentPace: 290);
    expect(said.last.$1, '1 kilometre. Current pace 4 minutes 50 per kilometre. Heart rate 150.');
    expect(said.last.$2, 'female');
  });

  testWidgets('Settings › Running: what the voice says, which voice, pace alert', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    final nav = Navigator.of(tester.element(find.byType(NavigationBar)));
    nav.push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    await settle(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('voiceItem_heartRate')), 200);
    await settle(tester);
    await tester.tap(find.byKey(const Key('voiceItem_heartRate')));
    await settle(tester);
    expect(s.run.voice!.items.contains(VoiceItem.heartRate), isFalse);
    await tester.ensureVisible(find.text('Male'));
    await tester.tap(find.text('Male'));
    await settle(tester);
    expect(s.run.voice!.kind, 'male');
    await tester.tap(find.byKey(const Key('testVoice')));
    await settle(tester);
    expect((s.hr.beeper as SilentBeeper).spoken, isNotEmpty);

    await tester.scrollUntilVisible(find.byKey(const Key('paceAlertRow')), 200);
    await settle(tester);
    await tester.tap(find.byKey(const Key('paceAlertRow')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('paceSlow')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('paceInput')), '6:05');
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('savePace')));
    await settle(tester);
    expect(s.run.paceAlert!.min, 330);
    expect(s.run.paceAlert!.max, 365);
    expect(await tester.runAsync(() => s.db.getSetting('runPaceAlert')), '330-365');
    expect(await tester.runAsync(() => s.db.getSetting('runVoiceKind')), 'male');
    await tearDownApp(tester, s);
  });
}
