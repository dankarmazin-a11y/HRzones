part of 'workout_session.dart';

/// The lock-screen / Dynamic Island card of a live workout.
extension WorkoutSessionLiveCard on WorkoutSession {
  /// What the lock-screen card shows right now.
  /// The set being timed, or the first set not done yet.
  (LoggedExercise, LoggedSet)? get currentSet {
    final w = _active;
    if (w == null) return null;
    final t = _timer;
    if (t?.kind == TimerKind.setTimer && t?.exercise != null && t?.set != null) return (t!.exercise!, t.set!);
    return [
      for (final e in w.exercises)
        for (final s in e.sets)
          if (!s.done && !e.exercise.isInterval) (e, s),
    ].firstOrNull;
  }

  /// Buttons on the lock-screen card: skip the rest, start a timed set, or
  /// tick the current set.
  List<String> get cardActions {
    final t = _timer;
    if (t?.kind == TimerKind.rest) return const ['skipRest'];
    if (t != null) return const [];
    final c = currentSet;
    if (c == null) return const [];
    return c.$1.exercise.isTimed ? const ['startSet'] : const ['completeSet'];
  }

  /// A button on the lock-screen card was tapped.
  void handleCardAction(String action) {
    switch (action) {
      case 'skipRest' when _timer?.kind == TimerKind.rest:
        stopTimer();
      case 'startSet':
        final c = currentSet;
        if (c != null && _timer == null && c.$1.exercise.isTimed) startSetTimer(c.$1, c.$2);
      case 'completeSet':
        final c = currentSet;
        if (c != null && _timer?.kind != TimerKind.setTimer && !c.$2.done) {
          toggleDone(c.$1, c.$2);
        }
    }
  }

  LiveCard get liveCard {
    final w = _active;
    if (w == null) return const LiveCard(title: '');
    final all = w.exercises.expand((e) => e.sets).toList();
    final done = all.where((s) => s.done).length;
    final t = _timer;
    final current = currentSet;
    final progress = '$done/${all.length} sets';
    String title, detail;
    if (current == null) {
      title = all.isEmpty ? w.name : 'All sets done';
      detail = all.isEmpty ? 'Add an exercise' : 'Great work!';
    } else {
      final (e, s) = current;
      final same = e.sets.where((x) => x.side == s.side).toList();
      final side = s.side == null ? '' : (s.side == Side.left ? 'L' : 'R');
      title = (s.subExercise ?? e.exercise).name;
      detail = 'Set ${same.indexOf(s) + 1}$side of ${same.length}${_setTargetOf(s)}';
    }
    final countdownEnd = t != null && t.countsDown
        ? t.startedAt.add(Duration(seconds: t.total)) // + pauses: none for workout timers
        : null;
    return LiveCard(
      title: title,
      detail: detail,
      heartRate: hr.running ? hr.bpm : null,
      metrics: [('Sets done', progress), ('Heart rate', hr.running && hr.bpm != null ? '${hr.bpm}' : '–')],
      actions: cardActions,
      clockStart: w.startedAt,
      elapsed: DateTime.now().difference(w.startedAt),
      countdownStart: countdownEnd == null ? null : t!.startedAt,
      countdownEnd: countdownEnd,
      countdownLabel: t == null ? null : (t.kind == TimerKind.setTimer ? 'Hold' : t.label),
    );
  }

  /// " · 60 kg × 8" – the planned/typed values of a set, if any.
  static String _setTargetOf(LoggedSet s) {
    final parts = [
      if (s.weightKg != null && s.weightKg! > 0) formatWeight(s.weightKg!),
      if (s.reps != null) '${s.reps}',
      if (s.durationS != null && s.reps == null) '${s.durationS} s',
      if (s.distanceM != null) '${s.distanceM!.round()} m',
    ];
    return parts.isEmpty ? '' : ' · ${parts.join(' × ')}';
  }
}
