/// Weeks start on Sunday (owner, 2026-11-10).
/// Sunday 00:00 of the week containing [d].
DateTime weekStart(DateTime d) => DateTime(d.year, d.month, d.day - d.weekday % 7);

/// Position of [weekday] (1 = Monday … 7 = Sunday) in a week: Sunday = 0.
int dayIndex(int weekday) => weekday % 7;

/// Weekdays (1 = Monday … 7 = Sunday) in week order: Sunday first.
const weekdayOrder = [7, 1, 2, 3, 4, 5, 6];

/// One letter per day in week order.
const weekLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

class StreakInfo {
  const StreakInfo({required this.weeks, required this.thisWeek, required this.daysThisWeek, required this.target});

  /// Consecutive weeks that reached the target (this week counts once reached).
  final int weeks;

  /// Workouts so far this week.
  final int thisWeek;

  /// Sun..Sat: did a workout that day?
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
