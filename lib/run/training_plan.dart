import 'dart:convert';

import '../workout/streak.dart';
import 'run_plan.dart';

/// What kind of run a plan day is.
enum PlanDayKind {
  easy('Easy run'),
  long('Long run'),
  tempo('Tempo'),
  intervals('Intervals'),
  race('Race'),
  other('Run');

  const PlanDayKind(this.label);
  final String label;
}

/// One run in the plan: week (0-based), weekday (1 = Monday … 7 = Sunday),
/// a distance or a time (or neither), or one of the saved planned runs.
class PlanDay {
  const PlanDay({
    required this.week,
    required this.weekday,
    required this.kind,
    this.distanceM,
    this.durationS,
    this.runPlanId,
    this.runPlanName,
  });

  final int week;
  final int weekday;
  final PlanDayKind kind;
  final int? distanceM;
  final int? durationS;

  /// A saved planned run (intervals etc.) to start for this day.
  final String? runPlanId;
  final String? runPlanName;

  /// "Easy run · 5 km", "Intervals · 6 × 400 m", "Long run · 60 min".
  String get describe {
    final amount =
        runPlanName ??
        (distanceM != null
            ? '${formatKmShort(distanceM!)} km'
            : (durationS != null ? '${(durationS! / 60).round()} min' : null));
    return amount == null ? kind.label : '${kind.label} · $amount';
  }

  PlanDay copyWith({int? week}) => PlanDay(
    week: week ?? this.week,
    weekday: weekday,
    kind: kind,
    distanceM: distanceM,
    durationS: durationS,
    runPlanId: runPlanId,
    runPlanName: runPlanName,
  );

  Map<String, Object?> toJson() => {
    'w': week,
    'd': weekday,
    'k': kind.name,
    if (distanceM != null) 'm': distanceM,
    if (durationS != null) 's': durationS,
    if (runPlanId != null) 'p': runPlanId,
    if (runPlanName != null) 'pn': runPlanName,
  };

  static PlanDay? fromJson(Object? j) {
    if (j is! Map) return null;
    final kind = PlanDayKind.values.where((k) => k.name == j['k']).firstOrNull;
    final w = j['w'], d = j['d'];
    if (kind == null || w is! num || d is! num) return null;
    return PlanDay(
      week: w.toInt(),
      weekday: d.toInt(),
      kind: kind,
      distanceM: (j['m'] as num?)?.toInt(),
      durationS: (j['s'] as num?)?.toInt(),
      runPlanId: j['p'] as String?,
      runPlanName: j['pn'] as String?,
    );
  }
}

String formatKmShort(int metres) {
  final km = metres / 1000;
  return km == km.roundToDouble() ? '${km.round()}' : km.toStringAsFixed(1);
}

String encodePlanDays(List<PlanDay> days) => jsonEncode([for (final d in days) d.toJson()]);

List<PlanDay> decodePlanDays(String? json) {
  if (json == null || json.isEmpty) return [];
  try {
    return [for (final j in jsonDecode(json) as List) ?PlanDay.fromJson(j)];
  } catch (_) {
    return [];
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// How a plan day is going.
enum DayStatus { done, missed, today, upcoming }

/// A plan with its days and the dates you ran on: what's today, what's done.
class WeeklyPlan {
  WeeklyPlan({required DateTime start, required this.weeks, required this.days, required Iterable<DateTime> runDates})
    : start = weekStart(start),
      _ran = {for (final r in runDates) _dateOnly(r)};

  /// Sunday of week 1 (weeks run Sunday … Saturday).
  final DateTime start;
  final int weeks;
  final List<PlanDay> days;
  final Set<DateTime> _ran;

  DateTime dateOf(PlanDay d) => DateTime(start.year, start.month, start.day + d.week * 7 + dayIndex(d.weekday));

  /// Done = you recorded (or logged) any run that day.
  DayStatus status(PlanDay d, DateTime now) {
    final date = dateOf(d), today = _dateOnly(now);
    if (_ran.contains(date)) return DayStatus.done;
    if (date == today) return DayStatus.today;
    return date.isBefore(today) ? DayStatus.missed : DayStatus.upcoming;
  }

  /// 0-based week that [now] falls in (may be < 0 before the start or
  /// ≥ weeks after the end).
  int weekIndex(DateTime now) => (_dateOnly(now).difference(start).inDays / 7).floor();

  bool finishedBy(DateTime now) => weekIndex(now) >= weeks;

  PlanDay? today(DateTime now) {
    final w = weekIndex(now);
    return days.where((d) => d.week == w && d.weekday == now.weekday).firstOrNull;
  }

  /// The next planned run from today on (today included).
  PlanDay? next(DateTime now) {
    final today = _dateOnly(now);
    final upcoming = days.where((d) => !dateOf(d).isBefore(today)).toList()
      ..sort((a, b) => dateOf(a).compareTo(dateOf(b)));
    return upcoming.firstOrNull;
  }

  List<PlanDay> week(int w) =>
      days.where((d) => d.week == w).toList()..sort((a, b) => dayIndex(a.weekday) - dayIndex(b.weekday));

  /// (done, planned) runs in week [w].
  (int, int) weekProgress(int w, DateTime now) {
    final list = week(w);
    return (list.where((d) => status(d, now) == DayStatus.done).length, list.length);
  }

  /// (done, planned) over the whole plan.
  (int, int) totalProgress(DateTime now) => (days.where((d) => status(d, now) == DayStatus.done).length, days.length);
}

/// A plan day's planned run spec (goal by distance/time) to start a run with
/// a target, when the day has no saved planned run.
PlanSpec? goalSpecFor(PlanDay d) {
  if (d.distanceM != null) return PlanSpec(goal: PlanStep(StepKind.goal, byDistance: true, value: d.distanceM!));
  if (d.durationS != null) return PlanSpec(goal: PlanStep(StepKind.goal, byDistance: false, value: d.durationS!));
  return null;
}
