import 'package:flutter/material.dart';

import '../../run/geo.dart';
import '../../run/run_session.dart';
import 'run_summary_screen.dart';

/// "Still running?" – a run still recording without movement for 20 min,
/// or paused for 30 min: finish it where you stopped, keep going, or
/// discard it (when almost nothing was recorded).
Future<void> askAboutForgottenRun(BuildContext context, RunSession run) async {
  final idle = run.idleFor;
  final pausedAt = run.paused ? run.lastPausedAt : null;
  final end = pausedAt ?? run.lastMoveAt ?? DateTime.now();
  final ago = idle.inHours > 0 ? '${idle.inHours} h ${idle.inMinutes % 60} min' : '${idle.inMinutes} min';
  final choice = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (c) => AlertDialog(
      key: const Key('forgottenRun'),
      title: const Text('Still running?'),
      content: Text(
        '${pausedAt != null ? 'Your run has been paused for $ago.' : 'Your run is still recording, but you haven\'t moved for $ago.'}'
        '\n\n${formatKm(run.distanceM)} km so far.',
      ),
      actions: [
        if (run.distanceM < 50)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(c).colorScheme.error),
            onPressed: () => Navigator.pop(c, 'discard'),
            child: const Text('Discard'),
          ),
        TextButton(
          key: const Key('keepRunning'),
          onPressed: () => Navigator.pop(c, 'keep'),
          child: const Text('Keep going'),
        ),
        FilledButton(
          key: const Key('finishForgottenRun'),
          onPressed: () => Navigator.pop(c, 'finish'),
          child: Text('Finish at ${TimeOfDay.fromDateTime(end).format(c)}'),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  final nav = Navigator.of(context);
  switch (choice) {
    case 'keep':
      await run.keepGoing();
    case 'discard':
      await run.discard();
      nav.popUntil((r) => r.isFirst);
    case 'finish':
      final id = await run.finish(endAt: end);
      if (id == null || !context.mounted) return;
      nav.popUntil((r) => r.isFirst);
      await nav.push(MaterialPageRoute(builder: (_) => RunSummaryScreen(runId: id)));
  }
}
