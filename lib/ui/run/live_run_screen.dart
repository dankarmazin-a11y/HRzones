import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app_services.dart';
import '../../hr/hr_monitor.dart';
import '../../run/geo.dart';
import '../../run/location_source.dart';
import '../../run/route_zones.dart';
import '../../run/run_session.dart';
import '../../workout/stats.dart';
import '../timer_style.dart';
import '../number_input.dart';
import '../zone_colors.dart';
import 'run_map.dart';
import 'run_start.dart';
import 'run_summary_screen.dart';

/// The run being recorded: distance, time, pace, heart rate; pause / finish.
/// Bold white numbers on a dark background (readable while running).
class LiveRunScreen extends StatefulWidget {
  const LiveRunScreen({super.key});

  /// Numbers or map (kept while the app runs).
  static bool showMap = false;

  @override
  State<LiveRunScreen> createState() => _LiveRunScreenState();
}

class _LiveRunScreenState extends State<LiveRunScreen> {
  static const _bg = TimerStyle.neutralBackground;

  @override
  Widget build(BuildContext context) {
    final run = Services.of(context).run;
    final map = LiveRunScreen.showMap && !run.treadmill;
    return ListenableBuilder(
      listenable: run,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: run.paused ? TimerStyle.restBackground : _bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            leading: IconButton(
              key: const Key('minimizeRun'),
              tooltip: 'Back to the app',
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(run.paused ? 'Paused' : (run.treadmill ? 'Treadmill run' : 'Run')),
            actions: [
              if (!run.treadmill) _GpsChip(status: run.gps),
              if (!run.treadmill)
                IconButton(
                  key: const Key('toggleRunMap'),
                  tooltip: map ? 'Show numbers' : 'Show map',
                  icon: Icon(map ? Icons.speed : Icons.map_outlined),
                  onPressed: () => setState(() => LiveRunScreen.showMap = !map),
                ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: !run.active
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      if (map) ...[
                        Expanded(child: _LiveMap(run: run)),
                        ValueListenableBuilder<int>(
                          valueListenable: run.ticks,
                          builder: (context, _, _) => _Strip(run: run),
                        ),
                      ] else
                        Expanded(
                          child: ValueListenableBuilder<int>(
                            valueListenable: run.ticks,
                            builder: (context, _, _) => _Numbers(run: run),
                          ),
                        ),
                      if (run.location.isSimulated && run.location is SimulatedLocationSource)
                        _SimulatedControls(source: run.location as SimulatedLocationSource),
                      _Controls(run: run),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _Numbers extends StatelessWidget {
  const _Numbers({required this.run});

  final RunSession run;

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600);
    const small = TextStyle(
      color: Colors.white,
      fontSize: 34,
      fontWeight: FontWeight.w800,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    Widget stat(String value, String name, {Key? key}) => Expanded(
      child: Column(
        children: [
          FittedBox(
            child: Text(value, key: key, style: small),
          ),
          Text(name, style: label),
        ],
      ),
    );
    // Small phones: everything shrinks to fit instead of overflowing.
    return LayoutBuilder(
      builder: (context, box) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: box.maxWidth,
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _column(run, label, stat)),
          ),
        ),
      ),
    );
  }

  Widget _column(RunSession run, TextStyle label, Widget Function(String, String, {Key? key}) stat) => run.treadmill
      ? Column(
          // Treadmill: no GPS – the time is the big number.
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              child: Text(
                formatDuration(run.moving),
                key: const Key('runTime'),
                style: TimerStyle.digits.copyWith(fontSize: 110),
              ),
            ),
            Text('Time', style: label),
            const SizedBox(height: 32),
            const _HeartRate(),
            _Cadence(run: run),
          ],
        )
      : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              child: Text(
                formatKm(run.distanceM),
                key: const Key('runDistance'),
                style: TimerStyle.digits.copyWith(fontSize: 120),
              ),
            ),
            Text('Kilometres', style: label),
            const SizedBox(height: 32),
            Row(
              children: [
                stat(formatDuration(run.moving), 'Time', key: const Key('runTime')),
                stat(formatPace(run.currentPace), 'Pace /km', key: const Key('runPace')),
                stat(formatPace(run.avgPace), 'Avg pace', key: const Key('runAvgPace')),
              ],
            ),
            const SizedBox(height: 24),
            const _HeartRate(),
            _Cadence(run: run),
          ],
        );
}

