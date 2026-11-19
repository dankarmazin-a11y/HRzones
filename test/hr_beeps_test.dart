import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/hr/zone_alert_engine.dart';
import 'package:hrzones/hr/zones.dart';

import 'test_helpers.dart';

/// Owner (2026-11-19): heart-rate zone ideas – beep only on one side, faster
/// beeps far out, a chime when back in.
void main() {
  final t0 = DateTime(2026, 11, 19, 10);
  DateTime at(int s) => t0.add(Duration(seconds: s));

  test('"too high" only: below the zone stays quiet, above still beeps', () {
    final e = ZoneAlertEngine(range: const HrRange(min: 120, max: 140))..beepWhen = BeepWhen.high;
    for (var s = 0; s <= 20; s++) {
      expect(e.onReading(100, at(s)), isNull, reason: 'warm-up below the zone');
    }
    ZoneAlert? got;
    for (var s = 21; s <= 40 && got == null; s++) {
      got = e.onReading(150, at(s));
    }
    expect(got, ZoneAlert.high);
    final low = ZoneAlertEngine(range: const HrRange(min: 120, max: 140))..beepWhen = BeepWhen.low;
    ZoneAlert? g2;
    for (var s = 0; s <= 20; s++) {
      g2 ??= low.onReading(160, at(s));
    }
    expect(g2, isNull);
  });

  test('far outside the zone the beeps repeat twice as often', () {
    List<int> alertTimes(bool faster, int bpm) {
      final e = ZoneAlertEngine(range: const HrRange(min: 120, max: 140))..fasterWhenFar = faster;
      expect(HrMonitor(beeper: SilentBeeper()).engine.fasterWhenFar, isTrue, reason: 'on for heart rate');
      return [
        for (var s = 0; s <= 60; s++)
          if (e.onReading(bpm, at(s)) != null) s,
      ];
    }

    expect(alertTimes(true, 160).length, greaterThan(alertTimes(true, 145).length), reason: '20 above vs 5 above');
    expect(alertTimes(false, 160).length, alertTimes(false, 145).length);
  });

  test('back in the zone after a beep → chime once; no chime without a beep', () {
    final e = ZoneAlertEngine(range: const HrRange(min: 120, max: 140));
    for (var s = 0; s <= 10; s++) {
      e.onReading(150, at(s));
    }
    e.onReading(130, at(11));
    expect(e.justBack, isTrue);
    e.onReading(131, at(12));
    expect(e.justBack, isFalse);
    // A short trip out with no beep (shorter than the 5 s grace): no chime.
    e.onReading(150, at(20));
    e.onReading(130, at(22));
    expect(e.justBack, isFalse);
  });

  test('the monitor plays the back-in-zone chime (switchable)', () async {
    final b = SilentBeeper();
    final m = HrMonitor(beeper: b);
    m.setRange(const HrRange(min: 120, max: 140));
    m.engine.onReading(150, at(0));
    m.engine.onReading(150, at(6));
    expect(m.engine.onReading(130, at(7)), isNull);
    expect(m.engine.justBack, isTrue);
    m.setBackChime(false);
    expect(m.backChime, isFalse);
  });

  test('a zone preset keeps its "beep when" choice', () async {
    final s = await testServices();
    final id = await s.presets.save(
      name: 'Easy',
      min: 120,
      max: 140,
      use: PresetUse.any,
      beepWhen: BeepWhen.high.index,
    );
    expect((await s.presets.byId(id))!.beepWhen, BeepWhen.high.index);
    await s.session.startEmpty();
    await s.session.applyPreset(await s.presets.byId(id));
    expect(s.hr.beepWhen, BeepWhen.high);
    await s.session.discard();
    await s.close();
  });
}
