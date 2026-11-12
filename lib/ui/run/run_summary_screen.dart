import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../app_services.dart';
import '../../data/database.dart';
import '../../run/geo.dart';
import '../../run/elevation.dart';
import '../../run/splits.dart';
import '../../workout/stats.dart';
import '../hr_presets.dart';
import 'run_map.dart';
import 'edit_run_screen.dart';
import 'run_feel.dart';
import 'run_plans.dart';
import 'run_records.dart';
import 'run_start.dart';
import 'share_run.dart';
import 'shoes.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:latlong2/latlong.dart';

import '../../hr/hr_monitor.dart';
import '../../hr/zones.dart';
import '../../run/route_zones.dart';
import '../zone_colors.dart';

/// A finished run: distance, time, pace, heart rate.
class RunSummaryScreen extends StatelessWidget {
  const RunSummaryScreen({super.key, required this.runId});

  final String runId;

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete this run?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await Services.of(context).runs.delete(runId);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return StreamBuilder<Run?>(
      stream: s.runs.watch(runId),
      builder: (context, snap) {
        final run = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(run == null ? 'Run' : runTitle(run)),
            actions: [
              PopupMenuButton<String>(
                key: const Key('runMenu'),
                onSelected: (v) => switch (v) {
                  'delete' => _delete(context),
                  'share' when run != null => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => ShareRunScreen(run: run))),
                  'edit' when run != null => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => EditRunScreen(run: run))),
                  _ => null,
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'share', child: Text('Share picture')),
                  PopupMenuItem(value: 'edit', child: Text('Edit run')),
                  PopupMenuItem(value: 'delete', child: Text('Delete run')),
                ],
              ),
            ],
          ),
          body: run == null ? const SizedBox.shrink() : _Body(run: run),
        );
      },
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.run});

  final Run run;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  Future<double?>? _weight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Once: a new future on every rebuild (typing a note saves the run)
    // made the calories flicker.
    _weight ??= Services.of(context).body.latest('weight');
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final pace = paceSecPerKm(run.distanceM, run.durationS.toDouble());
    Widget tile(String value, String label) => Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(value, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
    // Not a lazy ListView: its cards load their numbers when first built, so
    // building them only on scrolling made the page jump while scrolling
    // (and again on the way back, after they were thrown away).
    return SingleChildScrollView(
      key: const Key('runSummaryList'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RouteCard(run: run),
          const SizedBox(height: 16),
          Center(
            child: Text(
              formatKm(run.distanceM),
              key: const Key('summaryDistance'),
              style: text.displayLarge?.copyWith(fontWeight: FontWeight.w900, color: scheme.primary),
            ),
          ),
          Center(child: Text('Kilometres', style: text.titleMedium)),
          const SizedBox(height: 16),
          FutureBuilder<double?>(
            future: _weight,
            builder: (context, snap) {
              final kcal = runCalories(run.distanceM, snap.data);
              return Row(
                children: [
                  tile(formatDuration(Duration(seconds: run.durationS)), 'Time'),
                  tile(formatPace(pace), 'Avg pace /km'),
                  tile(kcal == null ? '–' : '${kcal.round()}', kcal == null ? 'kcal (add weight)' : 'Calories'),
                ],
              );
            },
          ),
          if (run.avgHr != null || run.maxHr != null)
            Row(
              children: [
                tile(run.avgHr == null ? '–' : '${run.avgHr}', 'Avg HR'),
                tile(run.maxHr == null ? '–' : '${run.maxHr}', 'Max HR'),
              ],
            ),
          _ClimbAndCadence(run: run, tile: tile),
          if (run.hrPresetId != null)
            FutureBuilder<HrPreset?>(
              future: Services.of(context).presets.byId(run.hrPresetId),
              builder: (context, snap) => snap.data == null
                  ? const SizedBox.shrink()
                  : ListTile(
                      leading: const Icon(Icons.monitor_heart_outlined),
                      title: Text('${snap.data!.name} · ${presetRange(snap.data!)}'),
                    ),
            ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(_timeRange(run)),
            subtitle: run.endedAt == null
                ? null
                : Text('Total ${formatDuration(run.endedAt!.difference(run.startedAt))}'),
          ),
          const SizedBox(height: 8),
          RunShoeRow(runId: run.id, shoeId: run.shoeId),
          RunFeelCard(key: ValueKey('feel_${run.id}'), run: run),
          LapsCard(run: run),
          RunCompareCard(key: ValueKey('compare_${run.id}'), run: run),
          RunBestsCard(run: run),
          _SplitsSection(run: run),
        ],
      ),
    );
  }
}

/// Rough energy used running [distanceM]: about 1 kcal per kg of body
/// weight per km (the usual estimate; pace barely changes it). Null
/// without a body weight.
double? runCalories(double distanceM, double? weightKg) =>
    weightKg == null || weightKg <= 0 ? null : weightKg * distanceM / 1000 * 1.036;

