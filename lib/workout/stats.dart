import '../data/database.dart';
import '../units/units.dart';

/// Estimated one-rep max (Epley).
double estimated1RM(double weightKg, int reps) => reps <= 1 ? weightKg : weightKg * (1 + reps / 30);

/// A completed set reduced to what stats need.
class SetStat {
  const SetStat({
    required this.exerciseId,
    required this.type,
    this.weightKg,
    this.reps,
    this.durationS,
    this.right = false,
  });

  factory SetStat.fromRow(WorkoutSet s) => SetStat(
    exerciseId: s.subExerciseId ?? s.exerciseId,
    type: s.setType,
    weightKg: s.weightKg,
    reps: s.reps,
    durationS: s.durationS,
    right: s.side == Side.right,
  );

  /// The right side of a one-sided set (the pair counts as one set).
  final bool right;

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

/// A plain number with up to 2 decimals and no trailing zeros: 60, 62.5,
/// 61.25 (also used for RPE and metres – no unit conversion).
String formatKg(double? kg) {
  if (kg == null) return '';
  return kg.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

/// A stored weight (kg) as a number in the chosen unit: "60" / "132.3".
/// Pounds get one decimal (typed whole pounds come back exactly).
String formatW(double? kg) {
  if (kg == null) return '';
  final v = Units.toW(kg);
  return Units.lb ? v.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '') : formatKg(v);
}

/// Big totals (volume lifted): "850", "12.4 t" (tonnes) or "27.3k" pounds.
/// The label is [bigWeightUnit].
String formatBigWeight(double kg, {int decimals = 1}) {
  final v = Units.toW(kg);
  if (v < 10000) return formatW(kg);
  return Units.lb ? '${(v / 1000).toStringAsFixed(decimals)}k' : '${(v / 1000).toStringAsFixed(decimals)} t';
}

/// "lb" for pounds; tonnes already carry " t".
String bigWeightUnit(double kg) => Units.toW(kg) < 10000 ? Units.w : (Units.lb ? 'lb' : '');

/// "60 kg" / "132.3 lb".
String formatWeight(double? kg) => kg == null ? '' : '${formatW(kg)} ${Units.w}';

String formatDuration(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

String formatRecord(RecordKind kind, double v) => switch (kind) {
  RecordKind.maxReps => '${v.round()} reps',
  RecordKind.longestDuration => formatDuration(Duration(seconds: v.round())),
  _ => formatWeight(v),
};

/// What the progress chart of an exercise shows.
enum ProgressMetric { est1RM, maxReps, longestTime }

ProgressMetric metricFor(TrackingType t) => switch (t) {
  TrackingType.weightReps => ProgressMetric.est1RM,
  TrackingType.bodyweightReps => ProgressMetric.maxReps,
  TrackingType.duration || TrackingType.distance => ProgressMetric.longestTime,
};

extension ProgressMetricLabel on ProgressMetric {
  String get label => switch (this) {
    ProgressMetric.est1RM => 'Best est. 1RM (kg)',
    ProgressMetric.maxReps => 'Most reps in a set',
    ProgressMetric.longestTime => 'Longest hold (s)',
  };
}

/// The value of one workout for [metric] (working sets only), or null.
double? sessionValue(ProgressMetric metric, Iterable<SetStat> sets) {
  double? best;
  for (final s in sets.where((s) => s.countsForRecords)) {
    final v = switch (metric) {
      ProgressMetric.est1RM => (s.weightKg ?? 0) > 0 && (s.reps ?? 0) > 0 ? estimated1RM(s.weightKg!, s.reps!) : null,
      ProgressMetric.maxReps => (s.reps ?? 0) > 0 ? s.reps!.toDouble() : null,
      ProgressMetric.longestTime => (s.durationS ?? 0) > 0 ? s.durationS!.toDouble() : null,
    };
    if (v != null && (best == null || v > best)) best = v;
  }
  return best;
}
