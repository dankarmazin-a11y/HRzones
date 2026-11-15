/// Metres climbed and descended. GPS altitude is noisy: it is smoothed
/// (moving average over 5 points) and only changes of 3 m or more from the
/// last turning point count, so standing still doesn't add metres.
({double climb, double descent}) elevationGainLoss(List<double> altitudes, {double threshold = 3}) {
  if (altitudes.length < 2) return (climb: 0, descent: 0);
  final smooth = smoothAltitudes(altitudes);
  var climb = 0.0, descent = 0.0;
  var anchor = smooth.first;
  for (final a in smooth.skip(1)) {
    final d = a - anchor;
    if (d >= threshold) {
      climb += d;
      anchor = a;
    } else if (d <= -threshold) {
      descent -= d;
      anchor = a;
    }
  }
  return (climb: climb, descent: descent);
}

/// Moving average over [window] points (centred).
List<double> smoothAltitudes(List<double> a, {int window = 5}) {
  final half = window ~/ 2;
  return [
    for (var i = 0; i < a.length; i++)
      () {
        final from = (i - half).clamp(0, a.length - 1), to = (i + half).clamp(0, a.length - 1);
        var sum = 0.0;
        for (var j = from; j <= to; j++) {
          sum += a[j];
        }
        return sum / (to - from + 1);
      }(),
  ];
}

/// An outing that is mostly walking and climbs more than this per km is a hike.
const hikeClimbPerKm = 30.0;

/// Hike numbers from the route: the steepest stretch (% over at least
/// [windowM] metres) and the highest point above the start. [points] =
/// (distance along the route in metres, altitude in metres), in order.
({double steepestPct, double highestAboveStart}) hikeStats(List<(double, double)> points, {double windowM = 100}) {
  if (points.length < 2) return (steepestPct: 0, highestAboveStart: 0);
  final alt = smoothAltitudes([for (final p in points) p.$2]);
  var steepest = 0.0, highest = 0.0;
  var j = 0;
  for (var i = 0; i < points.length; i++) {
    highest = highest > alt[i] - alt.first ? highest : alt[i] - alt.first;
    while (j < i && points[i].$1 - points[j + 1].$1 >= windowM) {
      j++;
    }
    final run = points[i].$1 - points[j].$1;
    if (run >= windowM) {
      final pct = (alt[i] - alt[j]).abs() / run * 100;
      if (pct > steepest) steepest = pct;
    }
  }
  return (steepestPct: steepest, highestAboveStart: highest);
}
