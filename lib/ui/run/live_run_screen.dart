import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../hr/hr_monitor.dart';
import '../../run/geo.dart';
import '../../run/location_source.dart';
import '../../run/run_session.dart';
import '../../workout/stats.dart';
import '../timer_style.dart';
import '../zone_colors.dart';
import 'run_start.dart';
import 'run_summary_screen.dart';

/// The run being recorded: distance, time, pace, heart rate; pause / finish.
/// Bold white numbers on a dark background (readable while running).
class LiveRunScreen extends StatelessWidget {
  const LiveRunScreen({super.key});

  static const _bg = TimerStyle.neutralBackground;

  @override
  Widget build(BuildContext context) {
    final run = Services.of(context).run;
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
            title: Text(run.paused ? 'Paused' : 'Run'),
            actions: [
              _GpsChip(status: run.gps),
              const SizedBox(width: 12),
            ],
          ),
          body: SafeArea(
            child: !run.active
                ? const SizedBox.shrink()
                : Column(
                    children: [
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

  Widget _column(RunSession run, TextStyle label, Widget Function(String, String, {Key? key}) stat) => Column(
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
    final tooShort = run.distanceM < 50;
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Finish run?'),
        content: Text(
          tooShort
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
      final id = await run.finish();
      if (id != null) runVibration(start: false);
      if (id != null) await nav.pushReplacement(MaterialPageRoute(builder: (_) => RunSummaryScreen(runId: id)));
    }
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
                  onTap: run.resume,
                ),
              ],
            )
          : Center(
              child: round(
                key: const Key('pauseRun'),
                icon: Icons.pause,
                label: 'Pause',
                color: TimerStyle.readyAccent,
                onTap: run.pause,
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
