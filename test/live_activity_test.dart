import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/run_repository.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/live/live_activity.dart';
import 'package:hrzones/run/run_plan.dart';
import 'package:hrzones/run/run_session.dart';

import 'run_test.dart' show FakeLocation, north, t0;
import 'test_helpers.dart';

Map<String, Object?> stateOf((String, Map<String, Object?>) call) => call.$2['state']! as Map<String, Object?>;

void main() {
  test('updates are skipped when nothing changed and throttled unless urgent', () async {
    var now = t0;
    final live = NoLiveActivity(clock: () => now);
    await live.update(const LiveCard(title: 'x'));
    expect(live.calls, isEmpty, reason: 'no card yet');
    await live.start('run', 'Run', const LiveCard(title: '0.00 km'));
    await live.update(const LiveCard(title: '0.00 km'));
    await live.update(const LiveCard(title: '0.01 km'));
    expect(live.calls.map((c) => c.$1), ['start'], reason: 'same card / too soon');
    await live.update(const LiveCard(title: '0.01 km', paused: true), now: true);
    now = now.add(const Duration(seconds: 6));
    await live.update(const LiveCard(title: '0.02 km'));
    expect(live.calls.map((c) => c.$1), ['start', 'update', 'update']);
    await live.end(kind: 'strength');
    expect(live.calls, hasLength(3), reason: 'not the strength card');
    await live.end(kind: 'run');
    expect(live.calls.last.$1, 'end');
    expect(live.kind, isNull);
  });

  test('a strength workout shows the current set, rest countdown and progress on the lock screen', () async {
    final s = await testServices();
    final live = s.live as NoLiveActivity;
    await s.session.startEmpty();
    expect(live.calls.first.$1, 'start');
    expect(live.calls.first.$2['kind'], 'strength');

    final bench = (await s.exercises.byId('Barbell_Bench_Press'))!;
    await s.session.addExercises([bench]);
    final e = s.session.active!.exercises.single;
    s.session.setWeight(e.sets.first, 60);
    s.session.setReps(e.sets.first, 8);
    var card = s.session.liveCard;
    expect(card.title, bench.name);
    expect(card.detail, startsWith('Set 1 of ${e.sets.length} · 60 kg × 8'));
    expect(card.clockStart, s.session.active!.startedAt);

    s.session.toggleDone(e, e.sets.first);
    final state = stateOf(live.calls.last);
    expect(state['countdownLabel'], 'Rest');
    expect(state['countdownEnd'], isNotNull);
    expect(state['detail'], contains('1/${e.sets.length} sets done'));

    s.session.stopTimer();
    expect(stateOf(live.calls.last)['countdownEnd'], isNull);

    await s.session.discard();
    expect(live.calls.last.$1, 'end');
    await s.close();
  });

  group('run card', () {
    late DateTime clock;
    late FakeLocation gps;
    late RunSession run;
    late NoLiveActivity live;

    setUp(() {
      clock = t0;
      gps = FakeLocation();
      live = NoLiveActivity(clock: () => clock);
      run = RunSession(
        runs: RunRepository(memoryDb()),
        hr: HrMonitor(beeper: SilentBeeper()),
        location: gps,
        clock: () => clock,
      )..live = live;
    });

    test('distance, pace, pause and finish', () async {
      await run.start();
      expect(live.calls.single.$1, 'start');
      expect(live.calls.single.$2['name'], 'Run');
      gps.emit(north(0, 0));
      for (var i = 1; i <= 100; i++) {
        clock = t0.add(Duration(seconds: i));
        gps.emit(north(i * 3.0, i));
      }
      await Future<void>.delayed(Duration.zero);
      final card = run.liveCard;
      expect(card.title, '0.30 km');
      expect(card.detail, 'Pace 5:33 /km · avg 5:33 /km');
      expect(card.clockStart, t0);

      clock = t0.add(const Duration(seconds: 100));
      await run.pause();
      final paused = stateOf(live.calls.last);
      expect(paused['paused'], isTrue);
      expect(paused['clockStart'], isNull, reason: 'the clock stops while paused');
      expect(paused['elapsed'], 100);

      clock = t0.add(const Duration(seconds: 160));
      await run.resume();
      final resumed = stateOf(live.calls.last);
      expect(resumed['paused'], isFalse);
      // 60 s paused: the card's clock starts 60 s later, so it still shows 1:40.
      expect(resumed['clockStart'], t0.add(const Duration(seconds: 60)).millisecondsSinceEpoch);

      await run.finish();
      expect(live.calls.last.$1, 'end');
    });

    test('a planned run shows the step and counts down time steps', () async {
      const spec = PlanSpec(
        warmup: PlanStep(StepKind.warmup, byDistance: false, value: 300),
        repeats: 2,
        work: PlanStep(StepKind.work, byDistance: true, value: 400),
        recover: PlanStep(StepKind.recover, byDistance: false, value: 60),
      );
      await run.start(
        plan: RunPlan(id: 'p', name: '2 × 400 m', specJson: spec.toJson(), position: 0, updatedAt: t0),
      );
      expect(live.calls.single.$2['name'], '2 × 400 m');
      var card = run.liveCard;
      expect(card.detail, startsWith('Warm-up 5 min'));
      expect(card.countdownEnd, t0.add(const Duration(seconds: 300)));
      expect(card.countdownLabel, 'Warm-up');

      clock = t0.add(const Duration(seconds: 120));
      card = run.liveCard;
      expect(card.detail, 'Warm-up 5 min · 03:00 left');
      await run.discard();
      expect(live.calls.last.$1, 'end');
    });
  });
}
