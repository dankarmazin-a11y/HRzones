import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../bike/bike_sensors.dart';
import '../data/database.dart';
import '../data/run_repository.dart';
import '../hr/hr_monitor.dart';
import '../beep/sounds.dart';
import '../hr/zone_alert_engine.dart';
import '../hr/zones.dart';
import '../live/live_activity.dart';
import '../notify/rest_notifier.dart';
import '../workout/stats.dart' show formatDuration;
import 'best_efforts.dart';
import 'elevation.dart';
import 'gait.dart';
import 'geo.dart';
import 'location_source.dart';
import 'motion_source.dart';
import 'run_plan.dart';
import 'run_voice.dart';
import '../units/units.dart';

/// GPS signal as shown on the run screen.
enum GpsStatus {
  /// Not recording (no run, or paused – GPS is off then to save battery).
  off,

  /// Waiting for the first accurate fix.
  searching,
  good,

  /// No accurate fix for a while (tunnel, buildings).
  weak,
}

/// One recorded point of the route (kept in memory while running).
class RoutePoint {
  const RoutePoint({
    required this.time,
    required this.lat,
    required this.lon,
    this.accuracy,
    this.altitude,
    required this.segment,
    this.hr,
    this.cadence,
  });

  final DateTime time;
  final double lat;
  final double lon;
  final double? accuracy;
  final double? altitude;
  final int segment;
  final int? hr;

  /// Steps per minute (null = unknown) – tells walking from running.
  final int? cadence;
}

/// The recorded points as the walk/run detection needs them.
List<GaitPoint> gaitPoints(Iterable<RoutePoint> route) => [
  for (final p in route)
    (time: p.time, lat: p.lat, lon: p.lon, accuracy: p.accuracy, segment: p.segment, cadence: p.cadence),
];

/// Records a run: GPS route, distance, moving time, pace and heart rate.
/// Keeps working with the screen locked (iOS background location). GPS only
/// runs while recording – it is switched off when paused or finished.
class RunSession extends ChangeNotifier {
  RunSession({
    required this.runs,
    required this.hr,
    LocationSource? location,
    MotionSource? motion,
    DateTime Function()? clock,
  }) : location = location ?? LocationSource.create(),
       motion = motion ?? NoMotionSource(),
       now = clock ?? DateTime.now;

  /// Bluetooth speed/cadence and power sensors, used on rides.
  BikeSensorHub? bike;

  /// The rider's weight in kg for W/kg (latest body weight; set at start).
  Future<double?> Function()? riderWeight;
  double? _riderKg;
  int _powerSum = 0, _powerN = 0;
  int? _maxPowerW;
  double _bikeCadSum = 0;
  int _bikeCadN = 0;
  DateTime? _lastBikeSample;

  /// Watts now (rides with a power meter).
  int? get powerW => riding && !paused ? bike?.power : null;

  /// Average watts so far (coasting counts as 0); null without a power meter.
  int? get avgPowerW => _powerN == 0 ? null : (_powerSum / _powerN).round();
  int? get maxPowerW => _maxPowerW;

  /// Pedal turns per minute (rides with a cadence sensor or power meter).
  double? get bikeCadence => riding && !paused ? bike?.cadence : null;

  /// Watts per kg of body weight (null without a power meter or a weight).
  double? get wattsPerKg {
    final w = powerW, kg = _riderKg;
    return w == null || kg == null || kg <= 0 ? null : w / kg;
  }

  double? get avgWattsPerKg {
    final w = avgPowerW, kg = _riderKg;
    return w == null || kg == null || kg <= 0 ? null : w / kg;
  }

  @visibleForTesting
  void sampleBikeForTest() => _sampleBike();

  /// Every second while a ride records: power, cadence and (indoors) the
  /// wheel sensor's speed and distance.
  void _sampleBike() {
    final b = bike;
    if (b == null || !riding || paused) {
      _lastBikeSample = null;
      return;
    }
    final t = now();
    final last = _lastBikeSample;
    _lastBikeSample = t;
    final w = b.power;
    if (w != null) {
      _powerSum += w;
      _powerN++;
      if (_maxPowerW == null || w > _maxPowerW!) _maxPowerW = w;
    }
    final c = b.cadence;
    if (c != null && c > 0) {
      _bikeCadSum += c;
      _bikeCadN++;
    }
    final v = b.speedMs;
    if (_treadmill && v != null && last != null) {
      final dt = t.difference(last).inMilliseconds / 1000;
      if (dt > 0 && dt <= 5) _tracker.distanceM += v * dt;
      if (v <= maxPlausibleSpeedMs && (_maxSpeedMs == null || v > _maxSpeedMs!)) _maxSpeedMs = v;
    }
  }

  /// Step counter for cadence (the phone's motion chip).
  MotionSource motion;
  int _stepsBefore = 0, _steps = 0;
  bool _counting = false;
  double? _cadence;
  final _stepSamples = <(DateTime, int)>[];

  /// Steps so far (null when the phone can't count them).
  int? get steps => _counting || _steps > 0 ? _stepsBefore + _steps : (_stepsBefore > 0 ? _stepsBefore : null);

  /// Current cadence in steps per minute (null when paused or unknown).
  double? get cadence => paused ? null : _cadence;

  Future<void> _startSteps() async {
    _steps = 0;
    _stepSamples.clear();
    _baroBase = null; // the barometer starts from 0 again
    _counting = await motion.start();
  }

  // ── Barometer height ────────────────────────────────────────────────
  /// Offset that turns the barometer's "height since start" into a height
  /// continuing from the last known one (a new segment starts at 0 again).
  double? _baroBase;

  /// Latest height (barometer, continued over pauses); null without one.
  double? _baroAlt;

  /// Latest GPS height (the barometer's starting point).
  double? _gpsAlt;

  /// Climb / descent from the barometer (stored with the run).
  double _gainM = 0, _lossM = 0;
  double? _elevRef;
  bool _hasBaro = false;

