import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/hr/zone_alert_engine.dart';
import 'package:hrzones/hr/zones.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 8);
  DateTime at(int s) => t0.add(Duration(seconds: s));

  late ZoneAlertEngine e;
  setUp(() => e = ZoneAlertEngine(range: const HrRange(min: 120, max: 140)));

  /// Feeds [bpm] once per second from [from] to [to] (inclusive) and returns
  /// the seconds at which alerts fired.
  Map<int, ZoneAlert> feed(int bpm, int from, int to) {
    final out = <int, ZoneAlert>{};
    for (var s = from; s <= to; s++) {
      final a = e.onReading(bpm, at(s));
      if (a != null) out[s] = a;
    }
    return out;
  }

  test('starts with no signal, in range produces no alerts', () {
    expect(e.status, RangeStatus.noSignal);
    expect(feed(130, 0, 60), isEmpty);
    expect(e.status, RangeStatus.inRange);
  });

  test('high alert only after 5 s grace, then every 10 s cooldown', () {
    feed(130, 0, 9);
    final alerts = feed(150, 10, 40);
    expect(alerts, {15: ZoneAlert.high, 25: ZoneAlert.high, 35: ZoneAlert.high});
    expect(e.status, RangeStatus.above);
  });

  test('low alert below range', () {
    final alerts = feed(100, 0, 6);
    expect(alerts, {5: ZoneAlert.low});
  });

  test('short excursion shorter than grace does not alert', () {
    feed(130, 0, 4);
    expect(feed(150, 5, 8), isEmpty);
    expect(feed(130, 9, 30), isEmpty);
  });

  test('hysteresis: must drop 2 bpm inside the range to count as back in', () {
    feed(150, 0, 0);
    e.onReading(140, at(1)); // at the edge → still above
    expect(e.status, RangeStatus.above);
    e.onReading(139, at(2)); // 1 bpm inside → still above
    expect(e.status, RangeStatus.above);
    e.onReading(138, at(3)); // 2 bpm inside → back in
    expect(e.status, RangeStatus.inRange);
  });

  test('hysteresis on the low side', () {
    feed(110, 0, 0);
    e.onReading(121, at(1));
    expect(e.status, RangeStatus.below);
    e.onReading(122, at(2));
    expect(e.status, RangeStatus.inRange);
  });

  test('returning to range resets grace', () {
    feed(150, 0, 3);
    feed(130, 4, 5);
    expect(feed(150, 6, 10), isEmpty); // only 4 s out again
    expect(feed(150, 11, 11), {11: ZoneAlert.high});
  });

  test('cooldown applies across a high→low switch', () {
    expect(feed(150, 0, 5), {5: ZoneAlert.high});
    final alerts = feed(100, 6, 20);
    // 5 s grace from 6 → 11 is allowed by grace, but cooldown blocks until 15.
    expect(alerts.keys.first, 15);
    expect(alerts[15], ZoneAlert.low);
  });

  test('no signal after 15 s without readings pauses alerts', () {
    feed(150, 0, 5);
    e.tick(at(19));
    expect(e.status, RangeStatus.above);
    e.tick(at(20));
    expect(e.status, RangeStatus.noSignal);
    // Signal returns: grace starts over.
    expect(feed(150, 21, 25), isEmpty);
    expect(feed(150, 26, 26), {26: ZoneAlert.high});
  });

  test('custom cooldown is respected', () {
    e.settings = e.settings.copyWith(cooldown: const Duration(seconds: 30));
    expect(feed(150, 0, 40), {5: ZoneAlert.high, 35: ZoneAlert.high});
  });
}