String _two(int n) => n.toString().padLeft(2, '0');

String _clock(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

String _timeRange(Run r) => r.endedAt == null ? _clock(r.startedAt) : '${_clock(r.startedAt)} – ${_clock(r.endedAt!)}';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "Thu 5 Nov · Morning run"
String runTitle(Run r) {
  final d = r.startedAt;
  final h = d.hour;
  final part = h < 5 ? 'Night' : (h < 12 ? 'Morning' : (h < 17 ? 'Afternoon' : (h < 21 ? 'Evening' : 'Night')));
  return '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} · $part run';
}

/// The route on a small map (plain or coloured by heart-rate zone), the
/// time in each zone below it; tap the map for full screen.
class _RouteCard extends StatefulWidget {
  const _RouteCard({required this.run});

  final Run run;

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  RouteSegments? _segments;
  List<HrPoint> _points = const [];
  bool _byZone = false;

  bool get _hasHr => _points.any((p) => p.hr != null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_segments == null) _load();
  }

  Future<void> _load() async {
    final rows = await Services.of(context).runs.points(widget.run.id);
    if (!mounted) return;
    setState(() {
      _points = [for (final p in rows) (time: p.time, lat: p.lat, lon: p.lon, segment: p.segment, hr: p.hr)];
      _segments = routeSegments(rows.map((p) => (lat: p.lat, lon: p.lon, segment: p.segment)));
      _byZone = _hasHr; // show the zones straight away when there is heart rate
    });
  }

  List<(List<LatLng>, Color)>? _colored(HrZones zones) => !_byZone
      ? null
      : [
          for (final piece in zonePieces(_points, zones))
            ([for (final p in piece.points) LatLng(p.lat, p.lon)], zoneColor(piece.zone)),
        ];

  @override
  Widget build(BuildContext context) {
    final segments = _segments;
    if (segments == null) return const SizedBox(height: 220);
    if (segments.isEmpty) {
      return Card(
        child: SizedBox(
          height: 80,
          child: Center(
            child: Text(
              widget.run.kind == RunKind.treadmill ? 'Treadmill run – no route' : 'No GPS route recorded',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }
    final zones = HrScope.of(context).zones;
    final colored = _colored(zones);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasHr)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SegmentedButton<bool>(
              key: const Key('routeMode'),
              segments: const [
                ButtonSegment(value: false, label: Text('Route'), icon: Icon(Icons.route)),
                ButtonSegment(value: true, label: Text('Heart-rate zones'), icon: Icon(Icons.favorite_outline)),
              ],
              selected: {_byZone},
              onSelectionChanged: (v) => setState(() => _byZone = v.first),
            ),
          ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                Positioned.fill(
                  child: RunMap(key: const Key('summaryMap'), segments: segments, colored: colored, interactive: false),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('openRunMap'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              RunMapScreen(segments: segments, colored: colored, title: runTitle(widget.run)),
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned(right: 8, top: 8, child: Icon(Icons.open_in_full, size: 20)),
              ],
            ),
          ),
        ),
        if (_hasHr) _ZoneTimes(points: _points, zones: zones, presetId: widget.run.hrPresetId),
      ],
    );
  }
}

/// Time in each heart-rate zone (bars), and in / above / below the preset
/// range when the run had one.
class _ZoneTimes extends StatelessWidget {
  const _ZoneTimes({required this.points, required this.zones, this.presetId});

