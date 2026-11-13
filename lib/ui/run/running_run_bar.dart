import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../run/geo.dart';
import '../../workout/stats.dart';
import 'run_start.dart';
import '../../units/units.dart';

/// Shown above the tabs while a run is being recorded. Tap to go back to it.
class RunningRunBar extends StatelessWidget {
  const RunningRunBar({super.key});

  @override
  Widget build(BuildContext context) {
    final run = Services.of(context).run;
    return ListenableBuilder(
      listenable: run,
      builder: (context, _) {
        if (!run.active) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final text = Theme.of(context).textTheme;
        return Material(
          color: scheme.tertiaryContainer,
          child: InkWell(
            key: const Key('runningRunBar'),
            onTap: () => openLiveRun(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  const Icon(Icons.directions_run, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    // Only the numbers rebuild every second.
                    child: ValueListenableBuilder<int>(
                      valueListenable: run.ticks,
                      builder: (context, _, _) => Text(
                        [
                          run.paused ? 'Run paused' : 'Run',
                          '${formatKm(run.distanceM)} ${Units.d}',
                          formatDuration(run.moving),
                        ].join(' · '),
                        style: text.titleSmall,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_up),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
