import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../workout/stats.dart';
import '../../workout/workout_session.dart';
import '../screens/workouts_screen.dart';

/// Shown above the tabs while a workout is running: name, time, % done.
/// Tap to go back into the workout.
class RunningWorkoutBar extends StatefulWidget {
  const RunningWorkoutBar({super.key});

  @override
  State<RunningWorkoutBar> createState() => _RunningWorkoutBarState();
}

class _RunningWorkoutBarState extends State<RunningWorkoutBar> {
  Timer? _tick;
  WorkoutSession? _session;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = Services.of(context).session;
    if (s != _session) {
      _session?.removeListener(_syncTicker);
      _session = s..addListener(_syncTicker);
      _syncTicker();
    }
  }

  /// Ticks once a second only while a workout runs (it used to tick forever,
  /// waking the phone every second for nothing).
  void _syncTicker() {
    final running = _session?.active != null;
    if (running && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!running) {
      _tick?.cancel();
      _tick = null;
    }
  }

  @override
  void dispose() {
    _session?.removeListener(_syncTicker);
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = Services.of(context).session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final w = session.active;
        if (w == null) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final text = Theme.of(context).textTheme;
        final pct = (session.progress * 100).round();
        final rest = session.timer;
        return Material(
          color: scheme.primaryContainer,
          child: InkWell(
            key: const Key('runningWorkoutBar'),
            onTap: () => openActiveWorkout(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: session.progress, minHeight: 3),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
                            Text(
                              [
                                formatDuration(DateTime.now().difference(w.startedAt)),
                                '$pct% done',
                                if (rest != null)
                                  '${rest.label} ${formatDuration(Duration(seconds: rest.countsDown ? rest.remaining : rest.elapsed))}',
                              ].join(' · '),
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_up),
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
