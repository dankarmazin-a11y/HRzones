import 'geo.dart';

/// One kilometre (or mile) of a run (the last one may be shorter).
class KmSplit {
  const KmSplit({required this.km, required this.distanceM, required this.seconds, this.avgHr, this.lengthM = 1000});

  /// 1, 2, 3…
  final int km;

  /// [lengthM], or less for the last, unfinished piece.
  final double distanceM;

  /// 1000 for km splits, 1609.344 for mile splits.
  final double lengthM;

  /// Moving time for this kilometre (pauses don't count).
  final double seconds;
  final int? avgHr;

  bool get partial => distanceM < lengthM - 0.5;

  /// Seconds per km.
  double? get pace => paceSecPerKm(distanceM, seconds);
}

/// A recorded GPS point as needed for splits.
typedef SplitPoint = ({DateTime time, double lat, double lon, double? accuracy, int segment, int? hr});

/// Kilometre splits from the route. Uses the same distance filter as the
/// live run, so the splits add up to the run's distance. Time between two
/// points of the same segment counts; a pause (new segment) doesn't.
/// A last piece shorter than [minPartialM] is left out.
/// [splitM] is the split length: 1000 (km) or 1609.344 (miles).
List<KmSplit> computeSplits(Iterable<SplitPoint> points, {double minPartialM = 50, double splitM = 1000}) {
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
        lengthM: splitM,
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
    while (dist >= splitM) {
      final over = dist - splitM;
      // The part of this step beyond the km mark belongs to the next km.
      final overTime = add > 0 ? dt * (over / add).clamp(0, 1) : 0.0;
      close(splitM, secs - overTime);
      dist = over;
      secs = overTime;
    }
  }
  if (dist >= minPartialM) close(dist, secs);
  return out;
}
