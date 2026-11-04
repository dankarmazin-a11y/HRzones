import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'test_helpers.dart';

void main() {
  test('audio only stops when the last feature releases it', () async {
    final b = SilentBeeper();
    await b.start('hr');
    await b.start('workout');
    await b.stop('hr');
    expect(b.calls.where((c) => c == 'stop'), isEmpty);
    await b.stop('hr'); // releasing twice does nothing
    expect(b.calls.where((c) => c == 'stop'), isEmpty);
    await b.stop('workout');
    expect(b.calls.where((c) => c == 'stop').length, 1);
    expect(b.holds, isEmpty);
  });

  test('a workout timer keeps the audio alive while it runs (not the whole workout)', () async {
    final beeper = SilentBeeper();
    final s = await testServices(beeper: beeper);
    await s.session.startEmpty();
    expect(beeper.holds, isEmpty); // no silent engine while just logging (battery)

    s.session.startRest(1);
    expect(beeper.holds, {'workout'});
    // Turning HR alerts on and off doesn't stop the running timer's audio.
    await s.hr.start();
    await s.hr.stop();
    expect(beeper.holds, {'workout'});
    expect(beeper.calls, isNot(contains('stop')));

    await Future<void>.delayed(const Duration(milliseconds: 1400)); // rest over
    expect(s.session.timer, isNull);
    expect(beeper.holds, isEmpty);
    expect(beeper.calls, contains('ding'));
    expect(beeper.calls, contains('stop')); // stops 3 s later on the phone, after the ding
    await s.session.discard();
    await s.close();
  });

  test('reopening the app mid-workout turns the HR alerts of its preset back on', () async {
    final s = await testServices();
    final presetId = await s.presets.save(name: 'Z2', min: 120, max: 140, use: PresetUse.any);
    await s.session.startEmpty(preset: await s.presets.byId(presetId));
    await s.session.flush();

    // Same database, fresh app (monitor not running).
    final beeper = SilentBeeper();
    final hr = HrMonitor(beeper: beeper);
    final again = WorkoutSession(workouts: s.workouts, exercises: s.exercises, hr: hr)..presets = s.presets;
    await again.restore();
    expect(again.active, isNotNull);
    expect(hr.running, isTrue);
    expect(hr.range.min, 120);
    expect(hr.range.max, 140);
    expect(beeper.holds, contains('hr'));
    await hr.stop();
    again.dispose();
    hr.dispose();
    await s.session.discard();
    await s.close();
  });

  test('tapping Finish twice saves the workout once', () async {
    final s = await testServices();
    await s.session.startEmpty();
    final bench = (await s.exercises.byId('Barbell_Bench_Press'))!;
    await s.session.addExercises([bench]);
    final e = s.session.active!.exercises.single;
    s.session.setReps(e.sets.single, 5);
    s.session.toggleDone(e, e.sets.single);
    final results = await Future.wait([s.session.finish(), s.session.finish()]);
    expect(results.whereType<Object>().length, 1);
    expect(s.session.active, isNull);
    await s.close();
  });
}
