import '../data/database.dart';

/// In-memory model of the workout being logged. Saved to the DB after every
/// change, so nothing is lost if the app is closed.
class LoggedSet {
  LoggedSet({String? id, this.type = SetType.normal, this.weightKg, this.reps, this.durationS, this.rpe})
    : id = id ?? newId();

  final String id;
  SetType type;
  double? weightKg;
  int? reps;
  int? durationS;

  /// Metres (distance sets: run, row, sled…).
  double? distanceM;
  double? rpe;
  int? maxHr;
  DateTime? completedAt;

  /// In a "Stretching" session card: which stretch this row is.
  Exercise? subExercise;

  /// Left / right of a one-sided exercise (sets then come in L+R pairs).
  Side? side;

  bool get done => completedAt != null;

  /// A copy with the same values, not done (new id).
  LoggedSet copy({Side? side}) => LoggedSet(type: type, weightKg: weightKg, reps: reps, durationS: durationS)
    ..distanceM = distanceM
    ..subExercise = subExercise
    ..side = side ?? this.side;
}

class LoggedExercise {
  LoggedExercise({String? id, required this.exercise, this.restSeconds = 90, this.supersetGroup, List<LoggedSet>? sets})
    : id = id ?? newId(),
      sets = sets ?? [];

  final String id;
  Exercise exercise;
  int restSeconds;
  int? supersetGroup;

  /// Note for this exercise in this workout.
  String notes = '';
  final List<LoggedSet> sets;

  /// The permanent note is folded away (owner, 2026-11-13: it starts folded
  /// behind a small slanted sticky-note tag next to the name; tap to open).
  bool noteHidden = true;

  /// Sets from the last finished workout with this exercise, by index.
  List<WorkoutSet> previous = const [];

  /// Stretching sessions have different stretches per row, so no
  /// "previous" by position.
  WorkoutSet? previousFor(int index) {
    if (exercise.isStretchSession) return null;
    var i = index;
    // Logged per side now but not last time: 1L and 1R both show set 1.
    if (index < sets.length && sets[index].side != null && previous.every((p) => p.side == null)) i = index ~/ 2;
    // …and the other way round: one set now, pairs last time → its left side.
    if (index < sets.length && sets[index].side == null && previous.any((p) => p.side != null)) i = index * 2;
    return i < previous.length ? previous[i] : null;
  }
}

class ActiveWorkout {
  ActiveWorkout({String? id, required this.name, DateTime? startedAt, this.templateId, List<LoggedExercise>? exercises})
    : id = id ?? newId(),
      startedAt = startedAt ?? DateTime.now(),
      lastChangeAt = startedAt ?? DateTime.now(),
      exercises = exercises ?? [];

  /// Last time anything was logged or changed (for "Still working out?").
  DateTime lastChangeAt;

  final String id;
  String name;
  DateTime startedAt;
  final String? templateId;
  final List<LoggedExercise> exercises;
  String notes = '';

  /// Heart-rate zone preset used in this workout (or template).
  String? hrPresetId;

  Iterable<LoggedSet> get completedSets => exercises.expand((e) => e.sets).where((s) => s.done);
}
