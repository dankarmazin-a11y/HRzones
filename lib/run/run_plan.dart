import 'dart:convert';

import '../units/units.dart';

/// One part of a planned run, ended by distance (metres) or moving time
/// (seconds).
enum StepKind { warmup, work, recover, cooldown, goal }

class PlanStep {
  const PlanStep(this.kind, {required this.byDistance, required this.value});

  final StepKind kind;

  /// True: [value] is metres; false: seconds.
  final bool byDistance;
  final int value;

  String get label => switch (kind) {
    StepKind.warmup => 'Warm-up',
    StepKind.work => 'Run',
    StepKind.recover => 'Recover',
    StepKind.cooldown => 'Cool-down',
    StepKind.goal => 'Goal',
  };

  /// "400 m", "1.5 km", "10 min", "90 s".
  String get amount => byDistance ? metresText(value) : secondsText(value);

  Map<String, Object> toJson() => {byDistance ? 'd' : 's': value};

  static PlanStep? fromJson(StepKind kind, Object? json) {
    if (json is! Map) return null;
    final d = json['d'], s = json['s'];
    if (d is num) return PlanStep(kind, byDistance: true, value: d.toInt());
    if (s is num) return PlanStep(kind, byDistance: false, value: s.toInt());
    return null;
  }
}

/// "400 m", "5 km" – with miles chosen, a mile or more shows in miles
/// ("3.1 mi"); track distances stay in metres.
String metresText(int m) {
  if (Units.mi) {
    if (m < 1600) return '$m m';
    final v = Units.toD(m.toDouble());
    return '${(v - v.roundToDouble()).abs() < 0.05 ? v.round() : v.toStringAsFixed(1)} mi';
  }
  return m >= 1000 ? '${(m / 1000).toStringAsFixed(m % 1000 == 0 ? 0 : (m % 100 == 0 ? 1 : 2))} km' : '$m m';
}

String secondsText(int s) =>
    s >= 60 && s % 60 == 0 ? '${s ~/ 60} min' : (s >= 60 ? '${s ~/ 60} min ${s % 60} s' : '$s s');

/// A planned run: a single goal ("5 km", "45 min"), or intervals –
/// warm-up, N × (run + recover), cool-down.
class PlanSpec {
  const PlanSpec({this.goal, this.warmup, this.repeats = 1, this.work, this.recover, this.cooldown});

  final PlanStep? goal;
  final PlanStep? warmup;
  final int repeats;
  final PlanStep? work;
  final PlanStep? recover;
  final PlanStep? cooldown;

  bool get isIntervals => work != null;

  /// Every step in order.
  List<PlanStep> get steps => [
    ?goal,
    ?warmup,
    if (work != null)
      for (var i = 0; i < repeats; i++) ...[work!, if (recover != null && i < repeats - 1) recover!],
    ?cooldown,
  ];

  /// "Warm-up 10 min · 6 × 400 m / 200 m · Cool-down 5 min" or "5 km".
  String get description {
    final g = goal;
    if (g != null) return g.amount;
    return [
      if (warmup != null) 'Warm-up ${warmup!.amount}',
      if (work != null) '$repeats × ${work!.amount}${recover == null ? '' : ' / ${recover!.amount} easy'}',
      if (cooldown != null) 'Cool-down ${cooldown!.amount}',
    ].join(' · ');
  }

  String toJson() => jsonEncode({
    if (goal != null) 'goal': goal!.toJson(),
    if (warmup != null) 'warmup': warmup!.toJson(),
    'repeats': repeats,
    if (work != null) 'work': work!.toJson(),
    if (recover != null) 'recover': recover!.toJson(),
    if (cooldown != null) 'cooldown': cooldown!.toJson(),
  });

  static PlanSpec fromJson(String text) {
    try {
      final m = jsonDecode(text) as Map<String, dynamic>;
      return PlanSpec(
        goal: PlanStep.fromJson(StepKind.goal, m['goal']),
        warmup: PlanStep.fromJson(StepKind.warmup, m['warmup']),
        repeats: (m['repeats'] as num?)?.toInt() ?? 1,
        work: PlanStep.fromJson(StepKind.work, m['work']),
        recover: PlanStep.fromJson(StepKind.recover, m['recover']),
        cooldown: PlanStep.fromJson(StepKind.cooldown, m['cooldown']),
      );
    } catch (_) {
      return const PlanSpec();
    }
  }
}

