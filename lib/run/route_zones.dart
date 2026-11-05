import '../hr/zones.dart';

/// A recorded point with its heart rate (for zones on the route).
typedef HrPoint = ({DateTime time, double lat, double lon, int segment, int? hr});

/// A piece of the route in one heart-rate zone (null = no heart rate / below
/// zone 1). Neighbouring pieces share their end point so the line is unbroken.
class ZonePiece {
  ZonePiece(this.zone, this.points);

  final int? zone;
  final List<({double lat, double lon})> points;
}

/// Splits the route into pieces of the same zone (never across a pause).
List<ZonePiece> zonePieces(List<HrPoint> points, HrZones zones) {
  final out = <ZonePiece>[];
  int? segment;
  for (final p in points) {
    final z = p.hr == null ? null : zones.zoneFor(p.hr!)?.number;
    final here = (lat: p.lat, lon: p.lon);
    if (out.isEmpty || p.segment != segment) {
      out.add(ZonePiece(z, [here]));
    } else if (out.last.zone != z) {
      // Start the new colour where the old one ended.
      out.last.points.add(here);
      out.add(ZonePiece(z, [here]));
    } else {
      out.last.points.add(here);
    }
    segment = p.segment;
  }
  return out;
}

/// Time spent in each zone (1–5, 0 = below zone 1), in seconds; time between
/// two points counts for the zone of the first. Pauses don't count.
Map<int, double> timeInZones(List<HrPoint> points, HrZones zones) {
  final out = <int, double>{};
  for (var i = 1; i < points.length; i++) {
    final a = points[i - 1], b = points[i];
    if (a.segment != b.segment || a.hr == null) continue;
    final dt = b.time.difference(a.time).inMilliseconds / 1000;
    if (dt <= 0 || dt > 30) continue; // a gap without GPS isn't counted
    final z = zones.zoneFor(a.hr!)?.number ?? 0;
    out[z] = (out[z] ?? 0) + dt;
  }
  return out;
}

/// Seconds below / inside / above a target range.
({double below, double inside, double above}) timeVsRange(List<HrPoint> points, HrRange range) {
  var below = 0.0, inside = 0.0, above = 0.0;
  for (var i = 1; i < points.length; i++) {
    final a = points[i - 1], b = points[i];
    if (a.segment != b.segment || a.hr == null) continue;
    final dt = b.time.difference(a.time).inMilliseconds / 1000;
    if (dt <= 0 || dt > 30) continue;
    if (a.hr! < range.min) {
      below += dt;
    } else if (a.hr! > range.max) {
      above += dt;
    } else {
      inside += dt;
    }
  }
  return (below: below, inside: inside, above: above);
}
