import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../run/geo.dart';
import '../../workout/stats.dart';
import '../hr_presets.dart';

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
        Text('Map, km splits and records are coming next.', textAlign: TextAlign.center, style: text.bodySmall),
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
