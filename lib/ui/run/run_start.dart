import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../run/location_source.dart';
import '../hr_presets.dart';
import '../screens/workouts_screen.dart';
import 'live_run_screen.dart';

/// Start a run: asks for a heart-rate zone (if there are run presets) and for
/// location permission, then opens the live run screen.
Future<void> startRun(BuildContext context) async {
  final s = Services.of(context);
  if (s.run.active) return openLiveRun(context);
  if (s.session.active != null) {
    final open = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Strength workout running'),
        content: const Text('Finish your strength workout before you start a run.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('OK')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Open workout')),
        ],
      ),
    );
    if (open == true && context.mounted) await openActiveWorkout(context);
    return;
  }
  final choice = await pickPreset(context, PresetUse.run);
  if (choice == null || !context.mounted) return;
  final access = await s.run.start(preset: choice.preset);
  if (!context.mounted) return;
  if (access == LocationAccess.granted) return openLiveRun(context);
  await showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Location needed'),
      content: Text(switch (access) {
        LocationAccess.serviceOff =>
          'Location Services are off. Turn them on in the iPhone Settings › Privacy & Security › Location Services.',
        _ =>
          'HR Zones needs your location to record the route, distance and pace. '
              'In Settings › HR Zones › Location choose "While Using the App".',
      }),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Not now')),
        if (access != LocationAccess.serviceOff)
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              s.run.location.openSettings();
            },
            child: const Text('Open Settings'),
          ),
      ],
    ),
  );
}

Future<void> openLiveRun(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LiveRunScreen(), fullscreenDialog: true));

/// Before a strength workout starts: a run being recorded must be finished
/// first. Returns true when there is no run.
Future<bool> confirmNoRun(BuildContext context) async {
  if (!Services.of(context).run.active) return true;
  final open = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Run in progress'),
      content: const Text('Finish your run before you start a strength workout.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('OK')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Open run')),
      ],
    ),
  );
  if (open == true && context.mounted) await openLiveRun(context);
  return false;
}
