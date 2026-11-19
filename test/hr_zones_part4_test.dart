import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/run/run_plan.dart';

import 'test_helpers.dart';

/// Owner (2026-11-19): heart-rate ideas 4 (your own max heart rate) and 5
/// (intervals by heart rate).
void main() {
  test('heart-rate intervals: work until 165, recover until 130 (time is only the limit)', () {
    const spec = PlanSpec(
      repeats: 2,
      work: PlanStep(StepKind.work, byDistance: false, value: 600, untilBpm: 165),
      recover: PlanStep(StepKind.recover, byDistance: false, value: 600, untilBpm: 130),
    );
    final back = PlanSpec.fromJson(spec.toJson());
    expect(back.work!.untilBpm, 165);
    expect(back.recover!.untilBpm, 130);
    expect(back.description, contains('up to 165 bpm'));
    final r = PlanRunner(back);
    expect(r.update(10, 5, bpm: 170), isNull, reason: 'a spike in the first 15 s does not count');
    expect(r.update(50, 20, bpm: 150), isNull);
    expect(r.update(90, 40, bpm: 166), PlanEvent.nextStep);
    expect(r.current!.kind, StepKind.recover);
    expect(r.update(120, 70, bpm: 140), isNull);
    expect(r.update(150, 100, bpm: 129), PlanEvent.nextStep);
    // No heart rate: the step ends at its time limit.
    expect(r.update(200, 600, bpm: null), isNull);
    expect(r.update(300, 701, bpm: null), PlanEvent.done);
    expect(r.laps.first.step.untilBpm, 165);
  });

  test('your own max heart rate sets the zones (and stays when the age changes)', () {
    final m = HrMonitor(beeper: SilentBeeper(), age: 40);
    expect(m.zones.maxHr, 180);
    m.setMaxHr(192);
    expect(m.zones.maxHr, 192);
    m.setAge(45);
    expect(m.zones.maxHr, 192);
    m.setMaxHr(null);
    expect(m.zones.maxHr, 175);
  });

  test('highest heart rate ever recorded (workouts and runs)', () async {
    final s = await testServices();
    expect(await s.workouts.highestHr(), isNull);
    await s.session.startEmpty();
    final w = s.session.active!;
    await s.workouts.save(w, endedAt: w.startedAt.add(const Duration(minutes: 30)), avgHr: 140, maxHr: 187);
    expect(await s.workouts.highestHr(), 187);
    await s.close();
  });
}
