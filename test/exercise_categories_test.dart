import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/exercise_repository.dart';

import 'test_helpers.dart';

void main() {
  test('strength moves filed as stretches by free-exercise-db are strength now', () async {
    final json = File('assets/exercises.json').readAsStringSync();
    final repo = ExerciseRepository(memoryDb());
    await repo.seedIfNeeded(() async => json);
    final superman = (await repo.byId('Superman'))!;
    expect(superman.category, 'strength');
    expect(superman.isStretch, isFalse, reason: 'not added to the Stretching card');
    expect(superman.trackingType, TrackingType.duration, reason: 'a hold');
    expect((await repo.byId('Scissor_Kick'))!.trackingType, TrackingType.bodyweightReps);
    expect((await repo.byId('Front_Leg_Raises'))!.category, 'stretching', reason: 'leg swings stay a stretch');
  });

  test('an older install switches the moved exercises from time to reps once', () async {
    final json = File('assets/exercises.json').readAsStringSync();
    final db = memoryDb();
    final repo = ExerciseRepository(db);
    await repo.seedIfNeeded(() async => json);
    // As an install from before seed 7 had it.
    await repo.setTrackingType('Scissor_Kick', TrackingType.duration);
    await db.setSetting('exerciseSeedVersion', '6');
    await repo.seedIfNeeded(() async => json);
    expect((await repo.byId('Scissor_Kick'))!.trackingType, TrackingType.bodyweightReps);
    // The user's own choice afterwards is kept on later re-seeds.
    await repo.setTrackingType('Scissor_Kick', TrackingType.duration);
    await repo.seedIfNeeded(() async => json);
    expect((await repo.byId('Scissor_Kick'))!.trackingType, TrackingType.duration);
  });
}
