import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../workout/workout_session.dart';
import '../number_input.dart';
import 'active_workout_screen.dart';

WorkoutSession _editSession(BuildContext context) {
  final s = Services.of(context);
  return WorkoutSession(workouts: s.workouts, exercises: s.exercises, hr: s.hr, editMode: true);
}

/// Opens a finished workout for editing (replaces the current screen).
Future<void> openWorkoutEditor(BuildContext context, String workoutId) async {
  final session = _editSession(context);
  if (!await session.loadForEdit(workoutId) || !context.mounted) return;
  await Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(session: session), fullscreenDialog: true));
  session.dispose();
}

/// Logs a workout that wasn't recorded live: asks for date, time and length.
Future<void> logPastWorkout(BuildContext context) async {
  final start = await pickWorkoutStart(context, DateTime.now().subtract(const Duration(hours: 1)));
  if (start == null || !context.mounted) return;
  final minutes = await promptNumber(
    context,
    title: 'How long was it? (minutes)',
    initial: 60,
    min: 1,
    max: 600,
    suffix: 'min',
  );
  if (minutes == null || !context.mounted) return;
  final session = _editSession(context)..startManual(start, Duration(minutes: minutes.round()));
  await Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(session: session), fullscreenDialog: true));
  session.dispose();
}
