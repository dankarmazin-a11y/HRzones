part of 'workout_session.dart';

enum TimerKind { rest, setTimer, countdown, stopwatch }

/// The one timer shown in the bottom bar of a workout.
class RunningTimer {
  RunningTimer({required this.kind, required this.total, this.exercise, this.set, this.switchSides = false})
    : startedAt = DateTime.now();

  /// The short pause between the left and right side of a timed hold.
  final bool switchSides;

  final TimerKind kind;
  final DateTime startedAt;

  /// Length in seconds (0 for a stopwatch).
  int total;
  final LoggedExercise? exercise;
  final LoggedSet? set;

  /// Set timer → rest → next timed set: continue automatically.
  bool chainNext = false;
  final Duration _paused = Duration.zero;

  int get elapsed => (DateTime.now().difference(startedAt) - _paused).inSeconds;

  int get remaining {
    final left = DateTime.now().difference(startedAt) - _paused;
    final ms = total * 1000 - left.inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  bool get countsDown => kind != TimerKind.stopwatch;

  String get label => switch (kind) {
    TimerKind.rest => switchSides ? 'Switch sides' : 'Rest',
    TimerKind.setTimer =>
      '${set?.subExercise?.name ?? exercise?.exercise.name ?? 'Set'}'
          '${set?.side == null ? '' : (set!.side == Side.left ? ' · left' : ' · right')}',
    TimerKind.countdown => 'Timer',
    TimerKind.stopwatch => 'Stopwatch',
  };
}

/// A distance set in a strength workout measured with GPS.
class SetRun {
  SetRun({required this.exercise, required this.set, this.target}) : startedAt = DateTime.now();

  final LoggedExercise exercise;
  final LoggedSet set;

  /// Metres to run (null = until ■).
  final double? target;
  final DateTime startedAt;
  final _tracker = DistanceTracker();

  double get metres => _tracker.distanceM;
  Duration get elapsed => DateTime.now().difference(startedAt);

  void add(GeoFix fix) => _tracker.add(fix);
}