  /// Moves less than this and it doesn't count (barometer noise).
  static const elevStep = 1.0;

  /// Climb and descent so far (null when the phone has no barometer).
  ({double climb, double descent})? get baroElevation => _hasBaro ? (climb: _gainM, descent: _lossM) : null;

  void _onBaro(double relative) {
    _baroBase ??= (_baroAlt ?? _gpsAlt ?? 0) - relative;
    final alt = _baroBase! + relative;
    _baroAlt = alt;
    _hasBaro = true;
    final ref = _elevRef;
    if (ref == null) {
      _elevRef = alt;
    } else if (alt - ref >= elevStep) {
      _gainM += alt - ref;
      _elevRef = alt;
    } else if (ref - alt >= elevStep) {
      _lossM += ref - alt;
      _elevRef = alt;
    }
  }

  /// Reads steps and the barometer now (tests; the run does it every 5 s).
  @visibleForTesting
  Future<void> readMotion() => _readSteps();

  /// Reads the step counter (every few seconds and before saving).
  Future<void> _readSteps() async {
    if (!_counting) return;
    final r = await motion.read();
    if (r == null) return;
    if (r.altitude != null && !_treadmill) _onBaro(r.altitude!);
    _steps = r.steps;
    final t = now();
    _stepSamples.add((t, r.steps));
    _stepSamples.removeWhere((x) => t.difference(x.$1) > const Duration(seconds: 30));
    if (r.cadence != null) {
      _cadence = r.cadence;
    } else if (_stepSamples.length >= 2) {
      final a = _stepSamples.first, b = _stepSamples.last;
      final secs = b.$1.difference(a.$1).inMilliseconds / 1000;
      _cadence = secs >= 8 ? (b.$2 - a.$2) / secs * 60 : null;
    }
  }

  Future<void> _stopSteps() async {
    if (!_counting) return;
    await _readSteps();
    await motion.stop();
    _stepsBefore += _steps;
    _steps = 0;
    _counting = false;
    _cadence = null;
  }

  final RunRepository runs;
  final HrMonitor hr;
  LocationSource location;
  final DateTime Function() now;

  /// Spoken updates (set by AppServices; none in some tests).
  RunVoice? voice;

  /// Looks up a planned run (set by AppServices; used when restoring).
  Future<RunPlan?> Function(String id)? plans;

  /// Looks up the run's heart-rate preset when the run is restored after the
  /// app was closed (set by AppServices; returns null when zones are off).
  Future<HrPreset?> Function(String? id)? presetFor;

  /// "Still running?" notification (set by AppServices).
  RestNotifier? notifier;

  /// The run's card on the lock screen / Dynamic Island (set by AppServices).
  LiveActivity? live;

  /// Name on the card: the planned run's name, or "Run".
  String? _planName;

  /// What the lock-screen card shows right now.
  LiveCard get liveCard {
    final start = _startedAt ?? now();
    final clockStart = paused ? null : start.add(Duration(milliseconds: _pausedMs));
    final p = plan, step = p?.current;
    final secs = moving.inMilliseconds / 1000;
    String detail;
    DateTime? countdownStart, countdownEnd;
    if (p != null && step != null) {
      final left = p.left(distanceM, secs);
      detail = [
        '${step.label} ${step.amount}',
        step.byDistance ? '${left.round()} m left' : '${formatDuration(Duration(seconds: left.round()))} left',
        if (p.repeat != null && p.spec.repeats > 1) '${p.repeat}/${p.spec.repeats}',
      ].join(' · ');
      final end = p.stepEndSeconds;
      if (end != null && clockStart != null) {
        countdownEnd = clockStart.add(Duration(milliseconds: (end * 1000).round()));
        countdownStart = clockStart.add(Duration(milliseconds: (p.stepStartSeconds * 1000).round()));
      }
    } else if (_treadmill) {
      detail = 'Treadmill';
    } else {
      detail = gps == GpsStatus.searching ? 'Finding GPS…' : '';
    }
    final bpm = hr.running ? hr.bpm : null;
    final cp = currentPace, ap = avgPace;
    final st = steps;
    final metrics = <(String, String)>[
      // walks and hikes: steps / climb instead of the current pace
      if (_chosen == RunActivity.walk && st != null) ('Steps', '$st'),
      if (_chosen == RunActivity.hike && climbM != null) ('Climbed', '${climbM!.round()} m'),
      if (riding && (!_treadmill || bike?.speedMs != null))
        ('Speed', paused || cp == null ? '–' : formatSpeed(cp, unit: false)),
      if (riding && powerW != null)
        ('Watts', '$powerW')
      else if (!_treadmill && riding)
        ('Avg ${Units.speed}', ap == null ? '–' : formatSpeed(ap, unit: false)),
      if (!_treadmill && _chosen == RunActivity.run) ('Pace', paused || cp == null ? '–' : formatPace(cp)),
      if (!_treadmill && !riding) ('Avg pace', ap == null ? '–' : formatPace(ap)),
      ('Heart rate', bpm == null ? '–' : '$bpm'),
    ];
    if (_chosen == RunActivity.run && _liveGait == Gait.walk && autoDetect && !paused && detail.isEmpty) {
      detail = 'Walking';
    }
    return LiveCard(
      title: _treadmill ? 'Treadmill ${_word(_chosen).toLowerCase()}' : '${formatKm(distanceM)} ${Units.d}',
      detail: paused ? 'Paused' : detail,
      heartRate: hr.running ? hr.bpm : null,
      clockStart: clockStart,
      elapsed: moving,
      countdownStart: paused ? null : countdownStart,
      countdownEnd: paused ? null : countdownEnd,
      countdownLabel: step?.label,
      paused: paused,
      metrics: metrics,
    );
  }

  void _liveStart() {
    if (!active) return;
    live?.start('run', _planName ?? (_treadmill ? 'Treadmill run' : 'Run'), liveCard);
  }

  void _pushLive({bool now = false}) {
    if (active) live?.update(liveCard, now: now);
  }