  final List<HrPoint> points;
  final HrZones zones;
  final String? presetId;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final times = timeInZones(points, zones);
    final total = times.values.fold(0.0, (a, b) => a + b);
    if (total <= 0) return const SizedBox.shrink();
    String mins(double s) => formatDuration(Duration(seconds: s.round()));
    return Card(
      key: const Key('zoneTimes'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time in heart-rate zones', style: text.titleMedium),
            const SizedBox(height: 8),
            for (final z in zones.zones.reversed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(width: 92, child: Text('Z${z.number} ${z.name}', style: text.bodySmall)),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) => Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 12,
                            width: box.maxWidth * ((times[z.number] ?? 0) / total),
                            decoration: BoxDecoration(
                              color: zoneColor(z.number),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: Text(
                        mins(times[z.number] ?? 0),
                        key: Key('zoneTime_${z.number}'),
                        textAlign: TextAlign.end,
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            if (presetId != null)
              FutureBuilder<HrPreset?>(
                future: Services.of(context).presets.byId(presetId),
                builder: (context, snap) {
                  final p = snap.data;
                  if (p == null) return const SizedBox.shrink();
                  final r = timeVsRange(points, HrRange(min: p.minBpm, max: p.maxBpm));
                  final all = r.below + r.inside + r.above;
                  if (all <= 0) return const SizedBox.shrink();
                  int pct(double v) => (v / all * 100).round();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'In your zone (${p.minBpm}–${p.maxBpm}) ${pct(r.inside)}% · '
                      'above ${pct(r.above)}% · below ${pct(r.below)}%',
                      key: const Key('inRange'),
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Time and pace for every kilometre, fastest in bold, bar = relative speed.
class _SplitsSection extends StatefulWidget {
  const _SplitsSection({required this.run});

  final Run run;

  @override
  State<_SplitsSection> createState() => _SplitsSectionState();
}

class _SplitsSectionState extends State<_SplitsSection> {
  List<KmSplit>? _splits;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_splits == null) _load();
  }

  Future<void> _load() async {
    final points = await Services.of(context).runs.points(widget.run.id);
    if (!mounted) return;
    setState(
      () => _splits = computeSplits(
        points.map((p) => (time: p.time, lat: p.lat, lon: p.lon, accuracy: p.accuracy, segment: p.segment, hr: p.hr)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final splits = _splits;
    if (splits == null || splits.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final full = splits.where((x) => !x.partial && x.pace != null).toList();
    final fastest = full.length < 2 ? null : full.reduce((a, b) => a.pace! <= b.pace! ? a : b);
    final paces = splits.map((x) => x.pace).whereType<double>().toList();
    final slowest = paces.isEmpty ? 1.0 : paces.reduce((a, b) => a > b ? a : b);
    final quickest = paces.isEmpty ? 1.0 : paces.reduce((a, b) => a < b ? a : b);
    final hasHr = splits.any((x) => x.avgHr != null);
    final avg = paceSecPerKm(widget.run.distanceM, widget.run.durationS.toDouble());
    final muted = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Card(
      key: const Key('splits'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Splits', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                if (avg != null) Text('avg ${formatPace(avg)} /km', style: muted),
              ],
            ),
            if (fastest != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Fastest: km ${fastest.km} in ${formatPace(fastest.pace)}', style: muted),
              ),
            const SizedBox(height: 12),
            for (final x in splits)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  key: Key('split_${x.km}'),
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        x.partial ? (x.distanceM / 1000).toStringAsFixed(2) : '${x.km}',
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          // Faster = longer bar (the slowest still gets 40 %);
                          // colour from green (fastest) to orange (slowest).
                          final p = x.pace ?? slowest;
                          final span = slowest - quickest;
                          final t = span <= 0 ? 0.0 : ((p - quickest) / span).clamp(0.0, 1.0);
                          final color = Color.lerp(const Color(0xFF2E9E5B), const Color(0xFFEF8A2C), t)!;
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 28,
                              width: box.maxWidth * (1 - t * 0.6),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                border: x == fastest ? Border.all(color: scheme.onSurface, width: 2) : null,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      formatPace(x.pace),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontFeatures: [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                    if (x == fastest) const Icon(Icons.bolt, size: 16, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (hasHr)
                      SizedBox(
                        width: 64,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (x.avgHr != null) const Icon(Icons.favorite, size: 13, color: AppColors.heart),
                            const SizedBox(width: 3),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(x.avgHr == null ? '–' : '${x.avgHr}', style: text.bodyMedium),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Climb / descent (barometer, or the GPS height on older runs) and cadence; plus the height
/// profile along the route.
class _ClimbAndCadence extends StatefulWidget {
  const _ClimbAndCadence({required this.run, required this.tile});

  final Run run;
  final Widget Function(String value, String label) tile;

  @override
  State<_ClimbAndCadence> createState() => _ClimbAndCadenceState();
}

class _ClimbAndCadenceState extends State<_ClimbAndCadence> {
  ({double climb, double descent})? _elevation;
  List<(double, double)> _profile = const []; // (km, metres)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_elevation == null) _load();
  }

  Future<void> _load() async {
    final pts = await Services.of(context).runs.points(widget.run.id);
    final withAlt = pts
        .where(
          (p) =>
              p.altitude != null &&
              DistanceTracker.usable(GeoFix(time: p.time, lat: p.lat, lon: p.lon, accuracy: p.accuracy)),
        )
        .toList();
    // Distance along the route for the profile.
    final tracker = DistanceTracker();
    final profile = <(double, double)>[];
    int? seg;
    for (final p in withAlt) {
      if (p.segment != seg) tracker.newSegment();
      seg = p.segment;
      tracker.add(GeoFix(time: p.time, lat: p.lat, lon: p.lon, accuracy: p.accuracy));
      profile.add((tracker.distanceM / 1000, p.altitude!));
    }
    final smooth = smoothAltitudes([for (final x in profile) x.$2]);
    if (!mounted) return;
    setState(() {
      // Barometer values when the phone measured them, else from GPS height.
      final r = widget.run;
      _elevation = r.elevGainM != null
          ? (climb: r.elevGainM!, descent: r.elevLossM ?? 0)
          : elevationGainLoss([for (final p in withAlt) p.altitude!]);
      _profile = [for (var i = 0; i < profile.length; i++) (profile[i].$1, smooth[i])];
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = _elevation;
    final r = widget.run;
    final hasClimb = e != null && _profile.length >= 10;
    final hasCadence = r.avgCadence != null;
    if (!hasClimb && !hasCadence) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            if (hasClimb) widget.tile('↑ ${e.climb.round()} m', 'Climb'),
            if (hasClimb) widget.tile('↓ ${e.descent.round()} m', 'Descent'),
            if (hasCadence) widget.tile('${r.avgCadence}', 'Cadence (spm)'),
          ],
        ),
        if (hasClimb && (e.climb >= 5 || e.descent >= 5)) _ElevationChart(profile: _profile),
      ],
    );
  }
}

/// A round step (1, 2, 5, 10, 20, 50…) giving about [count] steps over [span].
double niceStep(double span, int count) {
  if (span <= 0) return 1;
  final raw = span / count;
  var mag = 1.0;
  while (mag * 10 <= raw) {
    mag *= 10;
  }
  while (mag > raw) {
    mag /= 10;
  }
  for (final m in [1, 2, 5, 10]) {
    if (m * mag >= raw) return m * mag;
  }
  return 10 * mag;
}

String _kmLabel(double v) => v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

class _ElevationChart extends StatelessWidget {
  const _ElevationChart({required this.profile});

  final List<(double, double)> profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // At most ~200 points (the chart doesn't need every second).
    final step = (profile.length / 200).ceil().clamp(1, 1 << 30);
    final spots = [for (var i = 0; i < profile.length; i += step) FlSpot(profile[i].$1, profile[i].$2)];
    final minY = spots.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    // Round numbers on both axes, only a few labels, none squeezed together.
    final yStep = niceStep(maxY - minY + 4, 3);
    final lo = ((minY - 2) / yStep).floor() * yStep, hi = ((maxY + 2) / yStep).ceil() * yStep;
    final maxKm = spots.last.x;
    final xStep = niceStep(maxKm, 5).clamp(0.5, double.infinity);
    const label = TextStyle(fontSize: 11);
    return Card(
      key: const Key('elevationChart'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 20, 8),
        child: SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              minY: lo,
              maxY: hi,
              minX: 0,
              maxX: maxKm,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: yStep,
                getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: yStep,
                    getTitlesWidget: (v, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text('${v.round()} m', style: label),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: xStep,
                    minIncluded: true,
                    maxIncluded: false,
                    getTitlesWidget: (v, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(v == 0 ? '0 km' : _kmLabel(v), style: label),
                    ),
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  dotData: const FlDotData(show: false),
                  color: scheme.primary,
                  barWidth: 2,
                  belowBarData: BarAreaData(show: true, color: scheme.primary.withValues(alpha: 0.15)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Same route as an earlier run: time and pace then and now; and "Run this
/// route again" to race this run.
class RunCompareCard extends StatefulWidget {
  const RunCompareCard({super.key, required this.run});

  final Run run;

  @override
  State<RunCompareCard> createState() => _RunCompareCardState();
}

class _RunCompareCardState extends State<RunCompareCard> {
  Future<Run?>? _same;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _same ??= Services.of(context).runs.sameRoute(widget.run);
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    if (run.kind != RunKind.outdoor || run.distanceM < 300) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return FutureBuilder<Run?>(
      future: _same,
      builder: (context, snap) {
        final old = snap.data;
        final pace = paceSecPerKm(run.distanceM, run.durationS.toDouble());
        final oldPace = old == null ? null : paceSecPerKm(old.distanceM, old.durationS.toDouble());
        String diff(double a, double b) {
          final d = (a - b).round();
          if (d.abs() < 2) return 'same';
          return '${d < 0 ? '−' : '+'}${formatDuration(Duration(seconds: d.abs()))}';
        }

        return Card(
          key: const Key('runCompare'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (old != null) ...[
                  Text('Same route as ${runTitle(old)}', style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Time ${formatDuration(Duration(seconds: old.durationS))} → '
                    '${formatDuration(Duration(seconds: run.durationS))} '
                    '(${diff(run.durationS.toDouble(), old.durationS.toDouble())})',
                    key: const Key('compareTime'),
                  ),
                  if (pace != null && oldPace != null)
                    Text('Pace ${formatPace(oldPace)} → ${formatPace(pace)} /km (${diff(pace, oldPace)})'),
                  const SizedBox(height: 4),
                ],
                TextButton.icon(
                  key: const Key('raceThisRun'),
                  icon: const Icon(Icons.replay),
                  label: const Text('Run this route again'),
                  onPressed: () => startRun(context, ghostOf: run),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
