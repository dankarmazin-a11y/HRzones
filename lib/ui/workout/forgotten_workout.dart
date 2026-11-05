import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../workout/stats.dart';
import '../../workout/workout_session.dart';
import 'active_workout_screen.dart';
import 'workout_summary_screen.dart';

/// Watches for a workout left open ("Still working out?"): when the app
/// comes back to the foreground (e.g. from the reminder notification), at
/// start-up, and once a minute while it is open.
class ForgottenWorkoutWatcher extends StatefulWidget {
  const ForgottenWorkoutWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<ForgottenWorkoutWatcher> createState() => _ForgottenWorkoutWatcherState();
}

class _ForgottenWorkoutWatcherState extends State<ForgottenWorkoutWatcher> {
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(onResume: _check);
  late final Timer _minute = Timer.periodic(const Duration(minutes: 1), (_) => _check());
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _minute;
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _minute.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_asking || !mounted) return;
    final session = Services.of(context).session;
    if (session.active == null || session.idleFor < WorkoutSession.idleAfter) return;
    _asking = true;
    try {
      await askAboutForgottenWorkout(context, session);
    } finally {
      _asking = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// "Still working out?" – finish at the last set, keep going, or (with
/// nothing logged) discard.
Future<void> askAboutForgottenWorkout(BuildContext context, WorkoutSession session) async {
  final w = session.active!;
  final last = session.lastSetAt;
  final idle = session.idleFor;
  final ago = idle.inHours > 0 ? '${idle.inHours} h ${idle.inMinutes % 60} min' : '${idle.inMinutes} min';
  final choice = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (c) => AlertDialog(
      key: const Key('forgottenWorkout'),
      title: const Text('Still working out?'),
      content: Text(
        '"${w.name}" has been open for ${formatDuration(DateTime.now().difference(w.startedAt))} '
        'and nothing changed for $ago.'
        '${last == null ? '' : '\n\nYour last set was at ${TimeOfDay.fromDateTime(last).format(c)}.'}',
      ),
      actions: [
        if (last == null)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(c).colorScheme.error),
            onPressed: () => Navigator.pop(c, 'discard'),
            child: const Text('Discard'),
          ),
        TextButton(
          key: const Key('keepGoing'),
          onPressed: () => Navigator.pop(c, 'keep'),
          child: const Text('Keep going'),
        ),
        if (last != null)
          FilledButton(
            key: const Key('finishAtLastSet'),
            onPressed: () => Navigator.pop(c, 'finish'),
            child: Text('Finish at ${TimeOfDay.fromDateTime(last).format(c)}'),
          ),
      ],
    ),
  );
  if (!context.mounted) return;
  final nav = Navigator.of(context);
  switch (choice) {
    case 'keep':
      await session.keepGoing();
    case 'discard':
      await session.discard();
      nav.popUntil((r) => r.isFirst);
    case 'finish':
      final summary = await session.finish(endedAt: last!.add(const Duration(minutes: 1)));
      if (summary == null || !context.mounted) return;
      nav.popUntil((r) => r.isFirst); // close the workout screen if it is open
      await ActiveWorkoutScreen.offerTemplateUpdate(context, summary.workout);
      if (!context.mounted) return;
      await nav.push(MaterialPageRoute(builder: (_) => WorkoutSummaryScreen(summary: summary, justFinished: true)));
  }
}