  /// No movement for this long while recording → "Still running?".
  static const idleAfter = Duration(minutes: 20);

  /// Paused this long → "Still running?".
  static const pausedIdleAfter = Duration(minutes: 30);

  /// Changes every second while recording and on every GPS fix: the live
  /// numbers listen to this, the rest of the screen to the session itself.
  final ticks = ValueNotifier<int>(0);

  String? _id;
  DateTime? _startedAt;
  DateTime? _pausedAt;
  DateTime? _endOverride;
  int _pausedMs = 0;
  String? _presetId;
  String? _shoeId;
  int _segment = 0;
  final _tracker = DistanceTracker();
  final _route = <RoutePoint>[];
  int _saved = 0;

  /// (time, total distance) of recent fixes, for the current pace.
  final _recent = <(DateTime, double)>[];
  DateTime? _lastGoodAt;
  bool _hrStartedByRun = false;

  /// Target pace range for beeps (setting `runPaceAlert`); null = off.
  /// [HrRange] holds seconds per km: min = fastest, max = slowest.
  HrRange? paceAlert;

  /// Rides: beep and say "Speed up" when slower than this (m/s; setting
  /// `rideSpeedAlert`; null = off).
  double? rideSpeedAlert;

  /// While walking: beep when slower than this (s/km, setting `walkPaceAlert`;
  /// null = no pace beeps while walking – a walk break never beeps "speed up").
  int? walkPaceAlert;

  /// While walking, the heart-rate range of this zone is used instead of the
  /// run's (setting `walkPresetId`; null = keep the run's).
  HrPreset? walkPreset;

  /// Rides pause by themselves when you stop and go on when you move again
  /// (setting `autoPauseRide`, default on). GPS stays on while auto-paused.
  bool autoPauseRide = true;

  /// Auto-paused (not paused by hand): waiting to move again.
  bool get autoPaused => _autoPaused;
  bool _autoPaused = false;
  DateTime? _resumedAt;
  final _still = <GeoFix>[];

  /// Notice walking / running by itself (setting `autoDetectWalk`, default on):
  /// live label, alerts, and the run / walk label at the end.
  bool autoDetect = true;

  /// Metres climbed so far (barometer; null without one).
  double? get climbM => _hasBaro ? _gainM : null;

  /// What the owner picked at the start (Run · Walk · Hike).
  RunActivity get chosen => _chosen;
  RunActivity _chosen = RunActivity.run;

  /// Walking or running right now (changes after [gaitSwitchAfter] of the other).
  Gait get liveGait => _liveGait;
  Gait _liveGait = Gait.run;
  Gait? _gaitCandidate;
  DateTime? _gaitCandidateSince;
  HrRange? _runRange;

  /// After the outing: a note when the label differs from what was picked
  /// ("You picked Walk but mostly ran – saved as a run."). Read once.
  String? takeLabelNote() {
    final n = _labelNote;
    _labelNote = null;
    return n;
  }

  String? _labelNote;

  static const gaitSwitchAfter = Duration(seconds: 15);

  /// The same alert logic as for heart rate (grace, cooldown), fed with
  /// the current pace. GPS pace is jumpy: a longer grace.
  final _paceEngine = ZoneAlertEngine(
    range: const HrRange(min: 300, max: 360),
    settings: const AlertSettings(grace: Duration(seconds: 10), cooldown: Duration(seconds: 30), hysteresisBpm: 3),
  );
  StreamSubscription<GeoFix>? _gps;
  Timer? _ticker;
  int _sinceSave = 0;
  bool _finishing = false;

  /// Seconds between saves while recording (points are also saved when the
  /// app goes to the background).
  static const saveEvery = 10;

  /// How far back the current pace looks.
  static const paceWindow = Duration(seconds: 30);

  bool _treadmill = false;

  /// Decided at the end (run / walk) and how far was walked.
  RunActivity _activity = RunActivity.run;
  double? _walkedM;
  DateTime? _lastMoveAt;
  double _moveMark = 0;
  DateTime? _idleScheduledAt;

  /// "Keep going" during a long pause: count the pause from then.
  DateTime? _snoozedAt;

  /// When the current pause started (null when not paused).
  DateTime? get lastPausedAt => _pausedAt;

  /// Treadmill run: no GPS; the distance is typed in at the end.
  bool get treadmill => _treadmill;

  /// When the runner last moved (30 m or more); the start for a treadmill.
  DateTime? get lastMoveAt => _lastMoveAt;

  /// How long the run looks forgotten: paused for a long time, or recording
  /// outdoors without moving. Zero while all is fine.
  Duration get idleFor {
    if (!active) return Duration.zero;
    final p = _pausedAt;
    if (p != null) {
      final d = now().difference(_snoozedAt ?? p);
      return d >= pausedIdleAfter ? d : Duration.zero;
    }
    final m = _lastMoveAt;
    if (_treadmill || m == null) return Duration.zero;
    final d = now().difference(m);
    return d >= idleAfter ? d : Duration.zero;
  }

  bool get active => _id != null;
  bool get paused => _pausedAt != null;
  String? get runId => _id;
  DateTime? get startedAt => _startedAt;
  String? get presetId => _presetId;

  /// The shoes worn on this run.
  String? get shoeId => _shoeId;
  List<RoutePoint> get route => List.unmodifiable(_route);
  double get distanceM => _tracker.distanceM;

  Duration get moving {
    final s = _startedAt;
    if (s == null) return Duration.zero;
    final ms = (_endOverride ?? _pausedAt ?? now()).difference(s).inMilliseconds - _pausedMs;
    return Duration(milliseconds: ms < 0 ? 0 : ms);
  }

  /// Average pace (s/km) so far; null for the first 50 m.
  double? get avgPace => distanceM < 50 ? null : paceSecPerKm(distanceM, moving.inMilliseconds / 1000);

  /// A ride (picked at the start): speed instead of pace, no walk detection.
  bool get riding => _chosen == RunActivity.ride;

