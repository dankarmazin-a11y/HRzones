import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../run/geo.dart';
import '../../run/splits.dart';
import '../../workout/stats.dart';
import '../hr_presets.dart';
import 'run_map.dart';

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
                onSelected: (v) => v == 'delete' ? _delete(context) : null,
                itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete run'))],
              ),
            ],
          ),
          body: run == null ? const SizedBox.shrink() : _Body(run: run),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.run});

  final Run run;

  @override
  Widget build(BuildContext context) {
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
    return ListView(
      padding: const EdgeInsets.all(16),
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
        Row(
          children: [
            tile(formatDuration(Duration(seconds: run.durationS)), 'Time'),
            tile(formatPace(pace), 'Avg pace /km'),
          ],
        ),
        if (run.avgHr != null || run.maxHr != null)
          Row(
            children: [
              tile(run.avgHr == null ? '–' : '${run.avgHr}', 'Avg HR'),
              tile(run.maxHr == null ? '–' : '${run.maxHr}', 'Max HR'),
            ],
          ),
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
        _SplitsSection(run: run),
        const SizedBox(height: 8),
        Text('Running records are coming next.', textAlign: TextAlign.center, style: text.bodySmall),
      ],
    );
  }
}

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

/// The route on a small map; tap for the full-screen map.
class _RouteCard extends StatefulWidget {
  const _RouteCard({required this.run});

  final Run run;

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  RouteSegments? _segments;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_segments == null) _load();
  }

  Future<void> _load() async {
    final points = await Services.of(context).runs.points(widget.run.id);
    if (!mounted) return;
    setState(() => _segments = routeSegments(points.map((p) => (lat: p.lat, lon: p.lon, segment: p.segment))));
  }

  @override
  Widget build(BuildContext context) {
    final segments = _segments;
    if (segments == null) return const SizedBox(height: 220);
    if (segments.isEmpty) {
      return Card(
        child: SizedBox(
          height: 80,
          child: Center(child: Text('No GPS route recorded', style: Theme.of(context).textTheme.bodyMedium)),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            Positioned.fill(
              child: RunMap(key: const Key('summaryMap'), segments: segments, interactive: false),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('openRunMap'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RunMapScreen(segments: segments, title: runTitle(widget.run)),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(right: 8, top: 8, child: Icon(Icons.open_in_full, size: 20)),
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
    final head = text.labelMedium?.copyWith(color: scheme.onSurfaceVariant);
    return Card(
      key: const Key('splits'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Splits', style: text.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(width: 48, child: Text('KM', style: head)),
                SizedBox(width: 64, child: Text('PACE', style: head)),
                const Expanded(child: SizedBox()),
                if (hasHr)
                  SizedBox(
                    width: 44,
                    child: Text('HR', textAlign: TextAlign.end, style: head),
                  ),
              ],
            ),
            for (final x in splits)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  key: Key('split_${x.km}'),
                  children: [
                    SizedBox(width: 48, child: Text(x.partial ? (x.distanceM / 1000).toStringAsFixed(2) : '${x.km}')),
                    SizedBox(
                      width: 64,
                      child: Text(
                        formatPace(x.pace),
                        style: TextStyle(fontWeight: x == fastest ? FontWeight.w900 : FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          // Faster = longer bar (the slowest still gets a third).
                          final p = x.pace ?? slowest;
                          final span = slowest - quickest;
                          final f = span <= 0 ? 1.0 : 1 - (p - quickest) / span * 0.67;
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 10,
                              width: box.maxWidth * f,
                              decoration: BoxDecoration(
                                color: x == fastest ? scheme.primary : scheme.primary.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (hasHr)
                      SizedBox(width: 44, child: Text(x.avgHr == null ? '–' : '${x.avgHr}', textAlign: TextAlign.end)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
