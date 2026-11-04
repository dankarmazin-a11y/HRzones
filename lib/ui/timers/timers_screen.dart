import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/preset_repository.dart';
import '../../workout/interval_runner.dart';
import '../../workout/stats.dart';
import '../number_input.dart';
import 'interval_editor_screen.dart';
import 'interval_run_screen.dart';

/// Interval timers: built-in and your own presets, plus a quick countdown.
class TimersScreen extends StatelessWidget {
  const TimersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Timers')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('newTimer'),
        icon: const Icon(Icons.add),
        label: const Text('New timer'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IntervalEditorScreen())),
      ),
      body: StreamBuilder<List<IntervalPreset>>(
        stream: s.intervals.watchAll(),
        builder: (context, snap) {
          final list = snap.data ?? const <IntervalPreset>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text('Quick', style: text.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sec in [30, 60, 90, 120, 180, 300])
                    ActionChip(
                      label: Text(sec < 60 ? '$sec s' : (sec % 60 == 0 ? '${sec ~/ 60} min' : formatRest(sec))),
                      onPressed: () => runQuick(context, sec),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.edit, size: 16),
                    label: const Text('Custom'),
                    onPressed: () async {
                      final v = await promptNumber(
                        context,
                        title: 'Countdown (seconds)',
                        initial: 60,
                        min: 1,
                        max: 7200,
                      );
                      if (v != null && context.mounted) runQuick(context, v.round());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Interval timers', style: text.titleMedium),
              const SizedBox(height: 8),
              for (final p in list) _PresetCard(preset: p),
            ],
          );
        },
      ),
    );
  }
}

/// "8 × (Work 20 s · Rest 10 s) · 4:00"
String intervalSummary(List<IntervalSegment> segments, int rounds) {
  final parts = segments.map((x) => '${x.label} ${formatRest(x.seconds)}').join(' · ');
  final total = formatDuration(Duration(seconds: totalSeconds(segments, rounds)));
  return rounds > 1 ? '$rounds × ($parts) · $total' : '$parts · $total';
}

void runQuick(BuildContext context, int seconds) => runIntervals(
  context,
  name: 'Countdown',
  rounds: 1,
  segments: [IntervalSegment(label: 'Countdown', seconds: seconds)],
);

void runIntervals(
  BuildContext context, {
  required String name,
  required int rounds,
  required List<IntervalSegment> segments,
}) {
  final runner = IntervalRunner(
    name: name,
    rounds: rounds,
    steps: expandSegments(segments, rounds),
    beeper: Services.of(context).hr.beeper,
  );
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => IntervalRunScreen(runner: runner), fullscreenDialog: true));
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({required this.preset});

  final IntervalPreset preset;

  @override
  Widget build(BuildContext context) {
    final segments = decodeSegments(preset.segmentsJson);
    final repo = Services.of(context).intervals;
    return Card(
      child: ListTile(
        title: Text(preset.name),
        subtitle: Text(intervalSummary(segments, preset.rounds)),
        leading: IconButton.filledTonal(
          tooltip: 'Start',
          icon: const Icon(Icons.play_arrow),
          onPressed: () => runIntervals(context, name: preset.name, rounds: preset.rounds, segments: segments),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            switch (v) {
              case 'edit':
                await Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => IntervalEditorScreen(existing: preset)));
              case 'duplicate':
                await repo.save(name: '${preset.name} (copy)', rounds: preset.rounds, segments: segments);
              case 'delete':
                await repo.delete(preset.id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => runIntervals(context, name: preset.name, rounds: preset.rounds, segments: segments),
      ),
    );
  }
}
