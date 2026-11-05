import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/run_repository.dart';
import '../../run/best_efforts.dart';
import '../../run/geo.dart';
import '../../workout/stats.dart';
import 'run_summary_screen.dart';

String _time(double seconds) => formatDuration(Duration(seconds: seconds.round()));

/// Run tab: fastest 1 km / 5 km / 10 km / half marathon and the longest run.
/// Tap one to open the run it was set in.
class RunRecordsCard extends StatelessWidget {
  const RunRecordsCard({super.key, required this.runs});

  /// The finished runs (the card reloads when they change).
  final List<Run> runs;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    return FutureBuilder<RunRecords>(
      // Keyed by the runs, so it is worked out again after a new run.
      key: ValueKey(runs.map((r) => r.id).join()),
      future: s.runs.records(),
      builder: (context, snap) {
        final r = snap.data;
        if (r == null) return const SizedBox(height: 120);
        Widget row(String label, RunRecord? rec, String Function(RunRecord) value, Key key) => ListTile(
          key: key,
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.emoji_events_outlined, color: rec == null ? Theme.of(context).disabledColor : null),
          title: Text(label),
          subtitle: rec == null ? null : Text(runTitle(rec.run)),
          trailing: Text(rec == null ? '–' : value(rec), style: text.titleMedium),
          onTap: rec == null
              ? null
              : () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => RunSummaryScreen(runId: rec.run.id))),
        );
        return Card(
          key: const Key('runRecords'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Records', style: text.titleMedium),
                for (final e in recordDistances.entries)
                  row(e.value, r.fastest[e.key], (x) => _time(x.value), Key('record_${e.key}')),
                row('Longest run', r.longest, (x) => '${formatKm(x.value)} km', const Key('record_longest')),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Run summary: the records this run set ("New record") and its best
/// times at the record distances.
class RunBestsCard extends StatelessWidget {
  const RunBestsCard({super.key, required this.run});

  final Run run;

  Future<(Map<int, double>, RunRecords)> _load(AppServices s) async =>
      (await s.runs.bestsFor(run), await s.runs.records(before: run.startedAt, excludeId: run.id));

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<(Map<int, double>, RunRecords)>(
      future: _load(s),
      builder: (context, snap) {
        final data = snap.data;
        if (data == null || data.$1.isEmpty) return const SizedBox.shrink();
        final (bests, before) = data;
        return Card(
          key: const Key('runBests'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Best efforts', style: text.titleMedium),
                const SizedBox(height: 4),
                for (final e in recordDistances.entries)
                  if (bests[e.key] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(e.value)),
                          if (before.fastest[e.key] != null && bests[e.key]! < before.fastest[e.key]!.value)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                key: Key('newRecord_${e.key}'),
                                avatar: const Icon(Icons.emoji_events, size: 16),
                                label: const Text('New record'),
                                backgroundColor: scheme.tertiaryContainer,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          Text(_time(bests[e.key]!), style: text.titleMedium),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
