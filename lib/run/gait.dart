import 'geo.dart';

/// Walking or running at a moment of an outing (owner's limits, 2026-11-15):
/// - walking = pace slower than 9:00 /km and under 130 steps/min;
/// - running = pace faster than 8:00 /km or over 145 steps/min;
/// - in between the steps decide; without steps, pace 8:30 is the line.
/// Standing still (traffic light) is neither.
enum Gait { run, walk, still }

const walkPaceS = 540.0; // 9:00 /km
const runPaceS = 480.0; // 8:00 /km
const walkCadence = 130.0;
const runCadence = 145.0;

/// Slower than this (or no movement) with hardly any steps = standing still.
const stillPaceS = 1500.0; // 25:00 /km
const stillCadence = 40.0;

/// Share of the distance walked above which an outing is saved as a walk.
const walkShare = 0.8;

/// A walk or run part shorter than this is merged into its neighbours (a few
/// slow steps around a corner are not a walk break).
const minPieceS = 20.0;

/// [paceS] seconds per km over the last 30 s (null = not moving / unknown),
/// [cadence] steps per minute (null = no step counter).
Gait classifyGait({double? paceS, double? cadence}) {
  final stopped = (paceS == null || paceS > stillPaceS) && (cadence == null || cadence < stillCadence);
  if (stopped) return Gait.still;
  if (cadence != null && cadence > runCadence) return Gait.run;
  if (paceS != null && paceS < runPaceS) return Gait.run;
  if (cadence != null && cadence < walkCadence && (paceS == null || paceS > walkPaceS)) return Gait.walk;
  if (cadence != null) return cadence < (walkCadence + runCadence) / 2 ? Gait.walk : Gait.run;
  if (paceS == null) return Gait.still;
  return paceS >= (walkPaceS + runPaceS) / 2 ? Gait.walk : Gait.run;
}

/// One recorded point, as needed here.
typedef GaitPoint = ({DateTime time, double lat, double lon, double? accuracy, int segment, int? cadence});

/// A stretch of walking or running: points [from]..[to] (inclusive).
class GaitPiece {
  GaitPiece(this.gait, this.from, this.to, this.metres, this.seconds);
  final Gait gait;
  final int from;
  int to;
  double metres;
  double seconds;
}

class GaitSummary {
  const GaitSummary(
    this.pieces,
    this.walkedM,
    this.ranM,
    this.walkedS,
    this.ranS, [
    this.cum = const [],
    this.cumS = const [],
  ]);
  final List<GaitPiece> pieces;
  final double walkedM, ranM, walkedS, ranS;

  /// Distance at each point (same filter as the live run).
  final List<double> cum;

  /// Moving seconds at each point (pauses don't count).
  final List<double> cumS;

  /// Share of the moving time between [fromS] and [toS] seconds that was walked.
  double walkedShareBetween(double fromS, double toS) {
    if (cumS.length < 2 || toS <= fromS) return 0;
    final gaits = perPoint(cumS.length);
    var walk = 0.0, all = 0.0;
    for (var i = 1; i < cumS.length; i++) {
      final a = cumS[i - 1], b = cumS[i];
      final lo = a < fromS ? fromS : a, hi = b > toS ? toS : b;
      if (hi <= lo) continue;
      all += hi - lo;
      if (gaits[i] == Gait.walk) walk += hi - lo;
    }
    return all <= 0 ? 0 : walk / all;
  }

  /// Seconds per km while running / walking (null if none).
  double? get runPaceS => ranM < 50 ? null : ranS / ranM * 1000;
  double? get walkPaceS => walkedM < 50 ? null : walkedS / walkedM * 1000;

  /// Share of each split ([splitM] metres: km or mile) that was walked, 0–1.
  List<double> walkedPerSplit(double splitM) {
    if (cum.length < 2) return const [];
    final gaits = perPoint(cum.length);
    final walk = <double>[], all = <double>[];
    for (var i = 1; i < cum.length; i++) {
      final d = cum[i] - cum[i - 1];
      if (d <= 0) continue;
      final k = (cum[i - 1] / splitM).floor();
      while (all.length <= k) {
        all.add(0);
        walk.add(0);
      }
      all[k] += d;
      if (gaits[i] == Gait.walk) walk[k] += d;
    }
    return [for (var k = 0; k < all.length; k++) all[k] <= 0 ? 0.0 : walk[k] / all[k]];
  }

  double get totalM => walkedM + ranM;

  /// Walk breaks inside a run (walking pieces).
  int get walkBreaks => pieces.where((p) => p.gait == Gait.walk).length;

  /// Mostly walking → saved as a walk.
  bool get isWalk => totalM > 0 && walkedM / totalM > walkShare;

  /// Gait of each point (for colouring the route), same length as the input.
  List<Gait> perPoint(int n) {
    final out = List.filled(n, Gait.run);
    for (final p in pieces) {
      for (var i = p.from; i <= p.to && i < n; i++) {
        out[i] = p.gait;
      }
    }
    return out;
  }

  static const empty = GaitSummary([], 0, 0, 0, 0);
}

