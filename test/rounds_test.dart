import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'test_helpers.dart';

void main() {
  test('a stretch list runs N rounds; done rows are kept; the template remembers', () async {
    final s = await testServices();
    await s.exercises.setUnilateral('Hamstring_Stretch', false);
    await s.session.startEmpty();
    final ham = (await s.exercises.byId('Hamstring_Stretch'))!;
    final plank = (await s.exercises.byId('Plank'))!; // stretching category in the test data
    await s.session.addExercises([ham, plank]);
    final card = s.session.active!.exercises.single;
    expect(WorkoutSession.stretchRounds(card), 1);
    s.session.setDuration(card.sets[0], 40);
    card.sets[0].completedAt = DateTime.now();

    s.session.setStretchRounds(card, 3);
    expect(card.sets.map((x) => x.subExercise!.id), [
      'Hamstring_Stretch', 'Plank', 'Hamstring_Stretch', 'Plank', 'Hamstring_Stretch', 'Plank', //
    ]);
    expect(WorkoutSession.stretchRounds(card), 3);
    expect(card.sets[0].done, isTrue, reason: 'existing rows kept');
    expect(card.sets[2].done, isFalse);
    expect(card.sets[2].durationS, 40, reason: 'new rounds copy round 1');

    s.session.setStretchRounds(card, 2);
    expect(card.sets, hasLength(4));

    // Saved as a template and started again: still 2 rounds.
    final id = await s.templates.save(name: 'Stretch', slots: WorkoutSession.slotsFrom(s.session.active!));
    await s.session.discard();
    await s.session.startFromTemplate((await s.templates.byId(id))!);
    expect(WorkoutSession.stretchRounds(s.session.active!.exercises.single), 2);
    await s.session.discard();
  });

  test('a timed hold runs N times; sets already done are not removed', () async {
    final s = await testServices();
    await s.session.startEmpty();
    // A hold that isn't a stretch (logged by time).
    await s.exercises.setTrackingType('Barbell_Bench_Press', TrackingType.duration);
    await s.session.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]);
    final e = s.session.active!.exercises.single;
    s.session.setSetCount(e, 5);
    expect(WorkoutSession.setCount(e), 5);
    e.sets[0].completedAt = DateTime.now();
    s.session.setSetCount(e, 1);
    expect(WorkoutSession.setCount(e), 1);
    expect(e.sets.single.done, isTrue);
    await s.session.discard();
  });
}
