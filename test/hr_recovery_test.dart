import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/hr/simulated_hr_source.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'test_helpers.dart';

/// Owner (2026-11-19): heart-rate ideas 1 (rest by heart rate) and 3
/// (recovery minute after a workout).
void main() {
  test('rest by heart rate: ends early once under the target, waits when still high', () async {
    final s = await testServices();
    final w = s.session;
    w.recoveryRest = true;
    w.recoveryBpm = 120;
    final src = SimulatedHrSource(bpm: 110, interval: const Duration(milliseconds: 20));
    await s.hr.setSource(src);
    await s.hr.start();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(s.hr.bpm, 110);
    await w.startEmpty();

    // 20 s into a 90 s rest at 110 bpm: recovered → rest ends now.
    final rest = RunningTimer(
      kind: TimerKind.rest,
      total: 90,
      startedAt: DateTime.now().subtract(const Duration(seconds: 20)),
    );
    w.recoveryCheck(rest);
    expect(rest.remaining, 0, reason: 'heart rate is down – the rest is over');

    // Not before the 15 s minimum.
    final early = RunningTimer(kind: TimerKind.rest, total: 90, startedAt: DateTime.now());
    w.recoveryCheck(early);
    expect(early.remaining, greaterThan(80));

    // Still 140 bpm at the end of the timer: it waits 5 s at a time, with a label.
    src.bpm = 140;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final over = RunningTimer(
      kind: TimerKind.rest,
      total: 60,
      startedAt: DateTime.now().subtract(const Duration(seconds: 60)),
    );
    w.recoveryCheck(over);
    expect(over.remaining, greaterThan(0));
    expect(over.label, contains('recover'));

    // Switched off: the timer is left alone.
    w.recoveryRest = false;
    final plain = RunningTimer(
      kind: TimerKind.rest,
      total: 60,
      startedAt: DateTime.now().subtract(const Duration(seconds: 60)),
    );
    w.recoveryCheck(plain);
    expect(plain.remaining, 0);
    await w.discard();
    await s.hr.stop();
    await s.close();
  });

  testWidgets('recovery minute: drop measured and saved, monitoring off after when the workout turned it on', (
    tester,
  ) async {
    final m = HrMonitor(beeper: SilentBeeper(), source: SimulatedHrSource(bpm: 160));
    await m.start();
    await tester.pump(const Duration(seconds: 2));
    expect(m.bpm, 160);
    int? saved;
    expect(m.startRecovery(ownerId: 'w1', save: (d) async => saved = d, stopAfter: true), isTrue);
    expect(m.recovery.value!.done, isFalse);
    m.simulated!.bpm = 128;
    await tester.pump(const Duration(seconds: 30));
    expect(m.recovery.value!.secondsLeft, lessThan(31));
    await tester.pump(const Duration(seconds: 31));
    expect(m.recovery.value!.done, isTrue);
    expect(saved, 32);
    expect(hrRecoveryWord(32), 'very good');
    expect(m.running, isFalse, reason: 'it was the workout\'s monitoring');
    // Off, or no signal: nothing starts.
    m.recoveryCheck = false;
    expect(m.startRecovery(ownerId: 'w2', save: (_) async {}), isFalse);
    m.dispose();
  });
}
