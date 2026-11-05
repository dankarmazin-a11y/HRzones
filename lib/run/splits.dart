import 'geo.dart';

/// One kilometre of a run (the last one may be shorter).
class KmSplit {
  const KmSplit({required this.km, required this.distanceM, required this.seconds, this.avgHr});

  /// 1, 2, 3…
  final int km;

  /// 1000, or less for the last, unfinished kilometre.
  final double distanceM;

  /// Moving time for this kilometre (pauses don't count).
  final double seconds;
  final int? avgHr;

  bool get partial => distanceM < 999.5;

  /// Seconds per km.
  double? get pace => paceSecPerKm(distanceM, seconds);
}

/// A recorded GPS point as needed for splits.
typedef SplitPoint = ({DateTime time, double lat, double lon, double? accuracy, int segment, int? hr});

/// Kilometre splits from the route. Uses the same distance filter as the
/// live run, so the splits add up to the run's distance. Time between two
/// points of the same segment counts; a pause (new segment) doesn't.
/// A last piece shorter than [minPartialM] is left out.
List<KmSplit> computeSplits(Iterable<SplitPoint> points, {double minPartialM = 50}) {
  final tracker = DistanceTracker();
  final out = <KmSplit>[];
  var dist = 0.0, secs = 0.0;
  var hrSum = 0, hrCount = 0;
  SplitPoint? prev;

  void close(double metres, double seconds) {
    out.add(
      KmSplit(
        km: out.length + 1,
        distanceM: metres,
        seconds: seconds,
        avgHr: hrCount == 0 ? null : (hrSum / hrCount).round(),
      ),
    );
    hrSum = 0;
    hrCount = 0;
  }

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
    if (p.hr != null) {
      hrSum += p.hr!;
      hrCount++;
    }
    dist += add;
    secs += dt < 0 ? 0 : dt;
    while (dist >= 1000) {
      final over = dist - 1000;
      // The part of this step beyond the km mark belongs to the next km.
      final overTime = add > 0 ? dt * (over / add).clamp(0, 1) : 0.0;
      close(1000, secs - overTime);
      dist = over;
      secs = overTime;
    }
  }
  if (dist >= minPartialM) close(dist, secs);
  return out;
}
