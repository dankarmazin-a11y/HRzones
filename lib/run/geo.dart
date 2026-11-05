import 'dart:math' as math;

/// One GPS fix.
class GeoFix {
  const GeoFix({required this.time, required this.lat, required this.lon, this.accuracy, this.altitude, this.speed});

  final DateTime time;
  final double lat;
  final double lon;

  /// Horizontal accuracy radius in metres (null = unknown).
  final double? accuracy;
  final double? altitude;

  /// m/s as reported by the GPS (null = unknown).
  final double? speed;
}

/// Great-circle distance in metres.
double geoDistanceM(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLon = rad(lon2 - lon1);
  final a =
      math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.min(1, math.sqrt(a)));
}

/// Fixes worse than this are ignored (indoors / just started).
const maxAccuracyM = 30.0;

/// Faster than this between two fixes is a GPS jump, not running (43 km/h).
const maxSpeedMs = 12.0;

/// Smaller moves than this are GPS jitter while standing still.
const minStepM = 3.0;

/// Adds up the distance of a run from GPS fixes, ignoring inaccurate fixes,
/// jumps and jitter. Call [newSegment] after a pause so the gap isn't counted.
class DistanceTracker {
  double distanceM = 0;
  GeoFix? _anchor;
  GeoFix? _jump;

  /// Whether [fix] is accurate enough to use at all.
  static bool usable(GeoFix fix) => fix.accuracy == null || fix.accuracy! <= maxAccuracyM;

  /// Adds [fix]; returns the metres added (0 if ignored).
  double add(GeoFix fix) {
    if (!usable(fix)) return 0;
    final a = _anchor;
    if (a == null) {
      _anchor = fix;
      return 0;
    }
    final d = geoDistanceM(a.lat, a.lon, fix.lat, fix.lon);
    final seconds = fix.time.difference(a.time).inMilliseconds / 1000;
    if (seconds <= 0) return 0;
    if (d / seconds > maxSpeedMs) {
      // A jump. If the next fix agrees with it, the GPS really moved us
      // (e.g. it was wrong before): continue from there without counting it.
      final p = _jump;
      if (p != null && _plausible(p, fix)) {
        _anchor = fix;
        _jump = null;
      } else {
        _jump = fix;
      }
      return 0;
    }
    _jump = null;
    if (d < minStepM) return 0; // jitter – keep the old anchor
    _anchor = fix;
    distanceM += d;
    return d;
  }

  static bool _plausible(GeoFix a, GeoFix b) {
    final seconds = b.time.difference(a.time).inMilliseconds / 1000;
    return seconds > 0 && geoDistanceM(a.lat, a.lon, b.lat, b.lon) / seconds <= maxSpeedMs;
  }

  void newSegment() {
    _anchor = null;
    _jump = null;
  }
}

/// Pace in seconds per km for [metres] in [seconds] (null if too little).
double? paceSecPerKm(double metres, double seconds) => metres < 1 || seconds <= 0 ? null : seconds / metres * 1000;

/// "5:42" (min:sec per km), "–:––" when unknown.
String formatPace(double? secPerKm) {
  if (secPerKm == null || !secPerKm.isFinite || secPerKm > 60 * 60) return '–:––';
  final s = secPerKm.round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// "5.24" km with two decimals.
String formatKm(double metres) => (metres / 1000).toStringAsFixed(2);
