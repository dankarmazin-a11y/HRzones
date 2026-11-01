import '../data/database.dart';

/// Estimated one-rep max (Epley).
double estimated1RM(double weightKg, int reps) => reps <= 1 ? weightKg : weightKg * (1 + reps / 30);

/// A completed set reduced to what stats need.
class SetStat {
  const SetStat({required this.exerciseId, required this.type, this.weightKg, this.reps, this.durationS});

  factory SetStat.fromRow(WorkoutSet s) =>
      SetStat(exerciseId: s.exerciseId, type: s.setType, weightKg: s.weightKg, reps: s.reps, durationS: s.durationS);

  final String exerciseId;
  final SetType type;
  final double? weightKg;
  final int? reps;
  final int? durationS;

  bool get countsForRecords => type != SetType.warmup;
  double get volume => (weightKg ?? 0) * (reps ?? 0);
}

/// Total volume (kg × reps) of working sets.
double totalVolume(Iterable<SetStat> sets) =>
    sets.where((s) => s.countsForRecords).fold(0.0, (sum, s) => sum + s.volume);

enum RecordKind { maxWeight, est1RM, setVolume, maxReps, longestDuration }

extension RecordKindLabel on RecordKind {
  String get label => switch (this) {
    RecordKind.maxWeight => 'Heaviest weight',
    RecordKind.est1RM => 'Best est. 1RM',
    RecordKind.setVolume => 'Best set volume',
    RecordKind.maxReps => 'Most reps',
    RecordKind.longestDuration => 'Longest time',
  };
}

/// Best values for one exercise.
class ExerciseBests {
  final values = <RecordKind, double>{};

  void add(SetStat s) {
    if (!s.countsForRecords) return;
    final w = s.weightKg ?? 0, r = s.reps ?? 0;
    if (w > 0 && r > 0) {
      _max(RecordKind.maxWeight, w);
      _max(RecordKind.est1RM, estimated1RM(w, r));
      _max(RecordKind.setVolume, w * r);
    }
    if (r > 0) _max(RecordKind.maxReps, r.toDouble());
    if ((s.durationS ?? 0) > 0) _max(RecordKind.longestDuration, s.durationS!.toDouble());
  }

  void _max(RecordKind k, double v) {
    final cur = values[k];
    if (cur == null || v > cur) values[k] = v;
  }

  static Map<String, ExerciseBests> fromSets(Iterable<SetStat> sets) {
    final out = <String, ExerciseBests>{};
    for (final s in sets) {
      out.putIfAbsent(s.exerciseId, ExerciseBests.new).add(s);
    }
    return out;
  }
}

class PersonalRecord {
  const PersonalRecord({required this.exerciseId, required this.kind, required this.value, required this.previous});

  final String exerciseId;
  final RecordKind kind;
  final double value;
  final double previous;
}

/// New records in [current] compared to all earlier sets in [history].
/// Only exercises with earlier history can set a record (no PR flood on the
/// first workout). Weight-based records hide "most reps" for weighted lifts.
List<PersonalRecord> findRecords({required Iterable<SetStat> current, required Iterable<SetStat> history}) {
  final before = ExerciseBests.fromSets(history);
  final now = ExerciseBests.fromSets(current);
  final out = <PersonalRecord>[];
  for (final MapEntry(key: exerciseId, value: bests) in now.entries) {
    final prev = before[exerciseId];
    if (prev == null) continue;
    final weighted = bests.values.containsKey(RecordKind.maxWeight);
    for (final MapEntry(key: kind, value: value) in bests.values.entries) {
      if (weighted && kind == RecordKind.maxReps) continue;
      final p = prev.values[kind];
      if (p != null && value > p + 1e-9) {
        out.add(PersonalRecord(exerciseId: exerciseId, kind: kind, value: value, previous: p));
      }
    }
  }
  return out;
}

String formatKg(double? kg) {
  if (kg == null) return '';
  return kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
}

String formatDuration(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

String formatRecord(RecordKind kind, double v) => switch (kind) {
  RecordKind.maxReps => '${v.round()} reps',
  RecordKind.longestDuration => formatDuration(Duration(seconds: v.round())),
  _ => '${formatKg(v)} kg',
};