  /// Speed now (m/s, over the last 30 s), on average, and the top speed over
  /// 10 s so far; null when unknown.
  double? get speedMs {
    final p = currentPace;
    return p == null || p <= 0 ? null : 1000 / p;
  }

  double? get avgSpeedMs => avgPace == null ? null : 1000 / avgPace!;
  double? get maxSpeedMs => _maxSpeedMs;
  double? _maxSpeedMs;

  /// Faster than this over 10 s is a GPS glitch, not a ride (108 km/h).
  static const maxPlausibleSpeedMs = 30.0;

  /// Pace over the last 30 s (s/km); null when standing still or no GPS.
  double? get currentPace {
    if (paused) return null;
    // indoor ride with a speed sensor: the wheel's speed
    final wheel = _treadmill && riding ? bike?.speedMs : null;
    if (wheel != null) return wheel < 0.5 ? null : 1000 / wheel;
    if (_recent.length < 2) return null;
    final last = _recent.last;
    if (now().difference(_lastGoodAt ?? DateTime(0)) > const Duration(seconds: 10)) return null;
    final first = _recent.first;
    final seconds = last.$1.difference(first.$1).inMilliseconds / 1000;
    final metres = last.$2 - first.$2;
    if (seconds < 8 || metres < 15) return null;
    return paceSecPerKm(metres, seconds);
  }

  GpsStatus get gps {
    if (!active || paused || _treadmill) return GpsStatus.off;
    final last = _lastGoodAt;
    if (last == null) return GpsStatus.searching;
    return now().difference(last) > const Duration(seconds: 10) ? GpsStatus.weak : GpsStatus.good;
  }

  /// Starts recording. Asks for location permission first; returns what the
  /// phone answered (only [LocationAccess.granted] starts a run).
  /// An earlier run on the same route to race against (null = none).
  GhostRun? ghost;

  /// The planned run being followed (null = free run).
  PlanRunner? plan;
  String? _planId;
  String? get planId => _planId;

  /// Moves the plan on (every fix and every second).
  void _advancePlan() {
    final p = plan;
    if (p == null || p.done || paused) return;
    final event = p.update(distanceM, moving.inMilliseconds / 1000);
    if (event == null) return;
    switch (event) {
      case PlanEvent.halfway:
        voice?.planHalfway();
      case PlanEvent.nextStep:
        final step = p.current!;
        final hard = step.kind == StepKind.work || step.kind == StepKind.goal;
        hr.beeper.play(hard ? SoundEvent.intervalWork : SoundEvent.intervalRest);
        HapticFeedback.vibrate();
        voice?.planStep(step, repeat: p.repeat, repeats: p.spec.repeats);
      case PlanEvent.done:
        hr.beeper.play(SoundEvent.intervalDone);
        HapticFeedback.vibrate();
        voice?.planDone();
    }
    _pushLive(now: true);
    notifyListeners();
  }

  /// Seconds behind (+) or ahead (−) of [ghost] at the current distance.
  double? get ghostDelta {
    final g = ghost;
    if (g == null || distanceM < 50) return null;
    final t = g.timeAt(distanceM);
    return t == null ? null : moving.inMilliseconds / 1000 - t;
  }

  Future<LocationAccess> start({
    HrPreset? preset,
    bool treadmill = false,
    String? shoeId,
    GhostRun? ghost,
    RunPlan? plan,
    RunActivity activity = RunActivity.run,
  }) async {
    if (active) return LocationAccess.granted;
    final access = treadmill ? LocationAccess.granted : await location.ensureAccess();
    if (access != LocationAccess.granted) return access;
    _reset();
    _id = newId();
    _startedAt = now();
    _treadmill = treadmill;
    _shoeId = shoeId;
    this.ghost = treadmill ? null : ghost;
    // A plan day's distance/time goal has no saved planned run (id '').
    _planId = (plan?.id ?? '').isEmpty ? null : plan!.id;
    _planName = plan?.name;
    this.plan = plan == null ? null : PlanRunner(PlanSpec.fromJson(plan.specJson));
    _lastMoveAt = _startedAt;
    _presetId = preset?.id;
    _chosen = activity;
    if (riding) {
      bike?.start();
      _riderKg = await riderWeight?.call();
    }
    voice?.word = _word(activity);
    _liveGait = activity == RunActivity.run ? Gait.run : Gait.walk;
    _runRange = preset == null ? null : HrRange(min: preset.minBpm, max: preset.maxBpm);
    hr.resetSession();
    final startRange = _rangeFor(_liveGait);
    if (startRange != null) {
      hr.setRange(startRange);
      if (preset != null) hr.setBeepWhen(BeepWhen.values[preset.beepWhen.clamp(0, BeepWhen.values.length - 1)]);
      if (!hr.running) {
        await hr.start();
        _hrStartedByRun = true;
      }
    }
    await _startSteps();
    await _saveRun();
    _listen();
    _hookAlerts();
    voice?.started();
    final first = this.plan?.current;
    if (first != null) voice?.planStep(first, repeat: this.plan!.repeat, repeats: this.plan!.spec.repeats);
    _liveStart();
    notifyListeners();
    return access;
  }

  Future<void> pause() async {
    if (!active) return;
    if (_autoPaused) {
      // already stopped: now paused by hand (GPS off, like any pause)
      _autoPaused = false;
      _still.clear();
      await _stopGps();
      await _stopSteps();
      notifyListeners();
      return;
    }
    if (paused) return;
    _pausedAt = now();
    await _stopGps();
    await _stopSteps();
    _tracker.newSegment();
    _recent.clear();
    _segment++;
    voice?.paused();
    _pushLive(now: true);
    await flush();
    notifyListeners();
  }

