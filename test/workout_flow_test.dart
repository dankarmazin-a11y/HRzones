import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/data/template_repository.dart';
import 'package:hrzones/hr/zones.dart';
import 'package:hrzones/workout/stats.dart';

import 'test_helpers.dart';

void main() {
  test('seeds exercises with tracking types and search filters', () async {
    final s = await testServices();
    final all = await s.exercises.all();
    expect(all.map((e) => e.name), [
      'Barbell Bench Press',
      'Plank',
      'Pullups',
      'Standing Hamstring Stretch',
      'Stretching',
    ]);
    expect((await s.exercises.byId('Pullups'))!.trackingType, TrackingType.bodyweightReps);
    expect((await s.exercises.byId('Plank'))!.trackingType, TrackingType.duration);
    expect((await s.exercises.byId('Barbell_Bench_Press'))!.trackingType, TrackingType.weightReps);

    expect((await s.exercises.search(query: 'bench')).all.single.id, 'Barbell_Bench_Press');
    // Secondary muscles match too, primary first.
    expect((await s.exercises.search(muscle: 'triceps')).all.single.id, 'Barbell_Bench_Press');
    expect((await s.exercises.search(equipment: 'body only')).length, 3); // Stretching container hidden

    // Seeding twice does not duplicate.
    await s.exercises.seedIfNeeded(() async => testExercisesJson);
    expect((await s.exercises.all()).length, 5);
    await s.close();
  });

  test('custom exercise is saved', () async {
    final s = await testServices();
    final e = await s.exercises.createCustom(name: 'Landmine Press', primaryMuscle: 'shoulders');
    expect(e.isCustom, isTrue);
    expect((await s.exercises.search(query: 'landmine')).all.single.id, e.id);
    await s.close();
  });

  test('template → workout → finish → previous values and PRs', () async {
    final s = await testServices();
    final templateId = await s.templates.save(
      name: 'Push A',
      slots: [
        TemplateSlot(exerciseId: 'Barbell_Bench_Press', targetSets: 2, restSeconds: 120),
        TemplateSlot(exerciseId: 'Pullups', targetSets: 1),
      ],
    );
    final templates = await s.templates.watchAll().first;
    expect(templates.single.template.id, templateId);
    expect(templates.single.slots.map((x) => x.targetSets), [2, 1]);

    // Workout 1
    await s.session.startFromTemplate(templates.single);
    var w = s.session.active!;
    expect(w.name, 'Push A');
    expect(w.exercises.map((e) => e.sets.length), [2, 1]);
    final bench = w.exercises[0];
    s.session.setWeight(bench.sets[0], 60);
    s.session.setReps(bench.sets[0], 8);
    s.session.toggleDone(bench, bench.sets[0]);
    expect(s.session.restRemaining, greaterThan(100)); // rest timer started
    s.session.skipRest();
    s.session.setWeight(bench.sets[1], 60);
    s.session.setReps(bench.sets[1], 6);
    s.session.toggleDone(bench, bench.sets[1]);
    s.session.skipRest();
    // Pull-ups set left unfinished → dropped on finish.
    var summary = (await s.session.finish())!;
    expect(s.session.active, isNull);
    expect(summary.setCount, 2);
    expect(summary.volume, 60 * 8 + 60 * 6);
    expect(summary.records, isEmpty); // first time → no PRs
    expect(summary.workout.exercises.length, 1);

    // Workout 2: previous values shown, empty set filled from previous on ✓.
    await s.session.startFromTemplate(templates.single);
    w = s.session.active!;
    final bench2 = w.exercises[0];
    expect(bench2.previous.map((p) => '${p.weightKg}x${p.reps}'), ['60.0x8', '60.0x6']);
    s.session.toggleDone(bench2, bench2.sets[0]); // copies 60 × 8
    s.session.skipRest();
    expect(bench2.sets[0].weightKg, 60);
    expect(bench2.sets[0].reps, 8);
    s.session.setWeight(bench2.sets[1], 65);
    s.session.setReps(bench2.sets[1], 5);
    s.session.toggleDone(bench2, bench2.sets[1]);
    s.session.skipRest();
    summary = (await s.session.finish())!;
    // 65 × 5 (est. 1RM 75.8) beats the heaviest weight but not 60 × 8 (est. 1RM 76).
    final kinds = summary.records.map((r) => r.kind).toSet();
    expect(kinds, {RecordKind.maxWeight});
    final heaviest = summary.records.firstWhere((r) => r.kind == RecordKind.maxWeight);
    expect(heaviest.value, 65);
    expect(heaviest.previous, 60);

    final history = await s.workouts.watchFinished().first;
    expect(history.length, 2);
    await s.close();
  });

  test('unfinished workout is restored after restart', () async {
    final db = memoryDb();
    final s = await testServices();
    await s.session.startEmpty();
    final bench = (await s.exercises.byId('Barbell_Bench_Press'))!;
    await s.session.addExercises([bench]);
    final e = s.session.active!.exercises.single;
    s.session.setWeight(e.sets.single, 80);
    await s.session.flush();

    final restored = await s.workouts.loadActive();
    expect(restored!.exercises.single.exercise.id, bench.id);
    expect(restored.exercises.single.sets.single.weightKg, 80);
    await s.close();
    await db.close();
  });

  test('supersets: rest only after the last exercise of the group', () async {
    final s = await testServices();
    await s.session.startEmpty();
    final ex = await s.exercises.all();
    await s.session.addExercises([ex[0], ex[2]]);
    final w = s.session.active!;
    s.session.toggleSupersetWithNext(w.exercises[0]);
    expect(w.exercises[0].supersetGroup, isNotNull);
    expect(w.exercises[0].supersetGroup, w.exercises[1].supersetGroup);

    s.session.toggleDone(w.exercises[0], w.exercises[0].sets.first);
    expect(s.session.restRemaining, isNull);
    s.session.toggleDone(w.exercises[1], w.exercises[1].sets.first);
    expect(s.session.restRemaining, isNotNull);
    s.session.skipRest();

    s.session.toggleSupersetWithNext(w.exercises[0]);
    expect(w.exercises.map((e) => e.supersetGroup), [null, null]);
    await s.session.discard();
    await s.close();
  });

  test('HR settings are saved and loaded', () async {
    final s = await testServices();
    s.hr.setAge(40);
    s.hr.setRange(const HrRange(min: 130, max: 145));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(await s.db.getSetting('age'), '40');
    expect(await s.db.getSetting('rangeMax'), '145');
    await s.close();
  });
}
