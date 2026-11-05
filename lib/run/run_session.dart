import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../data/run_repository.dart';
import '../hr/hr_monitor.dart';
import '../hr/zones.dart';
import 'geo.dart';
import 'location_source.dart';

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
  RunSession({required this.runs, required this.hr, LocationSource? location, DateTime Function()? clock})
    : location = location ?? LocationSource.create(),
      now = clock ?? DateTime.now;

  final RunRepository runs;
  final HrMonitor hr;
  LocationSource location;
  final DateTime Function() now;

  /// Changes every second while recording and on every GPS fix: the live
  /// numbers listen to this, the rest of the screen to the session itself.
  final ticks = ValueNotifier<int>(0);

  String? _id;
  DateTime? _startedAt;
  DateTime? _pausedAt;
  int _pausedMs = 0;
  String? _presetId;
  int _segment = 0;
  final _tracker = DistanceTracker();
  final _route = <RoutePoint>[];
  int _saved = 0;

  /// (time, total distance) of recent fixes, for the current pace.
  final _recent = <(DateTime, double)>[];
  DateTime? _lastGoodAt;
  bool _hrStartedByRun = false;
  StreamSubscription<GeoFix>? _gps;
  Timer? _ticker;
  int _sinceSave = 0;
  bool _finishing = false;

  /// Seconds between saves while recording (points are also saved when the
  /// app goes to the background).
  static const saveEvery = 10;

  /// How far back the current pace looks.
  static const paceWindow = Duration(seconds: 30);

  bool get active => _id != null;
  bool get paused => _pausedAt != null;
  String? get runId => _id;
  DateTime? get startedAt => _startedAt;
  String? get presetId => _presetId;
  List<RoutePoint> get route => List.unmodifiable(_route);
  double get distanceM => _tracker.distanceM;

  Duration get moving {
    final s = _startedAt;
    if (s == null) return Duration.zero;
    final ms = (_pausedAt ?? now()).difference(s).inMilliseconds - _pausedMs;
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
    if (!active || paused) return GpsStatus.off;
    final last = _lastGoodAt;
    if (last == null) return GpsStatus.searching;
    return now().difference(last) > const Duration(seconds: 10) ? GpsStatus.weak : GpsStatus.good;
  }

  /// Starts recording. Asks for location permission first; returns what the
  /// phone answered (only [LocationAccess.granted] starts a run).
  Future<LocationAccess> start({HrPreset? preset}) async {
    if (active) return LocationAccess.granted;
    final access = await location.ensureAccess();
    if (access != LocationAccess.granted) return access;
    _reset();
    _id = newId();
    _startedAt = now();
    _presetId = preset?.id;
    hr.resetSession();
    if (preset != null) {
      hr.setRange(HrRange(min: preset.minBpm, max: preset.maxBpm));
      if (!hr.running) {
        await hr.start();
        _hrStartedByRun = true;
      }
    }
    await _saveRun();
    _listen();
    notifyListeners();
    return access;
  }

  Future<void> pause() async {
    if (!active || paused) return;
    _pausedAt = now();
    await _stopGps();
    _tracker.newSegment();
    _recent.clear();
    _segment++;
    await flush();
    notifyListeners();
  }

  Future<void> resume() async {
    final p = _pausedAt;
    if (!active || p == null) return;
    _pausedMs += now().difference(p).inMilliseconds;
    _pausedAt = null;
    _lastGoodAt = null;
    await flush();
    _listen();
    notifyListeners();
  }

  /// Ends the run and saves it; returns its id (null if no run).
  Future<String?> finish() async {
    final id = _id;
    if (id == null || _finishing) return null;
    _finishing = true;
    try {
      await _stopGps();
      final end = _pausedAt ?? now();
      await _savePoints();
      await _saveRun(endedAt: end, avgHr: hr.sessionAvg, maxHr: hr.sessionMax);
      if (_hrStartedByRun) await hr.stop();
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
    if (_hrStartedByRun) await hr.stop();
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
    if (!paused) _listen();
    notifyListeners();
  }

  /// Saves everything not yet saved (called every few seconds and when the
  /// app goes to the background).
  Future<void> flush() async {
    if (!active) return;
    _sinceSave = 0;
    await _savePoints();
    await _saveRun();
  }

  void _listen() {
    _gps?.cancel();
    _gps = location.start().listen(_onFix);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      ticks.value++;
      if (++_sinceSave >= saveEvery) flush();
    });
  }

  Future<void> _stopGps() async {
    _ticker?.cancel();
    _ticker = null;
    await _gps?.cancel();
    _gps = null;
    await location.stop();
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
    _recent.add((fix.time, _tracker.distanceM));
    while (_recent.length > 2 && fix.time.difference(_recent.first.$1) > paceWindow) {
      _recent.removeAt(0);
    }
    ticks.value++;
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

  Future<void> _saveRun({DateTime? endedAt, int? avgHr, int? maxHr}) async {
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
        updatedAt: Value(now()),
      ),
    );
  }

  void _reset() {
    _id = null;
    _startedAt = null;
    _pausedAt = null;
    _pausedMs = 0;
    _presetId = null;
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
