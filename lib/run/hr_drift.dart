import 'geo.dart';
import 'route_zones.dart';

/// Heart-rate drift ("cardiac drift", owner's idea 7, 19 Nov): on a steady
/// outing the heart rate creeps up for the same speed – heat, tiredness or
/// too little water. Measured like runners' "aerobic decoupling": speed per
/// heartbeat in the first half vs the second half of the moving time.
/// Positive = the heart worked harder later. Null when too short (< 20 min)
/// or without heart rate.
double? hrDriftPercent(List<HrPoint> points, {double minSeconds = 1200}) {
  // Same distance filter as the live run and the splits; pauses don't count.
  final steps = <({double dm, double dt, int? hr})>[];
  final tracker = DistanceTracker();
  HrPoint? prev;
  for (final p in points) {
    final fix = GeoFix(time: p.time, lat: p.lat, lon: p.lon);
    if (!DistanceTracker.usable(fix)) continue;
    if (prev == null || prev.segment != p.segment) {
      tracker.newSegment();
      tracker.add(fix);
      prev = p;
      continue;
    }
    final dt = p.time.difference(prev.time).inMilliseconds / 1000;
    prev = p;
    steps.add((dm: tracker.add(fix), dt: dt < 0 ? 0 : dt, hr: p.hr));
  }
  final total = steps.fold(0.0, (a, s) => a + s.dt);
  if (total < minSeconds) return null;
  double d1 = 0, t1 = 0, h1 = 0, d2 = 0, t2 = 0, h2 = 0, at = 0;
  var n1 = 0, n2 = 0;
  for (final s in steps) {
    at += s.dt;
    if (at <= total / 2) {
      d1 += s.dm;
      t1 += s.dt;
      if (s.hr != null) {
        h1 += s.hr!;
        n1++;
      }
    } else {
      d2 += s.dm;
      t2 += s.dt;
      if (s.hr != null) {
        h2 += s.hr!;
        n2++;
      }
    }
  }
  if (n1 < 5 || n2 < 5 || t1 <= 0 || t2 <= 0 || d1 <= 0 || d2 <= 0) return null;
  final ef1 = (d1 / t1) / (h1 / n1), ef2 = (d2 / t2) / (h2 / n2);
  return (ef1 / ef2 - 1) * 100;
}

/// A word for the drift: under 5 % steady, 5–10 % some, above that a lot.
String hrDriftWord(double pct) => pct < 5
    ? 'steady'
    : pct < 10
    ? 'some drift'
    : 'a lot of drift';

/// Live check during an outing (owner's idea 7): the heart rate went up 8 %
/// or more at about the same speed (±7 %) compared with minutes 5–15.
class DriftWatch {
  /// One sample a second while moving: (moving seconds, metres, bpm).
  final _samples = <({double t, double m, int bpm})>[];
  bool alerted = false;

  static const baselineFrom = 300.0, baselineTo = 900.0, window = 600.0, minMoving = 1200.0;

  void add(double movingS, double metres, int bpm) => _samples.add((t: movingS, m: metres, bpm: bpm));

  void reset() {
    _samples.clear();
    alerted = false;
  }

  /// Heart-rate rise in % at the same speed, once it is worth saying (null
  /// otherwise). Says it only once per outing.
  double? check() {
    if (alerted || _samples.isEmpty || _samples.last.t < minMoving) return null;
    final base = _window(baselineFrom, baselineTo);
    final now = _window(_samples.last.t - window, _samples.last.t);
    if (base == null || now == null) return null;
    final speedChange = (now.speed - base.speed).abs() / base.speed;
    final rise = (now.hr / base.hr - 1) * 100;
    if (speedChange <= 0.07 && rise >= 8) {
      alerted = true;
      return rise;
    }
    return null;
  }

  ({double speed, double hr})? _window(double from, double to) {
    final w = _samples.where((s) => s.t >= from && s.t <= to).toList();
    if (w.length < 60) return null;
    final dt = w.last.t - w.first.t, dm = w.last.m - w.first.m;
    if (dt <= 0 || dm <= 0) return null;
    return (speed: dm / dt, hr: w.map((s) => s.bpm).reduce((a, b) => a + b) / w.length);
  }
}
