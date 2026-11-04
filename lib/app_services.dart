import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'beep/sounds.dart';
import 'data/body_repository.dart';
import 'data/database.dart';
import 'data/goal_repository.dart';
import 'data/preset_repository.dart';
import 'workout/training_level.dart';
import 'workout/training_place.dart';
import 'data/exercise_repository.dart';
import 'data/template_repository.dart';
import 'data/workout_repository.dart';
import 'hr/ble_hr_source.dart';
import 'hr/hr_monitor.dart';
import 'hr/zones.dart';
import 'notify/rest_notifier.dart';
import 'workout/workout_session.dart';

/// Everything the screens need: database repositories, HR monitor and the
/// current workout session.
class AppServices {
  AppServices._(this.db, this.hr, this._loadExercises, this.restNotifier)
    : exercises = ExerciseRepository(db),
      templates = TemplateRepository(db),
      body = BodyRepository(db),
      presets = HrPresetRepository(db),
      intervals = IntervalPresetRepository(db) {
    workouts = WorkoutRepository(db, exercises);
    session = WorkoutSession(workouts: workouts, exercises: exercises, hr: hr)
      ..presets = presets
      ..restNotifier = restNotifier;
    goals = GoalRepository(db, workouts, exercises, body);
  }

  final AppDatabase db;
  final HrMonitor hr;
  final ExerciseRepository exercises;
  final TemplateRepository templates;
  final BodyRepository body;
  final HrPresetRepository presets;
  final IntervalPresetRepository intervals;