/// Splits an outing into walking and running parts: pace over the last 30 s
/// plus the steps per minute at each point. Distance uses the same filter as
/// the live run (so walked + ran = the run's distance); pauses don't count;
/// standing still joins the part before it.
GaitSummary analyzeGait(List<GaitPoint> pts) {
  if (pts.length < 2) return GaitSummary.empty;
  final tracker = DistanceTracker();
  final cum = <double>[]; // distance at each point
  var seg = pts.first.segment;
  for (final p in pts) {
    if (p.segment != seg) {
      seg = p.segment;
      tracker.newSegment();
    }
    tracker.add(GeoFix(time: p.time, lat: p.lat, lon: p.lon, accuracy: p.accuracy));
    cum.add(tracker.distanceM);
  }
  // gait per point from the last 30 s
  final gaits = <Gait>[];
  var start = 0;
  for (var i = 0; i < pts.length; i++) {
    while (start < i &&
        (pts[i].time.difference(pts[start].time).inSeconds > 30 || pts[start].segment != pts[i].segment)) {
      start++;
    }
    final secs = pts[i].time.difference(pts[start].time).inMilliseconds / 1000;
    final metres = cum[i] - cum[start];
    final pace = secs >= 10 && metres > 1 ? secs / metres * 1000 : null;
    final g = classifyGait(paceS: pace, cadence: pts[i].cadence?.toDouble());
    gaits.add(g == Gait.still ? (gaits.isEmpty ? Gait.run : gaits.last) : g);
  }
  // pieces with distance and moving time (time between points of one segment)
  final pieces = <GaitPiece>[];
  for (var i = 0; i < pts.length; i++) {
    final dm = i == 0 || pts[i].segment != pts[i - 1].segment ? 0.0 : cum[i] - cum[i - 1];
    final ds = i == 0 || pts[i].segment != pts[i - 1].segment
        ? 0.0
        : pts[i].time.difference(pts[i - 1].time).inMilliseconds / 1000;
    if (pieces.isEmpty || pieces.last.gait != gaits[i]) {
      pieces.add(GaitPiece(gaits[i], i, i, dm, ds));
    } else {
      pieces.last
        ..to = i
        ..metres += dm
        ..seconds += ds;
    }
  }
  // short pieces join their neighbours
  var changed = true;
  while (changed && pieces.length > 1) {
    changed = false;
    for (var k = 0; k < pieces.length; k++) {
      if (pieces[k].seconds >= minPieceS) continue;
      final into = k > 0 ? pieces[k - 1] : pieces[k + 1];
      final p = pieces.removeAt(k);
      if (k > 0) {
        into
          ..to = p.to
          ..metres += p.metres
          ..seconds += p.seconds;
        // the next piece may now continue the same gait
        if (k < pieces.length && pieces[k].gait == into.gait) {
          final n = pieces.removeAt(k);
          into
            ..to = n.to
            ..metres += n.metres
            ..seconds += n.seconds;
        }
      } else {
        pieces[0] = GaitPiece(into.gait, p.from, into.to, into.metres + p.metres, into.seconds + p.seconds);
      }
      changed = true;
      break;
    }
  }
  double sum(Gait g, double Function(GaitPiece) f) => pieces.where((p) => p.gait == g).fold(0.0, (a, p) => a + f(p));
  return GaitSummary(
    pieces,
    sum(Gait.walk, (p) => p.metres),
    sum(Gait.run, (p) => p.metres),
    sum(Gait.walk, (p) => p.seconds),
    sum(Gait.run, (p) => p.seconds),
    cum,
    _movingSeconds(pts),
  );
}

List<double> _movingSeconds(List<GaitPoint> pts) {
  final out = <double>[];
  var t = 0.0;
  for (var i = 0; i < pts.length; i++) {
    if (i > 0 && pts[i].segment == pts[i - 1].segment) {
      t += pts[i].time.difference(pts[i - 1].time).inMilliseconds / 1000;
    }
    out.add(t);
  }
  return out;
}

/// Run/walk plans: how many walk breaks were walked, and extra walking during
/// the run parts. [laps] in order (moving seconds of each).
({int walked, int breaks, int extra}) keptToPlan(GaitSummary g, List<({bool walkStep, double seconds})> laps) {
  var t = 0.0, walked = 0, breaks = 0, extra = 0;
  for (final l in laps) {
    final share = g.walkedShareBetween(t, t + l.seconds);
    if (l.walkStep) {
      breaks++;
      if (share >= 0.5) walked++;
    } else if (share > 0.2) {
      extra++;
    }
    t += l.seconds;
  }
  return (walked: walked, breaks: breaks, extra: extra);
}

/// Run or walk for an outing without a route (treadmill, logged by hand):
/// from its average pace and cadence.
bool isWalkByAverages({required double distanceM, required int durationS, int? avgCadence}) {
  if (distanceM <= 0 || durationS <= 0) return false;
  return classifyGait(paceS: durationS / distanceM * 1000, cadence: avgCadence?.toDouble()) == Gait.walk;
}
