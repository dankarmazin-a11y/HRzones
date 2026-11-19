import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/hr/simulated_hr_source.dart';
import 'package:hrzones/hr/zones.dart';
import 'package:hrzones/run/hr_drift.dart';

import 'test_helpers.dart';

/// Owner (2026-11-19): heart-rate ideas 2 (time-in-zone goal) and 7 (drift).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('drift: speed per heartbeat first half vs second half', () {
    final t0 = DateTime(2026, 11, 19, 7);
    // 40 min at a steady 3 m/s, a fix every 2 s heading north; heart rate 140 then 154 (+10 %).
    final points = [
      for (var i = 0; i <= 1200; i++)
        (
          time: t0.add(Duration(seconds: i * 2)),
          lat: 32.0 + i * 6 / 111320,
          lon: 34.8,
          segment: 0,
          hr: i < 600 ? 140 : 158,
        ),
    ];
    final d = hrDriftPercent(points)!;
    expect(d, closeTo(12.9, 1));
    expect(hrDriftWord(d), 'a lot of drift');
    expect(hrDriftWord(3), 'steady');
    // Too short (10 min): nothing.
    expect(hrDriftPercent(points.take(300).toList()), isNull);
  });

  test('live drift watch: said once, only at about the same speed', () {
    final w = DriftWatch();
    double? said;
    for (var s = 0; s <= 1800; s++) {
      final bpm = s < 900 ? 140 : 153; // +9 % in the last 10 minutes
      w.add(s.toDouble(), s * 3.0, bpm);
      said ??= w.check();
    }
    expect(said, inInclusiveRange(8, 9.5));
    expect(w.check(), isNull, reason: 'only once');
    // Faster in the second half: a higher heart rate is expected – no alert.
    final fast = DriftWatch();
    double? f;
    var m = 0.0;
    for (var s = 0; s <= 1800; s++) {
      m += s < 900 ? 3.0 : 3.6;
      fast.add(s.toDouble(), m, s < 900 ? 140 : 155);
      f ??= fast.check();
    }
    expect(f, isNull);
  });

  test('time-in-zone goal counts seconds in the zone and finishes once', () async {
    final s = await testServices(source: SimulatedHrSource(bpm: 130, interval: const Duration(milliseconds: 10)));
    s.hr.setRange(const HrRange(min: 120, max: 140));
    await s.hr.start();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    s.run.zoneGoalMin = 1;
    await s.run.start(treadmill: true);
    for (var i = 0; i < 59; i++) {
      s.run.zoneSecond();
    }
    expect(s.run.zoneSecs, 59);
    expect(s.run.zoneGoalDone, isFalse);
    s.run.zoneSecond();
    expect(s.run.zoneGoalDone, isTrue);
    // Out of the zone: the count stops.
    s.hr.simulated!.bpm = 160;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    final before = s.run.zoneSecs;
    s.run.zoneSecond();
    expect(s.run.zoneSecs, before);
    await s.run.discard();
    await s.hr.stop();
    await s.close();
  });
}