  /// Light / dark / system (setting `theme`, default light).
  final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Training level (setting `level`, default intermediate).
  final level = ValueNotifier<TrainingLevel>(TrainingLevel.intermediate);

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode.value = m;
    await db.setSetting('theme', m.name);
  }

  Future<void> setLevel(TrainingLevel l) async {
    level.value = l;
    await db.setSetting('level', l.name);
  }

  /// Where the user trains (setting `place`, default gym).
  final place = ValueNotifier<TrainingPlace>(TrainingPlace.gym);

  Future<void> setPlace(TrainingPlace p) async {
    place.value = p;
    await db.setSetting('place', p.name);
  }

  /// The place whose equipment the exercise list shows. Hybrid: the place
  /// picked for the running workout (in a workout), otherwise everything.
  TrainingPlace effectivePlace({bool inWorkout = false}) {
    final p = place.value;
    if (p != TrainingPlace.hybrid) return p;
    return inWorkout ? (session.workoutPlace ?? TrainingPlace.hybrid) : TrainingPlace.hybrid;
  }

  /// Heart-rate zones on/off (setting `zones`, default on). Off: no preset
  /// question when a workout starts, no zone row, no automatic monitoring.
  final zonesEnabled = ValueNotifier<bool>(true);

  Future<void> setZonesEnabled(bool on) async {
    zonesEnabled.value = on;
    session.zonesEnabled = on;
    if (!on) await hr.stop();
    await db.setSetting('zones', on ? '1' : '0');
  }

  late final GoalRepository goals;
  final Future<String> Function() _loadExercises;
  final RestNotifier restNotifier;

  /// Sound per event (setting `sounds`, JSON {event: choice}); kept on the
  /// beeper so every part of the app uses it.
  Map<SoundEvent, SoundChoice> get sounds => hr.beeper.choices;

  Future<void> setSound(SoundEvent e, SoundChoice c) async {
    c == SoundChoice.classic ? hr.beeper.choices.remove(e) : hr.beeper.choices[e] = c;
    await db.setSetting('sounds', jsonEncode({for (final x in hr.beeper.choices.entries) x.key.name: x.value.name}));
  }

  /// Light vibration when rest is over (setting `restVibrate`, default on).
  Future<void> setRestVibrate(bool on) async {
    session.vibrateRestOver = on;
    await db.setSetting('restVibrate', on ? '1' : '0');
  }

  /// Notification when rest is over while the phone is locked / in another
  /// app (setting `restNotify`, default off). Turning it on asks iOS once.
  /// Returns false if iOS doesn't allow notifications.
  Future<bool> setRestNotify(bool on) async {
    if (on && !await restNotifier.requestPermission()) return false;
    session.notifyRestOver = on;
    await db.setSetting('restNotify', on ? '1' : '0');
    return true;
  }

  /// When the last backup was saved (setting `lastBackupAt`; not part of
  /// backups).
  final lastBackupAt = ValueNotifier<DateTime?>(null);

  Future<void> setLastBackupAt(DateTime at) async {
    lastBackupAt.value = at;
    await db.setSetting('lastBackupAt', at.toIso8601String());
  }

  /// Re-reads everything after a backup was restored.
  Future<void> reloadAfterRestore() async {
    exercises.clearCache();
    await exercises.seedIfNeeded(_loadExercises); // older backup → newer exercise list
    await intervals.seedDefaults();
    await _loadSettings();
    session.zonesEnabled = zonesEnabled.value;
    await session.restore();
  }

  /// Workouts per week for the streak (setting `weeklyTarget`, default 3).
  final weeklyTarget = ValueNotifier<int>(3);

  Future<void> setWeeklyTarget(int n) async {
    weeklyTarget.value = n;
    await db.setSetting('weeklyTarget', '$n');
  }

  late final WorkoutRepository workouts;
  late final WorkoutSession session;
  Timer? _settingsTimer;

  static Future<AppServices> open({
    required Future<String> Function() loadExercises,
    AppDatabase? db,
    HrMonitor? hr,
    ValueChanged<String>? onStep,
    RestNotifier? restNotifier,
  }) async {
    final s = AppServices._(
      db ?? AppDatabase(),
      hr ?? HrMonitor(),
      loadExercises,
      restNotifier ?? (db == null ? RestNotifier.create() : SilentRestNotifier()),
    );
    // Each step is reported so a stuck start-up shows where it hangs.
    onStep?.call('Opening the database');
    await s.db.customSelect('SELECT 1').get();
    onStep?.call('Loading the exercise list');
    await s.exercises.seedIfNeeded(loadExercises);
    onStep?.call('Loading timers');
    await s.intervals.seedDefaults();
    onStep?.call('Loading settings');
    await s._loadSettings();
    s.session.zonesEnabled = s.zonesEnabled.value;
    onStep?.call('Restoring your workout');
    await s.session.restore();
    return s;
  }

  Future<void> _loadSettings() async {
    Future<int?> getInt(String k) async => int.tryParse(await db.getSetting(k) ?? '');
    weeklyTarget.value = await getInt('weeklyTarget') ?? 3;
    final theme = await db.getSetting('theme');
    themeMode.value = ThemeMode.values.where((m) => m.name == theme).firstOrNull ?? ThemeMode.light;
    final placeName = await db.getSetting('place');
    place.value = TrainingPlace.values.where((p) => p.name == placeName).firstOrNull ?? TrainingPlace.gym;
    zonesEnabled.value = await db.getSetting('zones') != '0';
    lastBackupAt.value = DateTime.tryParse(await db.getSetting('lastBackupAt') ?? '');
    session.vibrateRestOver = await db.getSetting('restVibrate') != '0';
    session.notifyRestOver = await db.getSetting('restNotify') == '1';
    hr.beeper.choices.clear();
    try {
      final saved = jsonDecode(await db.getSetting('sounds') ?? '{}') as Map<String, dynamic>;
      for (final e in SoundEvent.values) {
        final c = SoundChoice.values.where((c) => c.name == saved[e.name]).firstOrNull;
        if (c != null) hr.beeper.choices[e] = c;
      }
    } catch (_) {}
    final lvl = await db.getSetting('level');
    level.value = TrainingLevel.values.where((l) => l.name == lvl).firstOrNull ?? TrainingLevel.intermediate;
    final age = await getInt('age');
    final min = await getInt('rangeMin'), max = await getInt('rangeMax');
    final cooldown = await getInt('cooldownS');
    final volume = double.tryParse(await db.getSetting('volume') ?? '');
    if (age != null) hr.setAge(age);
    if (min != null && max != null && min < max) hr.setRange(HrRange(min: min, max: max));
    if (cooldown != null) hr.setCooldown(Duration(seconds: cooldown));
    if (volume != null) hr.setVolume(volume);
    // Saved heart-rate source: "ble|<id>|<name>" or "simulated".
    final src = (await db.getSetting('hrSource'))?.split('|');
    if (src != null && src.length == 3 && src[0] == 'ble' && bluetoothSupported) {
      await hr.setSource(BleHrSource(deviceId: src[1], deviceName: src[2]));
    }
    hr.onSourceChanged = (s) => db.setSetting(
      'hrSource',
      s is BleHrSource ? 'ble|${s.deviceId}|${s.deviceName.replaceAll('|', ' ')}' : 'simulated',
    );
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