  Future<void> resume() async {
    final p = _pausedAt;
    if (!active || p == null) return;
    if (_autoPaused) return _autoResume();
    _pausedMs += now().difference(p).inMilliseconds;
    _pausedAt = null;
    _lastGoodAt = null;
    _lastMoveAt = now();
    _snoozedAt = null;
    voice?.resumed();
    _pushLive(now: true);
    await _startSteps();
    await flush();
    _listen();
    notifyListeners();
  }

  /// Ends the run and saves it; returns its id (null if no run).
  /// [endAt]: a forgotten run ends at that time (route after it is dropped).
  /// [distanceM]: the treadmill's distance.
  Future<String?> finish({DateTime? endAt, double? distanceM}) async {
    final id = _id;
    if (id == null || _finishing) return null;
    _finishing = true;
    try {
      await _stopGps();
      await _stopSteps();
      bike?.stop();
      if (endAt != null) {
        final p = _pausedAt;
        _endOverride = p != null && p.isBefore(endAt) ? p : endAt;
        _route.removeWhere((x) => x.time.isAfter(endAt));
        await runs.deletePointsAfter(id, endAt);
        _saved = _saved.clamp(0, _route.length);
        _replayDistance();
      }
      if (distanceM != null) _tracker.distanceM = distanceM;
      final end = _endOverride ?? _pausedAt ?? now();
      await _savePoints();
      final bests = _treadmill
          ? <int, double>{}
          : bestEfforts(
              _route.map((p) => (time: p.time, lat: p.lat, lon: p.lon, accuracy: p.accuracy, segment: p.segment)),
              distances: recordDistancesFor(ride: riding).keys,
            );
      // Run or walk: from the route (pace + steps), or the averages on a treadmill.
      final gait = _treadmill ? GaitSummary.empty : analyzeGait(gaitPoints(_route));
      _walkedM = _treadmill ? null : gait.walkedM;
      final detected =
          (_treadmill
              ? isWalkByAverages(distanceM: this.distanceM, durationS: moving.inSeconds, avgCadence: _avgCadence())
              : gait.isWalk)
          ? RunActivity.walk
          : RunActivity.run;
      // A hike stays a hike; otherwise what was done wins over what was picked
      // (when detection is on) – too short to tell keeps the pick – and the owner is told.
      final enough = _treadmill ? this.distanceM >= 200 : gait.totalM >= 200;
      // a ride is a ride (walking pace on a bike would read as a walk)
      _activity = _chosen == RunActivity.hike || riding || !autoDetect || !enough ? _chosen : detected;
      // Mostly walking and steep (over 30 m climbed per km): a hike.
      if (_activity == RunActivity.walk && autoDetect && !_treadmill && this.distanceM >= 1000) {
        final climb = _hasBaro ? _gainM : elevationGainLoss([for (final p in _route) ?p.altitude]).climb;
        if (climb / (this.distanceM / 1000) > hikeClimbPerKm) _activity = RunActivity.hike;
      }
      _labelNote = _activity == _chosen
          ? null
          : switch (_activity) {
              RunActivity.run => 'You picked ${_word(_chosen)}, but you mostly ran – saved as a run.',
              RunActivity.hike => 'You walked and climbed a lot – saved as a hike.',
              RunActivity.walk => 'You mostly walked – saved as a walk.',
              RunActivity.ride => null,
            };
      // Faster than every earlier outing of the same kind (the first one at a distance isn't a record).
      final before = await runs.records(before: _startedAt, excludeId: id, activity: _activity);
      final newRecords = <int, double>{
        for (final e in bests.entries)
          if (before.fastest[e.key] != null && e.value < before.fastest[e.key]!.value) e.key: e.value,
      };
      final laps = plan?.finish(this.distanceM, moving.inMilliseconds / 1000);
      await _saveRun(
        endedAt: end,
        avgHr: hr.sessionAvg,
        maxHr: hr.sessionMax,
        bests: bests,
        laps: laps == null || laps.isEmpty ? null : encodeLaps(laps),
      );
      voice?.finished(this.distanceM, moving, newRecords: newRecords);
      live?.end(kind: 'run');
      if (_hrStartedByRun) await hr.stop();
      hr.onAlert = null;
      await notifier?.cancelRunIdle();
      _reset();
      notifyListeners();
      return id;
    } finally {
      _finishing = false;
    }
  }

  /// Throws the run away.
  Future<void> discard() async {
    final id = _id;
    if (id == null) return;
    await _stopGps();
    await _stopSteps();
    bike?.stop();
    if (_hrStartedByRun) await hr.stop();
    hr.onAlert = null;
    await notifier?.cancelRunIdle();
    live?.end(kind: 'run');
    await runs.delete(id);
    _reset();
    notifyListeners();
  }

