import 'geo.dart';

/// Distances with running records.
const recordDistances = <int, String>{1000: '1 km', 5000: '5 km', 10000: '10 km', 21097: 'Half marathon'};

/// A recorded point as needed for best efforts.
typedef EffortPoint = ({DateTime time, double lat, double lon, double? accuracy, int segment});

/// Fastest time (seconds) for each of [distances] anywhere inside the run –
/// e.g. the best 1 km of a 5 km run, not only the first km. Same distance
/// filter as the live run; pauses don't count. Distances longer than the run
/// are left out.
Map<int, double> bestEfforts(
  Iterable<EffortPoint> points, {
  Iterable<int> distances = const [1000, 5000, 10000, 21097],
}) {
  // Cumulative distance and moving time at each usable point.
  final dist = <double>[0], time = <double>[0];
  final tracker = DistanceTracker();
  EffortPoint? prev;
  for (final p in points) {
    final fix = GeoFix(time: p.time, lat: p.lat, lon: p.lon, accuracy: p.accuracy);
    if (!DistanceTracker.usable(fix)) continue;
    if (prev == null || prev.segment != p.segment) {
      tracker.newSegment();
      tracker.add(fix);
      prev = p;
      continue;
    }
    final dt = p.time.difference(prev.time).inMilliseconds / 1000;
    prev = p;
    final add = tracker.add(fix);
    if (add <= 0 && dt <= 0) continue;
    dist.add(dist.last + add);
    time.add(time.last + (dt < 0 ? 0 : dt));
  }
  final out = <int, double>{};
  for (final target in distances) {
    if (dist.last + 0.5 < target) continue;
    double? best;
    var i = 0;
    for (var j = 1; j < dist.length; j++) {
      final startAt = dist[j] - target; // where a window ending at j must start
      if (startAt < -0.5) continue;
      while (i + 1 < j && dist[i + 1] <= startAt) {
        i++;
      }
      // Time at distance `startAt`, between points i and i+1.
      final d0 = dist[i], d1 = dist[i + 1];
      final f = d1 > d0 ? ((startAt - d0) / (d1 - d0)).clamp(0.0, 1.0) : 0.0;
      final tStart = time[i] + (time[i + 1] - time[i]) * f;
      final t = time[j] - tStart;
      if (t > 0 && (best == null || t < best)) best = t;
    }
    if (best != null) out[target] = best;
  }
  return out;
}