class _HeartRate extends StatelessWidget {
  const _HeartRate();

  @override
  Widget build(BuildContext context) {
    final hr = HrScope.of(context);
    if (!hr.running) return const SizedBox.shrink();
    final bpm = hr.bpm;
    final color = zoneColor(hr.zone?.number);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: color, size: 32),
            const SizedBox(width: 8),
            Text(
              bpm == null ? '––' : '$bpm',
              key: const Key('runHr'),
              style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 6),
            const Text('bpm', style: TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
        Text(
          'Target ${hr.range}${hr.zone == null ? '' : ' · zone ${hr.zone!.number}'}',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}

class _GpsChip extends StatelessWidget {
  const _GpsChip({required this.status});

  final GpsStatus status;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      GpsStatus.off => ('GPS off', Colors.white54),
      GpsStatus.searching => ('Finding GPS…', TimerStyle.readyAccent),
      GpsStatus.good => ('GPS', TimerStyle.workAccent),
      GpsStatus.weak => ('Weak GPS', Colors.orangeAccent),
    };
    return Row(
      key: const Key('gpsStatus'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(status == GpsStatus.good ? Icons.gps_fixed : Icons.gps_not_fixed, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.run});

  final RunSession run;

  Future<void> _finish(BuildContext context) async {
    final nav = Navigator.of(context);
    final tooShort = !run.treadmill && run.distanceM < 50;
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Finish run?'),
        content: Text(
          run.treadmill
              ? 'Treadmill run, ${formatDuration(run.moving)}. Next: the distance.'
              : tooShort
              ? 'This run is shorter than 50 m. Save it anyway?'
              : '${formatKm(run.distanceM)} km in ${formatDuration(run.moving)}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, 'discard'), child: const Text('Discard')),
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Keep going')),
          FilledButton(onPressed: () => Navigator.pop(c, 'save'), child: const Text('Save')),
        ],
      ),
    );
    if (choice == 'discard') {
      if (!context.mounted) return;
      final sure = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Discard this run?'),
          content: const Text('The route and time will be deleted.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Discard')),
          ],
        ),
      );
      if (sure != true) return;
      await run.discard();
      nav.pop();
    } else if (choice == 'save') {
      if (run.treadmill) {
        if (context.mounted) await _finishTreadmill(context);
        return;
      }
      final id = await run.finish();
      if (id != null) runVibration(times: 2);
      if (id != null) await nav.pushReplacement(MaterialPageRoute(builder: (_) => RunSummaryScreen(runId: id)));
    }
  }

  /// Treadmill: the distance from the treadmill's display.
  Future<void> _finishTreadmill(BuildContext context) async {
    final nav = Navigator.of(context);
    final km = await promptNumber(
      context,
      title: 'Distance (km) – from the treadmill',
      initial: 5,
      decimal: true,
      min: 0,
      max: 100,
      suffix: 'km',
    );
    if (km == null) return;
    final id = await run.finish(distanceM: km * 1000);
    if (id == null) return;
    runVibration(times: 2);
    await nav.pushReplacement(MaterialPageRoute(builder: (_) => RunSummaryScreen(runId: id)));
  }

  @override
  Widget build(BuildContext context) {
    const big = Size(96, 96);
    Widget round({
      required Key key,
      required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap,
    }) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.fromSize(
          size: big,
          child: FilledButton(
            key: key,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: color,
              foregroundColor: Colors.black,
              padding: EdgeInsets.zero,
            ),
            onPressed: onTap,
            child: Icon(icon, size: 48),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: run.paused
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                round(
                  key: const Key('finishRun'),
                  icon: Icons.stop,
                  label: 'Finish',
                  color: const Color(0xFFFF8A80),
                  onTap: () => _finish(context),
                ),
                round(
                  key: const Key('resumeRun'),
                  icon: Icons.play_arrow,
                  label: 'Resume',
                  color: TimerStyle.workAccent,
                  onTap: () {
                    runVibration();
                    run.resume();
                  },
                ),
              ],
            )
          : Center(
              child: round(
                key: const Key('pauseRun'),
                icon: Icons.pause,
                label: 'Pause',
                color: TimerStyle.readyAccent,
                onTap: () {
                  runVibration();
                  run.pause();
                },
              ),
            ),
    );
  }
}

