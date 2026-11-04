import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/template_repository.dart';
import '../../workout/workout_session.dart';
import '../number_input.dart';
import 'active_workout_screen.dart';

WorkoutSession _editSession(BuildContext context) {
  final s = Services.of(context);
  return WorkoutSession(workouts: s.workouts, exercises: s.exercises, hr: s.hr, editMode: true)
    ..defaultRestSeconds = s.session.defaultRestSeconds; // the saved default, not 90 s
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

/// A session for building a template, with the user's saved settings
/// (default rest – it used to always be 1:30 – zone presets).
WorkoutSession templateSession(AppServices s) {
  final session = WorkoutSession(workouts: s.workouts, exercises: s.exercises, hr: s.hr, templateMode: true);
  session.defaultRestSeconds = s.session.defaultRestSeconds;
  session.presets = s.presets;
  session.zonesEnabled = s.zonesEnabled.value;
  return session;
}

/// Builds or edits a template in the same view as a live workout.
Future<void> openTemplateEditor(BuildContext context, TemplateWithSlots? template) async {
  final session = templateSession(Services.of(context));
  await session.loadTemplate(template);
  if (!context.mounted) return;
  await Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(session: session), fullscreenDialog: true));
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
