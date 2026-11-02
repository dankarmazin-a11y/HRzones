import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/workout/stats.dart';

SetStat set(double w, int r, {SetType type = SetType.normal, String id = 'bench'}) =>
    SetStat(exerciseId: id, type: type, weightKg: w, reps: r);

void main() {
  test('Epley 1RM', () {
    expect(estimated1RM(100, 1), 100);
    expect(estimated1RM(100, 10), closeTo(133.33, 0.01));
  });

  test('volume ignores warm-ups', () {
    expect(totalVolume([set(40, 10, type: SetType.warmup), set(60, 8), set(60, 8)]), 960);
  });

  test('no records without history', () {
    expect(findRecords(current: [set(100, 5)], history: []), isEmpty);
  });

  test('weight, 1RM and volume records', () {
    final r = findRecords(
      current: [
        set(110, 3),
        set(200, 1, type: SetType.warmup),
      ],
      history: [set(100, 5)],
    );
    final kinds = {for (final x in r) x.kind: x};
    expect(kinds.keys.toSet(), {RecordKind.maxWeight, RecordKind.est1RM});
    expect(kinds[RecordKind.maxWeight]!.value, 110);
    expect(kinds[RecordKind.est1RM]!.value, closeTo(121, 0.01));
  });

  test('bodyweight exercises get rep records', () {
    final r = findRecords(
      current: [const SetStat(exerciseId: 'pullup', type: SetType.normal, reps: 12)],
      history: [const SetStat(exerciseId: 'pullup', type: SetType.normal, reps: 10)],
    );
    expect(r.single.kind, RecordKind.maxReps);
  });

  test('formatting', () {
    expect(formatKg(60), '60');
    expect(formatKg(62.5), '62.5');
    expect(formatKg(61.25), '61.25');
    expect(formatKg(100.0), '100');
    expect(formatKg(0.5), '0.5');
    expect(formatDuration(const Duration(minutes: 75, seconds: 3)), '1:15:03');
  });
}
