import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/hr/ble_hr_source.dart';
import 'package:hrzones/hr/heart_rate_source.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/hr/simulated_hr_source.dart';
import 'package:hrzones/workout/calculators.dart';
import 'package:hrzones/workout/stats.dart';

import 'test_helpers.dart';

/// A source we can push readings into.
class FakeSource implements HeartRateSource {
  final controller = StreamController<HrReading>.broadcast();
  bool started = false;
  bool disposed = false;

  @override
  HrSourceKind get kind => HrSourceKind.bluetooth;
  @override
  String get displayName => 'Fake strap';
  @override
  Stream<HrReading> get readings => controller.stream;
  @override
  Future<void> start() async => started = true;
  @override
  Future<void> stop() async => started = false;
  @override
  void dispose() => disposed = true;

  void push(int bpm) => controller.add(HrReading(bpm: bpm, time: DateTime.now(), source: kind));
}

void main() {
  group('Bluetooth heart-rate measurement (0x2A37)', () {
    test('8-bit value', () => expect(parseHeartRateMeasurement([0x00, 72]), 72));
    test('16-bit value', () => expect(parseHeartRateMeasurement([0x01, 0x2C, 0x01]), 300));
    test('extra fields (RR intervals) are ignored', () {
      expect(parseHeartRateMeasurement([0x10, 150, 0x34, 0x12]), 150);
    });
    test('too short', () {
      expect(parseHeartRateMeasurement([0x00]), isNull);
      expect(parseHeartRateMeasurement([0x01, 0x10]), isNull);
    });
  });

  test('switching the heart-rate source while monitoring keeps monitoring', () async {
    final m = HrMonitor(beeper: SilentBeeper());
    HeartRateSource? saved;
    m.onSourceChanged = (s) => saved = s;
    await m.start();
    final old = m.source as SimulatedHrSource;
    final strap = FakeSource();
    await m.setSource(strap);
    expect(m.running, isTrue);
    expect(strap.started, isTrue);
    expect(saved, strap);
    strap.push(142);
    await Future<void>.delayed(Duration.zero);
    expect(m.bpm, 142);
    expect(old.bpm, isNotNull); // old source was disposed, not reused
    await m.stop();
    m.dispose();
  });

  test('plates per side', () {
    expect(platesPerSide(100).perSide, [25, 15]);
    expect(platesPerSide(62.5).perSide, [20, 1.25]);
    expect(platesPerSide(20).perSide, isEmpty);
    final odd = platesPerSide(101);
    expect(odd.perSide, [25, 15]);
    expect(odd.remainder, 1);
    expect(platesPerSide(60, bar: 15).perSide, [20, 2.5]);
  });

  test('1RM table', () {
    final rows = percentTable(100);
    expect(rows.first, (100, 100.0, 1));
    expect(rows[1].$2, 95);
    expect(rows.firstWhere((r) => r.$1 == 75).$3, 10);
  });

  test('progress value per workout', () {
    final sets = [
      const SetStat(exerciseId: 'x', type: SetType.warmup, weightKg: 200, reps: 1),
      const SetStat(exerciseId: 'x', type: SetType.normal, weightKg: 100, reps: 5),
      const SetStat(exerciseId: 'x', type: SetType.normal, weightKg: 90, reps: 10),
    ];
    expect(sessionValue(ProgressMetric.est1RM, sets), closeTo(120, 0.01));
    expect(sessionValue(ProgressMetric.maxReps, sets), 10);
    expect(sessionValue(ProgressMetric.longestTime, sets), isNull);
  });

  test('exercise history and swapping an exercise', () async {
    final s = await testServices();
    final bench = (await s.exercises.byId('Barbell_Bench_Press'))!;
    final pullups = (await s.exercises.byId('Pullups'))!;
    for (final kg in [60.0, 65.0]) {
      await s.session.startEmpty();
      await s.session.addExercises([bench]);
      final e = s.session.active!.exercises.single;
      s.session.setWeight(e.sets.single, kg);
      s.session.setReps(e.sets.single, 5);
      s.session.toggleDone(e, e.sets.single);
      s.session.stopTimer();
      await s.session.finish();
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    final history = await s.workouts.exerciseHistory(bench.id);
    expect(history.length, 2);
    expect(history.first.sets.single.weightKg, 65); // newest first

    // Swap: keeps the sets, "previous" now comes from the new exercise.
    await s.session.startEmpty();
    await s.session.addExercises([bench]);
    final e = s.session.active!.exercises.single;
    expect(e.previous, isNotEmpty);
    await s.session.swapExercise(e, pullups);
    expect(e.exercise.id, pullups.id);
    expect(e.previous, isEmpty);
    expect(e.sets.length, 1);
    await s.session.discard();
    await s.close();
  });
}
