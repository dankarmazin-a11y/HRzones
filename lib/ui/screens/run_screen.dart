import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../app_services.dart';
import '../../data/database.dart';
import '../../run/geo.dart';
import '../../workout/stats.dart';
import '../../workout/streak.dart';
import '../run/edit_run_screen.dart';
import '../run/run_plans.dart';
import '../run/weekly_plan.dart';
import '../run/run_progress.dart';
import '../run/run_records.dart';
import '../run/shoes.dart';
import '../run/run_start.dart';
import '../run/run_summary_screen.dart';
import 'zones_screen.dart';
import '../theme/emblems.dart';
import '../guide/get_started.dart';
import '../../units/units.dart';

/// Run tab: start a run, the run in progress, past runs.
class RunScreen extends StatelessWidget {
  const RunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Run'),
        actions: [
          IconButton(
            key: const Key('logRun'),
            tooltip: 'Log a run',
            icon: const Icon(Icons.edit_calendar),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditRunScreen())),
          ),
        ],
      ),
      // The big Run button sits at the bottom, always in reach.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ListenableBuilder(
            listenable: s.run,
            builder: (context, _) => SizedBox(
              height: 64,
              child: FilledButton.icon(
                key: const Key('startRun'),
                icon: Icon(s.run.active ? Icons.directions_run : Icons.play_arrow, size: 32),
                label: const Text('Run', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                onPressed: () => startRun(context),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Run>>(
        stream: s.runs.watchFinished(),
        builder: (context, snap) {
          final runs = snap.data ?? const <Run>[];
          return ListView(
            // Keep cards that load data built off-screen (no jumping while scrolling).
            scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Emblem(EmblemKind.heart),
                title: const Text('Heart-rate zones'),
                subtitle: const Text('Pick a zone at the start to get beeps when you leave it'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ZonesScreen())),
              ),
              const SizedBox(height: 8),
              const WeeklyPlanCard(),
              const SizedBox(height: 8),
              const RunPlansSection(),
              const SizedBox(height: 8),
              const ShoesCard(),
              const SizedBox(height: 8),
              if (runs.isNotEmpty) ...[
                _Totals(runs: runs),
                const SizedBox(height: 8),
                RunRecordsCard(runs: runs),
                Card(
                  child: ListTile(
                    key: const Key('runProgress'),
                    leading: const Emblem(EmblemKind.route),
                    title: const Text('Progress'),
                    subtitle: const Text('Km per week, pace and fitness charts'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RunProgressScreen())),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Your runs', style: text.titleMedium),
                for (final r in runs) RunTile(run: r),
              ] else
                const RunGetStarted(),
            ],
          );
        },
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.runs});

  final List<Run> runs;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final week = runs.where((r) => !r.startedAt.isBefore(weekStart(now)));
    final km = week.fold(0.0, (a, r) => a + r.distanceM);
    final secs = week.fold(0, (a, r) => a + r.durationS);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This week', style: text.labelLarge),
                  Text('${formatKm(km)} ${Units.d}', key: const Key('weekKm'), style: text.headlineSmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${week.length} ${week.length == 1 ? 'run' : 'runs'}', style: text.bodyMedium),
                Text(formatDuration(Duration(seconds: secs)), style: text.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RunTile extends StatelessWidget {
  const RunTile({super.key, required this.run});

  final Run run;

  @override
  Widget build(BuildContext context) {
    final pace = paceSecPerKm(run.distanceM, run.durationS.toDouble());
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Emblem(run.kind == RunKind.treadmill ? EmblemKind.stopwatch : EmblemKind.run),
      title: Text('${formatKm(run.distanceM)} ${Units.d}'),
      subtitle: HeartText(
        '${runTitle(run)}${run.kind == RunKind.treadmill ? ' · treadmill' : ''}\n'
        '${formatDuration(Duration(seconds: run.durationS))} · ${formatPace(pace)} ${Units.pace}'
        '${run.effort == null ? '' : ' · effort ${run.effort}/10'}'
        '${run.avgHr == null ? '' : ' · ♥ ${run.avgHr}'}',
      ),
      isThreeLine: true,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RunSummaryScreen(runId: run.id))),
    );
  }
}