/// Web preview / tests: change the pretend runner's pace.
class _SimulatedControls extends StatefulWidget {
  const _SimulatedControls({required this.source});

  final SimulatedLocationSource source;

  @override
  State<_SimulatedControls> createState() => _SimulatedControlsState();
}

class _SimulatedControlsState extends State<_SimulatedControls> {
  @override
  Widget build(BuildContext context) {
    final s = widget.source;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            'Simulated GPS (preview) · pace ${formatPace(s.paceSecPerKm)} /km',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Slider(
            min: 180,
            max: 600,
            value: s.paceSecPerKm.clamp(180, 600),
            onChanged: (v) => setState(() => s.paceSecPerKm = v),
          ),
        ],
      ),
    );
  }
}

/// Map view while running: follows you until you drag it; ◎ follows again.
class _LiveMap extends StatefulWidget {
  const _LiveMap({required this.run});

  final RunSession run;

  @override
  State<_LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<_LiveMap> {
  final _map = MapController();
  bool _follow = true;
  bool _ready = false;
  int _count = -1;
  RouteSegments _segments = const [];

  @override
  void initState() {
    super.initState();
    widget.run.ticks.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.run.ticks.removeListener(_onTick);
    _map.dispose();
    super.dispose();
  }

  LatLng? get _here {
    final r = widget.run.route;
    return r.isEmpty ? null : LatLng(r.last.lat, r.last.lon);
  }

  void _onTick() {
    final route = widget.run.route;
    if (route.length == _count) return; // nothing new
    setState(() {
      _count = route.length;
      _segments = routeSegments(route.map((p) => (lat: p.lat, lon: p.lon, segment: p.segment)));
    });
    final here = _here;
    if (_follow && _ready && here != null) _map.move(here, _map.camera.zoom);
  }

  /// With heart rate: the line in zone colours (as on the summary).
  List<(List<LatLng>, Color)>? _zoneColored(BuildContext context) {
    final hr = HrScope.of(context);
    final route = widget.run.route;
    if (!hr.running || !route.any((p) => p.hr != null)) return null;
    return [
      for (final piece in zonePieces([
        for (final p in route) (time: p.time, lat: p.lat, lon: p.lon, segment: p.segment, hr: p.hr),
      ], hr.zones))
        ([for (final p in piece.points) LatLng(p.lat, p.lon)], zoneColor(piece.zone)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_count < 0) {
      _count = widget.run.route.length;
      _segments = routeSegments(widget.run.route.map((p) => (lat: p.lat, lon: p.lon, segment: p.segment)));
    }
    return Stack(
      children: [
        Positioned.fill(
          child: RunMap(
            key: const Key('liveMap'),
            segments: _segments,
            colored: _zoneColored(context),
            controller: _map,
            current: _here ?? RunMap.fallbackCenter,
            fitRoute: false,
            onUserMove: () => _follow ? setState(() => _follow = false) : null,
            onReady: () => _ready = true,
          ),
        ),
        if (!_follow)
          Positioned(
            right: 12,
            bottom: 24,
            child: FloatingActionButton.small(
              key: const Key('followMe'),
              tooltip: 'Follow me',
              onPressed: () {
                setState(() => _follow = true);
                final here = _here;
                if (here != null && _ready) _map.move(here, _map.camera.zoom);
              },
              child: const Icon(Icons.my_location),
            ),
          ),
      ],
    );
  }
}

/// Distance / time / pace under the live map.
class _Strip extends StatelessWidget {
  const _Strip({required this.run});

  final RunSession run;

  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label, Key key) => Expanded(
      child: Column(
        children: [
          FittedBox(
            child: Text(
              value,
              key: key,
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Row(
        children: [
          stat(formatKm(run.distanceM), 'km', const Key('runDistance')),
          stat(formatDuration(run.moving), 'Time', const Key('runTime')),
          stat(formatPace(run.currentPace), 'Pace /km', const Key('runPace')),
        ],
      ),
    );
  }
}

/// Steps per minute from the phone's motion chip (hidden when unknown).
class _Cadence extends StatelessWidget {
  const _Cadence({required this.run});

  final RunSession run;

  @override
  Widget build(BuildContext context) {
    final c = run.cadence;
    if (c == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        'Cadence ${c.round()} spm',
        key: const Key('runCadence'),
        style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}
