import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../run/geo.dart';
import '../workout/workout_summary_screen.dart' show formatDate;
import '../number_input.dart';
import 'run_summary_screen.dart';

/// Log a run by hand ([run] null: treadmill, or the phone stayed at home)
/// or edit a finished run: start, time, distance, kind, average heart rate.
/// A recorded run that kept going after you stopped can be cut at the end.
class EditRunScreen extends StatefulWidget {
  const EditRunScreen({super.key, this.run});

  final Run? run;

  @override
  State<EditRunScreen> createState() => _EditRunScreenState();
}

class _EditRunScreenState extends State<EditRunScreen> {
  late DateTime _start;
  late int _seconds;
  late double _km;
  late RunKind _kind;
  int? _avgHr;
  DateTime? _cutAt;
  List<RunPoint> _points = const [];

  bool get _isNew => widget.run == null;

  @override
  void initState() {
    super.initState();
    final r = widget.run;
    final now = DateTime.now();
    _start = r?.startedAt ?? DateTime(now.year, now.month, now.day, now.hour).subtract(const Duration(hours: 1));
    _seconds = r?.durationS ?? 30 * 60;
    _km = (r?.distanceM ?? 5000) / 1000;
    _kind = r?.kind ?? RunKind.outdoor;
    _avgHr = r?.avgHr;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = widget.run;
    if (r != null && _points.isEmpty) {
      Services.of(context).runs.points(r.id).then((p) {
        if (mounted) setState(() => _points = p);
      });
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _start = DateTime(d.year, d.month, d.day, _start.hour, _start.minute));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (t != null) setState(() => _start = DateTime(_start.year, _start.month, _start.day, t.hour, t.minute));
  }

  Future<void> _save() async {
    final s = Services.of(context);
    final nav = Navigator.of(context);
    final r = widget.run;
    if (r == null) {
      final id = await s.runs.logRun(
        startedAt: _start,
        durationS: _seconds,
        distanceM: _km * 1000,
        kind: _kind,
        avgHr: _avgHr,
        shoeId: (await s.shoes.defaultShoe())?.id,
      );
      await nav.pushReplacement(MaterialPageRoute(builder: (_) => RunSummaryScreen(runId: id)));
      return;
    }
    final cut = _cutAt;
    if (cut != null) {
      await s.runs.trimEnd(r, cut);
      final trimmed = await s.runs.byId(r.id);
      if (trimmed != null) await s.runs.updateRun(trimmed, kind: _kind, avgHr: _avgHr);
    } else {
      await s.runs.updateRun(
        r,
        startedAt: _start,
        durationS: _seconds,
        distanceM: (_km * 1000 - r.distanceM).abs() < 5 ? null : _km * 1000,
        kind: _kind,
        avgHr: _avgHr,
      );
    }
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final pace = paceSecPerKm(_km * 1000, _seconds.toDouble());
    String two(int n) => n.toString().padLeft(2, '0');
    final r = widget.run;
    final canCut = r != null && _points.length > 10;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Log a run' : 'Edit run'),
        actions: [TextButton(key: const Key('saveRun'), onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<RunKind>(
            key: const Key('editRunKind'),
            segments: const [
              ButtonSegment(value: RunKind.outdoor, label: Text('Outdoor'), icon: Icon(Icons.landscape_outlined)),
              ButtonSegment(value: RunKind.treadmill, label: Text('Treadmill'), icon: Icon(Icons.home_outlined)),
            ],
            selected: {_kind},
            onSelectionChanged: (v) => setState(() => _kind = v.first),
          ),
          const SizedBox(height: 8),
          if (_cutAt == null) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Date'),
              trailing: TextButton(onPressed: _pickDate, child: Text(formatDate(_start))),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Start time'),
              trailing: TextButton(onPressed: _pickTime, child: Text('${two(_start.hour)}:${two(_start.minute)}')),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.straighten),
              title: const Text('Distance'),
              trailing: EditableNumber(
                key: const Key('editDistance'),
                value: _km,
                title: 'Distance (km)',
                decimal: true,
                min: 0,
                max: 300,
                suffix: 'km',
                display: '${_km.toStringAsFixed(2)} km',
                onChanged: (v) => setState(() => _km = v.toDouble()),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Moving time'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EditableNumber(
                    key: const Key('editMinutes'),
                    value: _seconds ~/ 60,
                    title: 'Minutes',
                    max: 1440,
                    suffix: 'min',
                    display: '${_seconds ~/ 60} min',
                    onChanged: (v) => setState(() => _seconds = v.toInt() * 60 + _seconds % 60),
                  ),
                  EditableNumber(
                    key: const Key('editSeconds'),
                    value: _seconds % 60,
                    title: 'Seconds',
                    max: 59,
                    suffix: 's',
                    display: '${_seconds % 60} s',
                    onChanged: (v) => setState(() => _seconds = _seconds ~/ 60 * 60 + v.toInt()),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 56, bottom: 8),
              child: Text('Pace ${formatPace(pace)} /km', style: text.bodyMedium),
            ),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Average heart rate'),
            trailing: EditableNumber(
              key: const Key('editAvgHr'),
              value: _avgHr ?? 0,
              title: 'Average heart rate (0 = none)',
              max: 230,
              suffix: 'bpm',
              display: _avgHr == null ? 'none' : '$_avgHr bpm',
              onChanged: (v) => setState(() => _avgHr = v == 0 ? null : v.toInt()),
            ),
          ),
          if (_isNew)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Runs logged by hand have no route and don\'t count for records (1 km, 5 km…). '
                'They count for your week, streak and goals.',
                style: text.bodySmall,
              ),
            ),
          if (canCut) ...[
            const Divider(height: 32),
            Text('Forgot to stop?', style: text.titleMedium),
            Text('Cut the end of the run: everything after this time is removed.', style: text.bodySmall),
            _CutSlider(
              points: _points,
              start: r.startedAt,
              end: r.endedAt ?? _points.last.time,
              value: _cutAt,
              onChanged: (t) => setState(() => _cutAt = t),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pick where the run really ended; shows the time and distance there.
class _CutSlider extends StatelessWidget {
  const _CutSlider({
    required this.points,
    required this.start,
    required this.end,
    required this.value,
    required this.onChanged,
  });

  final List<RunPoint> points;
  final DateTime start;
  final DateTime end;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final total = end.difference(start).inSeconds.toDouble();
    if (total <= 0) return const SizedBox.shrink();
    final at = value ?? end;
    // Distance up to the chosen time (same filter as the run).
    final tracker = DistanceTracker();
    int? seg;
    for (final p in points) {
      if (p.time.isAfter(at)) break;
      if (p.segment != seg) tracker.newSegment();
      seg = p.segment;
      tracker.add(GeoFix(time: p.time, lat: p.lat, lon: p.lon, accuracy: p.accuracy));
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          key: const Key('cutSlider'),
          value: at.difference(start).inSeconds.toDouble().clamp(0, total),
          max: total,
          onChanged: (v) {
            final t = start.add(Duration(seconds: v.round()));
            onChanged(t.isBefore(end.subtract(const Duration(seconds: 30))) ? t : null);
          },
        ),
        Text(
          value == null
              ? 'Ends at ${two(end.hour)}:${two(end.minute)} (no change)'
              : 'Ends at ${two(at.hour)}:${two(at.minute)} · ${formatKm(tracker.distanceM)} km',
          key: const Key('cutLabel'),
        ),
      ],
    );
  }
}