/// Built-in planned runs (added once; the user can edit or delete them).
final defaultPlans = <(String, PlanSpec)>[
  ('Easy 5 km', const PlanSpec(goal: PlanStep(StepKind.goal, byDistance: true, value: 5000))),
  ('Long run 60 min', const PlanSpec(goal: PlanStep(StepKind.goal, byDistance: false, value: 3600))),
  (
    '6 × 400 m',
    const PlanSpec(
      warmup: PlanStep(StepKind.warmup, byDistance: false, value: 600),
      repeats: 6,
      work: PlanStep(StepKind.work, byDistance: true, value: 400),
      recover: PlanStep(StepKind.recover, byDistance: true, value: 200),
      cooldown: PlanStep(StepKind.cooldown, byDistance: false, value: 300),
    ),
  ),
  (
    'Tempo 3 × 1 km',
    const PlanSpec(
      warmup: PlanStep(StepKind.warmup, byDistance: false, value: 600),
      repeats: 3,
      work: PlanStep(StepKind.work, byDistance: true, value: 1000),
      recover: PlanStep(StepKind.recover, byDistance: false, value: 120),
      cooldown: PlanStep(StepKind.cooldown, byDistance: false, value: 300),
    ),
  ),
];

/// A finished part of a planned run (for the laps table).
class Lap {
  const Lap({required this.step, required this.distanceM, required this.seconds});

  final PlanStep step;
  final double distanceM;
  final double seconds;

  Map<String, Object> toJson() => {
    'k': step.kind.name,
    'by': step.byDistance ? 'd' : 's',
    'v': step.value,
    'm': distanceM,
    't': seconds,
  };

  static Lap? fromJson(Map<String, dynamic> m) {
    final kind = StepKind.values.where((k) => k.name == m['k']).firstOrNull;
    if (kind == null) return null;
    return Lap(
      step: PlanStep(kind, byDistance: m['by'] == 'd', value: (m['v'] as num).toInt()),
      distanceM: (m['m'] as num).toDouble(),
      seconds: (m['t'] as num).toDouble(),
    );
  }
}

String encodeLaps(List<Lap> laps) => jsonEncode([for (final l in laps) l.toJson()]);

List<Lap> decodeLaps(String? json) {
  if (json == null) return const [];
  try {
    return [for (final m in (jsonDecode(json) as List).cast<Map<String, dynamic>>()) ?Lap.fromJson(m)];
  } catch (_) {
    return const [];
  }
}

/// What changed when the run moved on.
enum PlanEvent { nextStep, halfway, done }

/// Follows the steps of a planned run as distance and time go by.
class PlanRunner {
  PlanRunner(this.spec) : steps = spec.steps;

  final PlanSpec spec;
  final List<PlanStep> steps;
  int index = 0;
  double _startM = 0, _startS = 0;
  bool _halfwaySaid = false;
  final laps = <Lap>[];

  bool get done => index >= steps.length;
  PlanStep? get current => done ? null : steps[index];

  /// Which repeat the current work/recover step belongs to (1-based), or null.
  int? get repeat {
    if (!spec.isIntervals || done) return null;
    final before = steps.take(index + 1).where((s) => s.kind == StepKind.work).length;
    return before == 0 ? null : before;
  }

  /// 0–1 of the current step and what is left ("156 m left" / "2:10 left").
  double progress(double metres, double seconds) {
    final s = current;
    if (s == null) return 1;
    final done = s.byDistance ? metres - _startM : seconds - _startS;
    return (done / s.value).clamp(0.0, 1.0);
  }

  /// Moving seconds at which the current time step ends (null for a
  /// distance step or when done) – for the countdown on the lock screen.
  /// Moving seconds when the current step started.
  double get stepStartSeconds => _startS;

  double? get stepEndSeconds {
    final s = current;
    return s == null || s.byDistance ? null : _startS + s.value;
  }

  double left(double metres, double seconds) {
    final s = current;
    if (s == null) return 0;
    return (s.value - (s.byDistance ? metres - _startM : seconds - _startS)).clamp(0, s.value.toDouble());
  }

  /// Call on every GPS fix / second with the run's distance and moving time.
  PlanEvent? update(double metres, double seconds) {
    final s = current;
    if (s == null) return null;
    final doneAmount = s.byDistance ? metres - _startM : seconds - _startS;
    if (doneAmount >= s.value) {
      laps.add(Lap(step: s, distanceM: metres - _startM, seconds: seconds - _startS));
      _startM = metres;
      _startS = seconds;
      index++;
      _halfwaySaid = false;
      return done ? PlanEvent.done : PlanEvent.nextStep;
    }
    if (s.kind == StepKind.goal && !_halfwaySaid && doneAmount >= s.value / 2) {
      _halfwaySaid = true;
      return PlanEvent.halfway;
    }
    return null;
  }

  /// At the finish: the step still running counts as a (shorter) lap.
  List<Lap> finish(double metres, double seconds) {
    final s = current;
    if (s != null && (metres - _startM > 20 || seconds - _startS > 10)) {
      laps.add(Lap(step: s, distanceM: metres - _startM, seconds: seconds - _startS));
    }
    index = steps.length;
    return laps;
  }
}