  /// Picks up a run that was being recorded when the app was closed.
  Future<void> restore() async {
    final row = await runs.loadActive();
    if (row == null) return;
    _reset();
    _id = row.id;
    _startedAt = row.startedAt;
    _pausedAt = row.pausedAt;
    _pausedMs = row.pausedS * 1000;
    _presetId = row.hrPresetId;
    _maxSpeedMs = row.maxSpeedMs;
    _chosen = row.activity;
    if (riding) {
      bike?.start();
      _riderKg = await riderWeight?.call();
      _maxPowerW = row.maxPowerW;
      final secs = (row.durationS).clamp(0, 1 << 30);
      if (row.avgPowerW != null && secs > 0) {
        _powerN = secs;
        _powerSum = row.avgPowerW! * secs;
      }
      if (row.avgCadence != null && secs > 0) {
        _bikeCadN = secs;
        _bikeCadSum = row.avgCadence! * secs.toDouble();
      }
    }
    voice?.word = _word(_chosen);
    _liveGait = _chosen == RunActivity.run ? Gait.run : Gait.walk;
    _treadmill = row.kind == RunKind.treadmill;
    _shoeId = row.shoeId;
    _stepsBefore = row.steps ?? 0;
    _hasBaro = row.elevGainM != null;
    _gainM = row.elevGainM ?? 0;
    _lossM = row.elevLossM ?? 0;
    var segment = -1;
    for (final p in await runs.points(row.id)) {
      if (p.segment != segment) _tracker.newSegment();
      segment = p.segment;
      _tracker.add(GeoFix(time: p.time, lat: p.lat, lon: p.lon, accuracy: p.accuracy));
      _route.add(
        RoutePoint(
          time: p.time,
          lat: p.lat,
          lon: p.lon,
          accuracy: p.accuracy,
          altitude: p.altitude,
          segment: p.segment,
          hr: p.hr,
          cadence: p.cadence,
        ),
      );
    }
    _saved = _route.length;
    if (_route.isNotEmpty) {
      _baroAlt = _hasBaro ? _route.last.altitude : null;
      _gpsAlt = _route.last.altitude;
      _elevRef = _baroAlt;
    }
    // The app was closed: don't draw a line across the gap.
    _segment = segment + 1;
    _tracker.newSegment();
    _lastMoveAt = _route.isEmpty ? row.startedAt : _route.last.time;
    _moveMark = distanceM;
    voice?.restored(distanceM, moving);
    // The app was closed mid-run: turn the run's heart-rate beeps back on
    // (they stayed off before – the run went on without zone alerts).
    final preset = await presetFor?.call(row.hrPresetId);
    if (preset != null) {
      hr.setRange(HrRange(min: preset.minBpm, max: preset.maxBpm));
      hr.setBeepWhen(BeepWhen.values[preset.beepWhen.clamp(0, BeepWhen.values.length - 1)]);
      if (!hr.running) {
        await hr.start();
        _hrStartedByRun = true;
      }
    }
    _hookAlerts();
    _planId = row.planId;
    final planRow = row.planId == null ? null : await plans?.call(row.planId!);
    if (planRow != null) {
      // Catch up with the steps already run (from the route).
      final runner = PlanRunner(PlanSpec.fromJson(planRow.specJson));
      final (:dist, :time) = cumulativeProfile(
        _route.map((p) => (time: p.time, lat: p.lat, lon: p.lon, accuracy: p.accuracy, segment: p.segment)),
      );
      for (var i = 0; i < dist.length; i++) {
        runner.update(dist[i], time[i]);
      }
      plan = runner;
      _planName = planRow.name;
    }
    if (!paused) await _startSteps();
    if (!paused) _listen();
    _liveStart();
    notifyListeners();
  }

  /// Saves everything not yet saved (called every few seconds and when the
  /// app goes to the background).
  Future<void> flush() async {
    if (!active) return;
    _sinceSave = 0;
    _scheduleIdleReminder();
    await _savePoints();
    await _saveRun();
  }

  /// Heart-rate beeps during a run are also said out loud.
  void _hookAlerts() {
    _paceEngine.reset();
    hr.onAlert = (alert, bpm) => voice?.heartRateAlert(high: alert == ZoneAlert.high, bpm: bpm);
  }

  /// "Run", "Walk", "Hike" or "Ride" – what is recording now.
  String get activityWord => _word(_chosen);

  static String _word(RunActivity a) => switch (a) {
    RunActivity.run => 'Run',
    RunActivity.walk => 'Walk',
    RunActivity.hike => 'Hike',
    RunActivity.ride => 'Ride',
  };

  /// The heart-rate range for walking or running (null = none).
  HrRange? _rangeFor(Gait g) {
    final w = walkPreset;
    if (g == Gait.walk && w != null) return HrRange(min: w.minBpm, max: w.maxBpm);
    return _runRange;
  }

  /// Walking or running now, from the pace over the last 30 s and the steps
  /// per minute; switches after [gaitSwitchAfter] of the other.
  void _updateGait(double? pace) {
    if (!autoDetect || paused || riding) return;
    final g = classifyGait(paceS: pace, cadence: cadence);
    if (g == Gait.still || g == _liveGait) {
      if (g == _liveGait) _gaitCandidate = null;
      return;
    }
    if (_gaitCandidate != g) {
      _gaitCandidate = g;
      _gaitCandidateSince = now();
      return;
    }
    if (now().difference(_gaitCandidateSince!) < gaitSwitchAfter) return;
    _gaitCandidate = null;
    _liveGait = g;
    _paceEngine.reset();
    final range = _rangeFor(g);
    if (range != null && walkPreset != null) hr.setRange(range);
    voice?.gaitChanged(walking: g == Gait.walk);
    notifyListeners();
  }

  void _checkPace(double? pace) {
    if (riding) {
      final min = rideSpeedAlert;
      _checkPaceRange(min == null || min <= 0 ? null : HrRange(min: 1, max: (1000 / min).round()), pace);
      return;
    }
    if (_liveGait == Gait.walk) {
      final slowest = walkPaceAlert;
      // walking: only "too slow" (slower than the walk pace), never "speed up" to a running pace
      _checkPaceRange(slowest == null ? null : HrRange(min: 1, max: slowest), pace);
      return;
    }
    _checkPaceRange(paceAlert, pace, running: true);
  }

  /// Pace over the last 10 s (s/km; null if unknown) – reacts faster than
  /// the 30 s pace, so slowing down to a walk shows at once.
  double? get _shortPace {
    if (_recent.length < 2) return null;
    final last = _recent.last;
    final from = _recent.lastWhere(
      (r) => last.$1.difference(r.$1) >= const Duration(seconds: 10),
      orElse: () => _recent.first,
    );
    final secs = last.$1.difference(from.$1).inMilliseconds / 1000;
    final m = last.$2 - from.$2;
    if (secs < 5) return null;
    return m < 1 ? double.infinity : secs / m * 1000;
  }

  void _checkPaceRange(HrRange? range, double? pace, {bool running = false}) {
    if (range == null || pace == null || paused) return;
    _paceEngine.range = range;
    final alert = _paceEngine.onReading(pace.round(), now());
    if (alert == null) return;
    // More seconds per km = slower.
    final tooSlow = alert == ZoneAlert.high;
    final short = _shortPace;
    if (tooSlow && running && autoDetect && (_gaitCandidate == Gait.walk || (short != null && short > runPaceS))) {
      return; // slowing down to a walk – no "speed up"
    }
    hr.beeper.play(tooSlow ? SoundEvent.paceSlow : SoundEvent.paceFast);
    if (riding) {
      voice?.speedAlert(pace);
    } else {
      voice?.paceAlert(tooFast: !tooSlow, pace: pace);
    }
  }

