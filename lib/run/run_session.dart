import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../data/database.dart';
import '../data/run_repository.dart';
import '../hr/hr_monitor.dart';
import '../beep/sounds.dart';
import '../hr/zone_alert_engine.dart';
import '../hr/zones.dart';
import '../notify/rest_notifier.dart';
import 'best_efforts.dart';
import 'geo.dart';
import 'location_source.dart';
import 'motion_source.dart';
import 'run_plan.dart';
import 'run_voice.dart';

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
  });

  final DateTime time;
  final double lat;
  final double lon;
  final double? accuracy;
  final double? altitude;
  final int segment;
  final int? hr;
}

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
    _counting = await motion.start();
  }

  /// Reads the step counter (every few seconds and before saving).
  Future<void> _readSteps() async {
    if (!_counting) return;
    final r = await motion.read();
    if (r == null) return;
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

  /// "Still running?" notification (set by AppServices).
  RestNotifier? notifier;

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

  /// Pace over the last 30 s (s/km); null when standing still or no GPS.
  double? get currentPace {
    if (paused || _recent.length < 2) return null;
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
    _planId = plan?.id;
    this.plan = plan == null ? null : PlanRunner(PlanSpec.fromJson(plan.specJson));
    _lastMoveAt = _startedAt;
    _presetId = preset?.id;
    hr.resetSession();
    if (preset != null) {
      hr.setRange(HrRange(min: preset.minBpm, max: preset.maxBpm));
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
    notifyListeners();
    return access;
  }

  Future<void> pause() async {
    if (!active || paused) return;
    _pausedAt = now();
    await _stopGps();
    await _stopSteps();
    _tracker.newSegment();
    _recent.clear();
    _segment++;
    voice?.paused();
    await flush();
    notifyListeners();
  }

  Future<void> resume() async {
    final p = _pausedAt;
    if (!active || p == null) return;
    _pausedMs += now().difference(p).inMilliseconds;
    _pausedAt = null;
    _lastGoodAt = null;
    _lastMoveAt = now();
    _snoozedAt = null;
    voice?.resumed();
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
            );
      // Faster than every earlier run (the first run at a distance isn't a record).
      final before = await runs.records(before: _startedAt, excludeId: id);
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
    if (_hrStartedByRun) await hr.stop();
    hr.onAlert = null;
    await notifier?.cancelRunIdle();
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
    _treadmill = row.kind == RunKind.treadmill;
    _shoeId = row.shoeId;
    _stepsBefore = row.steps ?? 0;
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
        ),
      );
    }
    _saved = _route.length;
    // The app was closed: don't draw a line across the gap.
    _segment = segment + 1;
    _tracker.newSegment();
    _lastMoveAt = _route.isEmpty ? row.startedAt : _route.last.time;
    _moveMark = distanceM;
    voice?.restored(distanceM, moving);
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
    }
    if (!paused) await _startSteps();
    if (!paused) _listen();
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

  void _checkPace(double? pace) {
    final range = paceAlert;
    if (range == null || pace == null || paused) return;
    _paceEngine.range = range;
    final alert = _paceEngine.onReading(pace.round(), now());
    if (alert == null) return;
    // More seconds per km = slower.
    final tooSlow = alert == ZoneAlert.high;
    hr.beeper.play(tooSlow ? SoundEvent.paceSlow : SoundEvent.paceFast);
    voice?.paceAlert(tooFast: !tooSlow, pace: pace);
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
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      ticks.value++;
      _paceEngine.tick(now());
      _advancePlan(); // time-based steps (and treadmill runs)
      if (ticks.value % 5 == 0) _readSteps();
      if (++_sinceSave >= saveEvery) flush();
    });
  }

  Future<void> _stopGps() async {
    _ticker?.cancel();
    _ticker = null;
    await _gps?.cancel();
    _gps = null;
    if (!_treadmill) await location.stop();
  }

  void _onFix(GeoFix fix) {
    if (!active || paused) return;
    if (!DistanceTracker.usable(fix)) return;
    final wasGood = gps == GpsStatus.good;
    _lastGoodAt = now();
    _tracker.add(fix);
    _route.add(
      RoutePoint(
        time: fix.time,
        lat: fix.lat,
        lon: fix.lon,
        accuracy: fix.accuracy,
        altitude: fix.altitude,
        segment: _segment,
        hr: hr.running ? hr.bpm : null,
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
    );
    _checkPace(pace);
    _advancePlan();
    if (!wasGood) notifyListeners();
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
        ),
    ]);
  }

  Future<void> _saveRun({DateTime? endedAt, int? avgHr, int? maxHr, Map<int, double>? bests, String? laps}) async {
    final id = _id, start = _startedAt;
    if (id == null || start == null) return;
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
        updatedAt: Value(now()),
      ),
    );
  }

  int? _avgCadence() {
    final st = steps, mins = moving.inMilliseconds / 60000;
    return st == null || st == 0 || mins < 0.5 ? null : (st / mins).round();
  }

  void _reset() {
    _id = null;
    _startedAt = null;
    _pausedAt = null;
    _pausedMs = 0;
    _presetId = null;
    _shoeId = null;
    ghost = null;
    plan = null;
    _planId = null;
    _stepsBefore = 0;
    _steps = 0;
    _counting = false;
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
