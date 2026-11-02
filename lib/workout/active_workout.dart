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
  double? rpe;
  int? maxHr;
  DateTime? completedAt;

  bool get done => completedAt != null;
}

class LoggedExercise {
  LoggedExercise({String? id, required this.exercise, this.restSeconds = 90, this.supersetGroup, List<LoggedSet>? sets})
    : id = id ?? newId(),
      sets = sets ?? [];

  final String id;
  final Exercise exercise;
  int restSeconds;
  int? supersetGroup;
  String notes = '';
  final List<LoggedSet> sets;

  /// Sets from the last finished workout with this exercise, by index.
  List<WorkoutSet> previous = const [];

  WorkoutSet? previousFor(int index) => index < previous.length ? previous[index] : null;
}

class ActiveWorkout {
  ActiveWorkout({String? id, required this.name, DateTime? startedAt, this.templateId, List<LoggedExercise>? exercises})
    : id = id ?? newId(),
      startedAt = startedAt ?? DateTime.now(),
      exercises = exercises ?? [];

  final String id;
  String name;
  final DateTime startedAt;
  final String? templateId;
  final List<LoggedExercise> exercises;
  String notes = '';

  Iterable<LoggedSet> get completedSets => exercises.expand((e) => e.sets).where((s) => s.done);
}
