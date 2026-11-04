/// Monday 00:00 of the week containing [d].
DateTime weekStart(DateTime d) => DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

class StreakInfo {
  const StreakInfo({required this.weeks, required this.thisWeek, required this.daysThisWeek, required this.target});

  /// Consecutive weeks that reached the target (this week counts once reached).
  final int weeks;

  /// Workouts so far this week.
  final int thisWeek;

  /// Mon..Sun: did a workout that day?
  final List<bool> daysThisWeek;
  final int target;

  bool get thisWeekDone => thisWeek >= target;
}

/// Weekly streak from workout start times. The current week only adds to the
/// streak once its target is reached; it never breaks it while in progress.
StreakInfo weeklyStreak(Iterable<DateTime> workouts, {required int target, DateTime? now}) {
  final today = now ?? DateTime.now();
  final current = weekStart(today);
  final perWeek = <DateTime, int>{};
  for (final w in workouts) {
    final k = weekStart(w);
    perWeek[k] = (perWeek[k] ?? 0) + 1;
  }
  final thisWeek = perWeek[current] ?? 0;
  var weeks = thisWeek >= target ? 1 : 0;
  var week = current.subtract(const Duration(days: 7));
  // DST-safe: rebuild the date from y/m/d each step.
  while ((perWeek[week] ?? 0) >= target) {
    weeks++;
    week = DateTime(week.year, week.month, week.day - 7);
  }
  final days = List.generate(7, (i) {
    final day = DateTime(current.year, current.month, current.day + i);
    return workouts.any((w) => w.year == day.year && w.month == day.month && w.day == day.day);
  });
  return StreakInfo(weeks: weeks, thisWeek: thisWeek, daysThisWeek: days, target: target);
}