  /// Moves the "Still running?" notification to 20 min after the last
  /// movement (30 min after a pause). Called on every save.
  void _scheduleIdleReminder() {
    final n = notifier;
    if (n == null || !active) return;
    final from = _pausedAt == null ? _lastMoveAt : (_snoozedAt ?? _pausedAt);
    if (from == null || (_treadmill && _pausedAt == null)) return;
    final at = from.add(_pausedAt != null ? pausedIdleAfter : idleAfter);
    if (at == _idleScheduledAt) return;
    _idleScheduledAt = at;
    final after = at.difference(now());
    n.scheduleRunIdle(after.isNegative ? const Duration(seconds: 5) : after, paused: _pausedAt != null);
  }

  /// "Keep going" on the reminder: count from now.
  Future<void> keepGoing() async {
    if (!active) return;
    if (_pausedAt == null) {
      _lastMoveAt = now();
    } else {
      _snoozedAt = now();
    }
    _idleScheduledAt = null;
    _scheduleIdleReminder();
    notifyListeners();
  }

  /// Distance again from the route in memory (after dropping its end).
  void _replayDistance() {
    _tracker
      ..distanceM = 0
      ..newSegment();
    int? seg;
    for (final p in _route) {
      if (p.segment != seg) _tracker.newSegment();
      seg = p.segment;
      _tracker.add(GeoFix(time: p.time, lat: p.lat, lon: p.lon, accuracy: p.accuracy));
    }
  }

