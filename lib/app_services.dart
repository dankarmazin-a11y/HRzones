import 'dart:async';

import 'package:flutter/widgets.dart';

import 'data/database.dart';
import 'data/exercise_repository.dart';
import 'data/template_repository.dart';
import 'data/workout_repository.dart';
import 'hr/hr_monitor.dart';
import 'hr/zones.dart';
import 'workout/workout_session.dart';

/// Everything the screens need: database repositories, HR monitor and the
/// current workout session.
class AppServices {
  AppServices._(this.db, this.hr) : exercises = ExerciseRepository(db), templates = TemplateRepository(db) {
    workouts = WorkoutRepository(db, exercises);
    session = WorkoutSession(workouts: workouts, exercises: exercises, hr: hr);
  }

  final AppDatabase db;
  final HrMonitor hr;
  final ExerciseRepository exercises;
  final TemplateRepository templates;
  late final WorkoutRepository workouts;
  late final WorkoutSession session;
  Timer? _settingsTimer;

  static Future<AppServices> open({
    required Future<String> Function() loadExercises,
    AppDatabase? db,
    HrMonitor? hr,
  }) async {
    final s = AppServices._(db ?? AppDatabase(), hr ?? HrMonitor());
    await s.exercises.seedIfNeeded(loadExercises);
    await s._loadSettings();
    await s.session.restore();
    return s;
  }

  Future<void> _loadSettings() async {
    Future<int?> getInt(String k) async => int.tryParse(await db.getSetting(k) ?? '');
    final age = await getInt('age');
    final min = await getInt('rangeMin'), max = await getInt('rangeMax');
    final cooldown = await getInt('cooldownS');
    final volume = double.tryParse(await db.getSetting('volume') ?? '');
    if (age != null) hr.setAge(age);
    if (min != null && max != null && min < max) hr.setRange(HrRange(min: min, max: max));
    if (cooldown != null) hr.setCooldown(Duration(seconds: cooldown));
    if (volume != null) hr.setVolume(volume);
    hr.onSettingsChanged = () {
      _settingsTimer?.cancel();
      _settingsTimer = Timer(const Duration(milliseconds: 500), _saveSettings);
    };
  }

  Future<void> _saveSettings() async {
    await db.setSetting('age', '${hr.age}');
    await db.setSetting('rangeMin', '${hr.range.min}');
    await db.setSetting('rangeMax', '${hr.range.max}');
    await db.setSetting('cooldownS', '${hr.settings.cooldown.inSeconds}');
    await db.setSetting('volume', '${hr.volume}');
  }

  Future<void> close() async {
    _settingsTimer?.cancel();
    session.dispose();
    hr.dispose();
    await db.close();
  }
}

class Services extends InheritedWidget {
  const Services({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<Services>()!.services;

  @override
  bool updateShouldNotify(Services oldWidget) => services != oldWidget.services;
}
