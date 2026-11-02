import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/exercise_repository.dart';

import 'test_helpers.dart';

void main() {
  late String assetJson;
  setUpAll(() => assetJson = File('assets/exercises.json').readAsStringSync());

  test('real exercise list: clean names, popular first, then A–Z', () async {
    final s = await testServices();
    // Re-seed with the real asset instead of the small test list.
    await s.db.setSetting('exerciseSeedVersion', '0');
    await s.exercises.seedIfNeeded(() async => assetJson);

    final all = await s.exercises.all();
    expect(all.length, greaterThan(850));
    final names = all.map((e) => e.name).toSet();
    for (final n in [
      'Barbell Bench Press',
      'Incline Dumbbell Press',
      'Lat Pulldown',
      'Pull-Up',
      'Barbell Romanian Deadlift',
      'Bulgarian Split Squat',
      'Cable Lateral Raise',
      'Hip Abduction (Machine)',
      'Pigeon Pose',
    ]) {
      expect(names, contains(n));
    }
    expect(names.where((n) => n.contains(' - Medium Grip')), isEmpty);

    // No filter: the big lifts first.
    final top = await s.exercises.search();
    expect(top.popular.map((e) => e.name), [
      'Barbell Bench Press',
      'Barbell Squat',
      'Barbell Deadlift',
      'Pull-Up',
      'Barbell Overhead Press',
    ]);

    // Muscle filter: 5 most popular for that muscle, then the rest A–Z.
    final chest = await s.exercises.search(muscle: 'chest');
    expect(chest.popular.length, 5);
    expect(chest.popular.first.name, 'Barbell Bench Press');
    expect(chest.popular.every((e) => e.primaryMuscle == 'chest'), isTrue);
    final rest = chest.others.map((e) => e.name).toList();
    expect(rest, [...rest]..sort());

    // Stretching type filter.
    final stretches = await s.exercises.search(group: ExerciseGroup.stretching);
    expect(stretches.popular.first.name, 'Standing Hamstring Stretch');
    expect(stretches.all.every((e) => e.isStretch && e.isTimed), isTrue);

    // Holds are timed.
    expect((await s.exercises.byId('Plank'))!.isTimed, isTrue);
    await s.close();
  });

  test('changing the tracking type survives a re-seed', () async {
    final s = await testServices();
    await s.exercises.setTrackingType('Barbell_Bench_Press', TrackingType.duration);
    await s.db.setSetting('exerciseSeedVersion', '0');
    await s.exercises.seedIfNeeded(() async => testExercisesJson);
    expect((await s.exercises.byId('Barbell_Bench_Press'))!.trackingType, TrackingType.duration);
    await s.close();
  });
}
