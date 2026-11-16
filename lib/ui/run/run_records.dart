import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/run_repository.dart';
import '../../run/best_efforts.dart';
import '../../run/geo.dart';
import '../../workout/stats.dart';
import 'run_summary_screen.dart';
import '../../units/units.dart';

String _time(double seconds) => formatDuration(Duration(seconds: seconds.round()));

/// Run tab / Profile: fastest 1 km / 5 km / 10 km / half marathon and the
/// longest run; then walking records (fastest 1 / 5 / 10 km walk, longest
/// walk, most steps) and hike records (biggest climb, longest hike) once there
/// are walks / hikes. Tap one to open the outing it was set in.
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
        final walks = runs.any((x) => x.activity == RunActivity.walk);
        final hikes = runs.any((x) => x.activity == RunActivity.hike);
        final rides = runs.any((x) => x.activity == RunActivity.ride);
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
                row('Longest run', r.longest, (x) => '${formatKm(x.value)} ${Units.d}', const Key('record_longest')),
                if (walks) _ActivityRecords(activity: RunActivity.walk, row: row),
                if (hikes) _ActivityRecords(activity: RunActivity.hike, row: row),
                if (rides) _ActivityRecords(activity: RunActivity.ride, row: row),
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

  // A walk is compared with earlier walks, a run with earlier runs.
  Future<(Map<int, double>, RunRecords)> _load(AppServices s) async => (
    await s.runs.bestsFor(run),
    await s.runs.records(before: run.startedAt, excludeId: run.id, activity: run.activity),
  );

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
                for (final e in recordDistancesFor(ride: run.activity == RunActivity.ride).entries)
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

typedef _Row = Widget Function(String label, RunRecord? rec, String Function(RunRecord) value, Key key);

/// The Walking or Hiking part of the records card.
class _ActivityRecords extends StatelessWidget {
  const _ActivityRecords({required this.activity, required this.row});

  final RunActivity activity;
  final _Row row;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final walk = activity == RunActivity.walk;
    final ride = activity == RunActivity.ride;
    return FutureBuilder<RunRecords>(
      future: Services.of(context).runs.records(activity: activity),
      builder: (context, snap) {
        final r = snap.data;
        if (r == null) return const SizedBox.shrink();
        final name = walk ? 'walk' : (ride ? 'ride' : 'hike');
        return Column(
          key: Key('${name}Records'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              walk ? 'Walking' : (ride ? 'Cycling' : 'Hiking'),
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (ride)
              for (final e in rideRecordDistances.entries)
                row('Fastest ${e.value}', r.fastest[e.key], (x) => _time(x.value), Key('rideRecord_${e.key}')),
            if (walk)
              for (final m in const [1000, 5000, 10000])
                row('Fastest ${recordDistances[m]} walk', r.fastest[m], (x) => _time(x.value), Key('${name}Record_$m')),
            if (!walk) row('Biggest climb', r.biggestClimb, (x) => '${x.value.round()} m', Key('${name}Record_climb')),
            row('Longest $name', r.longest, (x) => '${formatKm(x.value)} ${Units.d}', Key('${name}Record_longest')),
            if (ride)
              row(
                'Top speed',
                r.topSpeed,
                (x) => '${Units.speedOut(x.value).toStringAsFixed(1)} ${Units.speed}',
                const Key('rideRecord_speed'),
              ),
            if (walk)
              row(
                'Most steps in one walk',
                r.mostSteps,
                (x) => formatThousands(x.value.round()),
                const Key('walkRecord_steps'),
              ),
          ],
        );
      },
    );
  }
}

/// "12,310"
String formatThousands(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
