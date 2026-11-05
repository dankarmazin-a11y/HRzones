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
