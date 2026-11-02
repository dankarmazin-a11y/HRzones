import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/template_repository.dart';
import 'package:hrzones/workout/stats.dart';

import 'test_helpers.dart';

Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  test('stretches are grouped into one Stretching card, one row per stretch', () async {
    final s = await testServices();
    await s.session.startEmpty();
    final ham = (await s.exercises.byId('Hamstring_Stretch'))!;
    final plank = (await s.exercises.byId('Plank'))!; // stretching category in the test data
    await s.session.addExercises([ham, plank]);
    final w = s.session.active!;
    expect(w.exercises.length, 1);
    final card = w.exercises.single;
    expect(card.exercise.isStretchSession, isTrue);
    expect(card.sets.map((x) => x.subExercise!.name), ['Standing Hamstring Stretch', 'Plank']);
    expect(card.sets.every((x) => x.durationS == 30), isTrue);
    expect(card.restSeconds, 10);

    // Adding more stretches right after appends to the same card.
    await s.session.addExercises([ham]);
    expect(w.exercises.length, 1);
    expect(card.sets.length, 3);

    // Hidden from the exercise list.
    expect((await s.exercises.search()).all.any((e) => e.isStretchSession), isFalse);

    // Assisted weight + saved/restored per row.
    s.session.setWeight(card.sets[0], 5);
    await s.session.flush();
    final restored = (await s.workouts.loadActive())!;
    final rows = restored.exercises.single.sets;
    expect(rows.map((x) => x.subExercise?.id), ['Hamstring_Stretch', 'Plank', 'Hamstring_Stretch']);
    expect(rows.first.weightKg, 5);
    await s.session.discard();
    await s.close();
  });

  test('the stretches run one after another', () async {
    final s = await testServices();
    await s.session.startEmpty();
    await s.session.addExercises([(await s.exercises.byId('Hamstring_Stretch'))!, (await s.exercises.byId('Plank'))!]);
    final card = s.session.active!.exercises.single;
    s.session.setRestSeconds(card, 1);
    for (final row in card.sets) {
      s.session.setDuration(row, 1);
    }
    s.session.startSetTimer(card, card.sets[0]);
    expect(s.session.timer!.label, 'Standing Hamstring Stretch');
    expect(s.session.nextUpLabel, 'Plank');
    await wait(1300);
    expect(card.sets[0].done, isTrue);
    expect(s.session.nextUpLabel, 'Plank'); // during the rest
    await wait(1200);
    expect(s.session.timer!.label, 'Plank');
    await wait(1300);
    expect(card.sets[1].done, isTrue);
    expect(s.session.progress, 1.0);
    s.session.stopTimer();

    final summary = (await s.session.finish())!;
    expect(summary.exerciseName('Plank'), 'Plank');
    expect(summary.sets.map((x) => x.exerciseId), ['Hamstring_Stretch', 'Plank']);
    expect(summary.setsPerMuscle.keys, containsAll(['hamstrings', 'abdominals']));
    await s.close();
  });

  test('templates keep a Stretching slot with its stretches', () async {
    final s = await testServices();
    await s.templates.save(
      name: 'Mobility',
      slots: [
        TemplateSlot(exerciseId: 'Barbell_Bench_Press', targetSets: 1),
        TemplateSlot(exerciseId: stretchingSessionId, restSeconds: 10, subExerciseIds: ['Hamstring_Stretch', 'Plank']),
      ],
    );
    final t = (await s.templates.watchAll().first).single;
    expect(t.slots[1].subExerciseIds, ['Hamstring_Stretch', 'Plank']);
    await s.session.startFromTemplate(t);
    final card = s.session.active!.exercises[1];
    expect(card.exercise.isStretchSession, isTrue);
    expect(card.sets.map((x) => x.subExercise!.id), ['Hamstring_Stretch', 'Plank']);
    await s.session.discard();
    await s.close();
  });

  test('stretch records are per stretch', () {
    final r = findRecords(
      current: [const SetStat(exerciseId: 'Plank', type: SetType.normal, durationS: 60)],
      history: [const SetStat(exerciseId: 'Plank', type: SetType.normal, durationS: 45)],
    );
    expect(r.single.kind, RecordKind.longestDuration);
  });
}