  void _listen() {
    _gps?.cancel();
    if (!_treadmill) _gps = location.start().listen(_onFix);
    // Outdoors GPS keeps the app running with the screen locked; a treadmill
    // run has no GPS, so it holds the audio session instead (otherwise iOS
    // would freeze the clock, timed steps and voice updates when locked).
    if (_treadmill) hr.beeper.start('run');
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      ticks.value++;
      _paceEngine.tick(now());
      _advancePlan(); // time-based steps (and treadmill runs)
      if (_treadmill && ticks.value % 5 == 0) _updateGait(null); // steps only, no GPS pace
      if (ticks.value % 5 == 0) _readSteps();
      _sampleBike();
      _checkAutoPause();
      _pushLive();
      if (++_sinceSave >= saveEvery) flush();
    });
  }

  Future<void> _stopGps() async {
    _ticker?.cancel();
    _ticker = null;
    await _gps?.cancel();
    _gps = null;
    if (!_treadmill) await location.stop();
    if (_treadmill) hr.beeper.stop('run', const Duration(seconds: 8)); // let "Run complete…" finish
  }

  void _onFix(GeoFix fix) {
    if (!active) return;
    if (paused) {
      if (_autoPaused) _whileAutoPaused(fix);
      return;
    }
    if (!DistanceTracker.usable(fix)) return;
    final wasGood = gps == GpsStatus.good;
    _lastGoodAt = now();
    _tracker.add(fix);
    if (fix.altitude != null) _gpsAlt = fix.altitude;
    _route.add(
      RoutePoint(
        time: fix.time,
        lat: fix.lat,
        lon: fix.lon,
        accuracy: fix.accuracy,
        altitude: _hasBaro ? _baroAlt : fix.altitude,
        segment: _segment,
        hr: hr.running ? hr.bpm : null,
        cadence: cadence?.round(),
      ),
    );
    if (_tracker.distanceM - _moveMark >= 30) {
      _moveMark = _tracker.distanceM;
      _lastMoveAt = now();
    }
    _recent.add((fix.time, _tracker.distanceM));
    while (_recent.length > 2 && fix.time.difference(_recent.first.$1) > paceWindow) {
      _recent.removeAt(0);
    }
    ticks.value++;
    final pace = currentPace;
    voice?.progress(
      distanceM,
      moving,
      bpm: hr.running ? hr.bpm : null,
      currentPace: pace,
      cadence: cadence,
      ghostDelta: ghostDelta,
      steps: steps,
    );
    _updateGait(pace);
    final short = _shortPace;
    if (short != null && short.isFinite && short > 0) {
      final v = 1000 / short;
      if (v <= maxPlausibleSpeedMs && (_maxSpeedMs == null || v > _maxSpeedMs!)) _maxSpeedMs = v;
    }
    _checkPace(pace);
    _advancePlan();
    if (!wasGood) notifyListeners();
  }

  /// Below this speed for [autoPauseAfter] a ride pauses by itself; it goes
  /// on above [autoResumeAboveMs].
  static const autoPauseAfter = Duration(seconds: 5);
  static const autoPauseBelowMs = 3 / 3.6;
  static const autoResumeAboveMs = 5 / 3.6;

  @visibleForTesting
  void checkAutoPauseForTest() => _checkAutoPause();

  void _checkAutoPause() {
    final s = _startedAt;
    if (!active || paused || _treadmill || !riding || !autoPauseRide || s == null) return;
    final t = now();
    // only with a fresh GPS fix (no fixes = no signal, not standing still)
    final good = _lastGoodAt;
    if (good == null || t.difference(good) > const Duration(seconds: 3)) return;
    if (t.difference(_resumedAt ?? s) < autoPauseAfter * 2) return;
    final before = t.subtract(autoPauseAfter);
    (DateTime, double)? then;
    for (final r in _recent) {
      if (r.$1.isAfter(before)) break;
      then = r;
    }
    if (then == null) return;
    if (distanceM - then.$2 > autoPauseAfter.inSeconds * autoPauseBelowMs) return;
    _autoPaused = true;
    _pausedAt = then.$1.isAfter(_resumedAt ?? s) ? then.$1 : t;
    _tracker.newSegment();
    _recent.clear();
    _still.clear();
    _segment++;
    voice?.autoPaused();
    _pushLive(now: true);
    flush();
    notifyListeners();
  }

  void _whileAutoPaused(GeoFix fix) {
    if (!DistanceTracker.usable(fix)) return;
    _lastGoodAt = now();
    _still.add(fix);
    while (_still.length > 2 && fix.time.difference(_still[1].time) > const Duration(seconds: 20)) {
      _still.removeAt(1); // keep the first (where you stopped)
    }
    GeoFix? from;
    for (final f in _still) {
      if (fix.time.difference(f.time) < const Duration(seconds: 3)) break;
      from = f;
    }
    if (from == null) return;
    final dt = fix.time.difference(from.time).inMilliseconds / 1000;
    final fast = geoDistanceM(from.lat, from.lon, fix.lat, fix.lon) / dt >= autoResumeAboveMs;
    final away = geoDistanceM(_still.first.lat, _still.first.lon, fix.lat, fix.lon) >= 15;
    if (!fast || !away) return;
    _autoResume(from: from, to: fix);
  }

  Future<void> _autoResume({GeoFix? from, GeoFix? to}) async {
    final p = _pausedAt;
    if (p == null) return;
    _pausedMs += now().difference(p).inMilliseconds;
    _pausedAt = null;
    _autoPaused = false;
    _resumedAt = now();
    _lastMoveAt = now();
    _snoozedAt = null;
    _still.clear();
    voice?.resumed();
    // the stretch since moving off counts in the new segment
    if (from != null) _onFix(from);
    if (to != null) _onFix(to);
    _pushLive(now: true);
    notifyListeners();
    await flush();
  }

  Future<void> _savePoints() async {
    final id = _id;
    if (id == null || _saved >= _route.length) return;
    final batch = _route.sublist(_saved);
    _saved = _route.length;
    await runs.addPoints([
      for (final p in batch)
        RunPointsCompanion.insert(
          runId: id,
          time: p.time,
          lat: p.lat,
          lon: p.lon,
          accuracy: Value(p.accuracy),
          altitude: Value(p.altitude),
          segment: Value(p.segment),
          hr: Value(p.hr),
          cadence: Value(p.cadence),
        ),
    ]);
  }

  Future<void> _saveRun({DateTime? endedAt, int? avgHr, int? maxHr, Map<int, double>? bests, String? laps}) async {
    final id = _id, start = _startedAt;
    if (id == null || start == null) return;
    // A save every few seconds must never land after Finish wrote the end
    // (the run would open as "still running" next time).
    if (endedAt == null && _finishing) return;
    await runs.saveRun(
      RunsCompanion.insert(
        id: Value(id),
        startedAt: start,
        endedAt: Value(endedAt),
        pausedAt: Value(endedAt == null ? _pausedAt : null),
        pausedS: Value((_pausedMs / 1000).round()),
        durationS: Value(moving.inSeconds),
        distanceM: Value(distanceM),
        hrPresetId: Value(_presetId),
        avgHr: Value(avgHr),
        maxHr: Value(maxHr),
        bestsJson: Value(bests == null ? null : encodeBests(bests)),
        kind: Value(_treadmill ? RunKind.treadmill : RunKind.outdoor),
        shoeId: Value(_shoeId),
        planId: Value(_planId),
        lapsJson: Value(laps),
        steps: Value(steps),
        avgCadence: Value(_avgCadence()),
        elevGainM: Value(_hasBaro ? _gainM : null),
        elevLossM: Value(_hasBaro ? _lossM : null),
        maxSpeedMs: Value(_maxSpeedMs),
        avgPowerW: Value(avgPowerW),
        maxPowerW: Value(_maxPowerW),
        // while recording: what was picked (so a restart keeps it); at the end: the decision
        activity: Value(endedAt == null ? _chosen : _activity),
        walkedM: Value(_walkedM),
        updatedAt: Value(now()),
      ),
    );
  }

  int? _avgCadence() {
    // rides: pedal turns per minute from the bike's sensor (steps mean nothing on a bike)
    if (riding) return _bikeCadN == 0 ? null : (_bikeCadSum / _bikeCadN).round();
    final st = steps, mins = moving.inMilliseconds / 60000;
    return st == null || st == 0 || mins < 0.5 ? null : (st / mins).round();
  }

  void _reset() {
    _id = null;
    _startedAt = null;
    _pausedAt = null;
    _autoPaused = false;
    _resumedAt = null;
    _still.clear();
    _pausedMs = 0;
    _presetId = null;
    _shoeId = null;
    ghost = null;
    plan = null;
    _planId = null;
    _planName = null;
    _stepsBefore = 0;
    _steps = 0;
    _counting = false;
    _baroBase = null;
    _baroAlt = null;
    _gpsAlt = null;
    _gainM = 0;
    _lossM = 0;
    _elevRef = null;
    _hasBaro = false;
    _cadence = null;
    _stepSamples.clear();
    _segment = 0;
    _tracker
      ..distanceM = 0
      ..newSegment();
    _route.clear();
    _saved = 0;
    _recent.clear();
    _lastGoodAt = null;
    _hrStartedByRun = false;
    _sinceSave = 0;
    _treadmill = false;
    _chosen = RunActivity.run;
    _liveGait = Gait.run;
    _gaitCandidate = null;
    _runRange = null;
    _maxSpeedMs = null;
    _riderKg = null;
    _powerSum = 0;
    _powerN = 0;
    _maxPowerW = null;
    _bikeCadSum = 0;
    _bikeCadN = 0;
    _lastBikeSample = null;
    _activity = RunActivity.run;
    _walkedM = null;
    _lastMoveAt = null;
    _moveMark = 0;
    _idleScheduledAt = null;
    _snoozedAt = null;
    _endOverride = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _gps?.cancel();
    location.stop();
    ticks.dispose();
    super.dispose();
  }
}
