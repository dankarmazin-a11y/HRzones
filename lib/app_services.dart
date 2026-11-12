import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'ui/theme/app_theme.dart';

import 'beep/sounds.dart';
import 'data/body_repository.dart';
import 'data/database.dart';
import 'data/goal_repository.dart';
import 'data/preset_repository.dart';
import 'data/run_plan_repository.dart';
import 'data/training_plan_repository.dart';
import 'data/run_repository.dart';
import 'data/shoe_repository.dart';
import 'workout/training_level.dart';
import 'workout/training_place.dart';
import 'data/exercise_repository.dart';
import 'data/template_repository.dart';
import 'data/workout_repository.dart';
import 'hr/ble_hr_source.dart';
import 'hr/hr_monitor.dart';
import 'hr/zones.dart';
import 'live/live_activity.dart';
import 'notify/rest_notifier.dart';
import 'run/location_source.dart';
import 'run/motion_source.dart';
import 'run/run_session.dart';
import 'run/run_voice.dart';
import 'workout/workout_session.dart';

/// Everything the screens need: database repositories, HR monitor and the
/// current workout session.
class AppServices {
  AppServices._(this.db, this.hr, this._loadExercises, this.restNotifier, LocationSource? location)
    : exercises = ExerciseRepository(db),
      runs = RunRepository(db),
      shoes = ShoeRepository(db),
      runPlans = RunPlanRepository(db),
      trainingPlans = TrainingPlanRepository(db),
      templates = TemplateRepository(db),
      body = BodyRepository(db),
      presets = HrPresetRepository(db),
      intervals = IntervalPresetRepository(db) {
    workouts = WorkoutRepository(db, exercises);
    intervals.onExercisesChanged = exercises.clearCache;
    session = WorkoutSession(workouts: workouts, exercises: exercises, hr: hr)
      ..presets = presets
      ..restNotifier = restNotifier
      ..intervals = intervals;
    goals = GoalRepository(db, workouts, exercises, body, runs);
    run = RunSession(runs: runs, hr: hr, location: location, motion: location == null ? MotionSource.create() : null)
      ..voice = RunVoice(hr.beeper.speak)
      ..notifier = restNotifier
      ..plans = runPlans.byId;
    session.locationFor = () => run.location;
    session.live = live;
    run.live = live;
    live.onAction = session.handleCardAction;
    void accent() =>
        live.accent = (palette.value.bright.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
    accent();
    palette.addListener(accent);
  }

  /// The workout card on the lock screen / Dynamic Island (strength or run).
  final LiveActivity live = LiveActivity.create();

  final RunRepository runs;
  final ShoeRepository shoes;
  final RunPlanRepository runPlans;

  /// The weekly running plan (Run tab, Home "Today's run").
  final TrainingPlanRepository trainingPlans;

  /// Target pace range in s/km for pace beeps (setting `runPaceAlert`,
  /// "330-350"; empty = off).
  Future<void> setPaceAlert(HrRange? range) async {
    run.paceAlert = range;
    await db.setSetting('runPaceAlert', range == null ? '' : '${range.min}-${range.max}');
  }

  /// Voice updates during runs (setting `runVoice`, default on) every
  /// [RunVoice.everyM] metres (setting `runVoiceEvery`, default 1000).
  Future<void> setRunVoice({bool? on, int? everyM, Set<VoiceItem>? items, String? kind, bool? spokenAlerts}) async {
    final v = run.voice!;
    if (items != null) {
      v.items = items;
      await db.setSetting('runVoiceItems', items.map((i) => i.name).join(','));
    }
    if (kind != null) {
      v.kind = kind;
      await db.setSetting('runVoiceKind', kind);
    }
    if (spokenAlerts != null) {
      v.spokenAlerts = spokenAlerts;
      await db.setSetting('spokenAlerts', spokenAlerts ? '1' : '0');
    }
    if (on != null) {
      v.enabled = on;
      await db.setSetting('runVoice', on ? '1' : '0');
    }
    if (everyM != null) {
      v.everyM = everyM;
      await db.setSetting('runVoiceEvery', '$everyM');
    }
  }

  /// The run being recorded (GPS).
  late final RunSession run;

  final AppDatabase db;
  final HrMonitor hr;
  final ExerciseRepository exercises;
  final TemplateRepository templates;
  final BodyRepository body;
  final HrPresetRepository presets;
  final IntervalPresetRepository intervals;

  /// Light / dark / follow the phone (setting `theme`, default: follow the phone).
  final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Colour theme Mint / Orange / Pink (setting `palette`, default Orange).
  final palette = ValueNotifier<AppPalette>(AppPalette.fallback);

  Future<void> setPalette(AppPalette p) async {
    palette.value = p;
    await db.setSetting('palette', p.name);
  }

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

  /// "Still working out?" reminder for a workout left open (setting
  /// `idleReminder`, default on).
  Future<void> setIdleReminder(bool on) async {
    session.idleReminder = on;
    if (on) await askNotificationsOnce(force: true);
    await db.setSetting('idleReminder', on ? '1' : '0');
    await session.flush(); // (re)schedules or cancels the reminder
  }

  /// Asks iOS for notification permission the first time a workout starts
  /// (setting `notifyAsked`), so the forgotten-workout reminder can work.
  Future<void> askNotificationsOnce({bool force = false}) async {
    if (!force && (!session.idleReminder || await db.getSetting('notifyAsked') == '1')) return;
    await db.setSetting('notifyAsked', '1');
    await restNotifier.requestPermission();
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
    await run.restore();
  }

  /// First launch: show the setup walk-through (level, place, age, …).
  /// Setting `onboarded`; only checked for the real app database.
  final needsOnboarding = ValueNotifier<bool>(false);

  /// The walk-through was finished or skipped.
  Future<void> finishOnboarding() async {
    needsOnboarding.value = false;
    await db.setSetting('onboarded', '1');
  }

  /// "What do you train?" from the walk-through: strength, running or both.
  Future<void> setFocus(String focus) => db.setSetting('focus', focus);

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
    LocationSource? location,
  }) async {
    final s = AppServices._(
      db ?? AppDatabase(),
      hr ?? HrMonitor(),
      loadExercises,
      restNotifier ?? (db == null ? RestNotifier.create() : SilentRestNotifier()),
      location ?? (db == null ? null : SimulatedLocationSource()),
    );
    // Each step is reported so a stuck start-up shows where it hangs.
    onStep?.call('Opening the database');
    await s.db.customSelect('SELECT 1').get();
    onStep?.call('Loading the exercise list');
    await s.exercises.seedIfNeeded(loadExercises);
    onStep?.call('Loading timers');
    await s.intervals.seedDefaults();
    await s.intervals.syncExercises(); // interval timers usable as exercises
    await s.runPlans.seedDefaults();
    onStep?.call('Loading settings');
    await s._loadSettings();
    s.session.zonesEnabled = s.zonesEnabled.value;
    // A new user gets the walk-through; someone who already logged
    // workouts (from before it existed) doesn't.
    if (db == null && await s.db.getSetting('onboarded') != '1') {
      final hasHistory =
          (await s.workouts.watchFinished().first).isNotEmpty || (await s.runs.watchFinished().first).isNotEmpty;
      if (hasHistory) {
        await s.db.setSetting('onboarded', '1');
      } else {
        s.needsOnboarding.value = true;
      }
    }
    onStep?.call('Restoring your workout');
    await s.session.restore();
    await s.run.restore();
    return s;
  }

  Future<void> _loadSettings() async {
    Future<int?> getInt(String k) async => int.tryParse(await db.getSetting(k) ?? '');
    weeklyTarget.value = await getInt('weeklyTarget') ?? 3;
    final theme = await db.getSetting('theme');
    themeMode.value = ThemeMode.values.where((m) => m.name == theme).firstOrNull ?? ThemeMode.system;
    palette.value = AppPalette.byName(await db.getSetting('palette'));
    final placeName = await db.getSetting('place');
    place.value = TrainingPlace.values.where((p) => p.name == placeName).firstOrNull ?? TrainingPlace.gym;
    zonesEnabled.value = await db.getSetting('zones') != '0';
    lastBackupAt.value = DateTime.tryParse(await db.getSetting('lastBackupAt') ?? '');
    session.vibrateRestOver = await db.getSetting('restVibrate') != '0';
    session.notifyRestOver = await db.getSetting('restNotify') == '1';
    session.idleReminder = await db.getSetting('idleReminder') != '0';
    run.voice!
      ..enabled = await db.getSetting('runVoice') != '0'
      ..everyM = await getInt('runVoiceEvery') ?? 1000
      ..kind = await db.getSetting('runVoiceKind') ?? 'default'
      ..spokenAlerts = await db.getSetting('spokenAlerts') != '0';
    final items = await db.getSetting('runVoiceItems');
    if (items != null) {
      run.voice!.items = {for (final n in items.split(',')) ?VoiceItem.values.where((i) => i.name == n).firstOrNull};
    }
    final pace = (await db.getSetting('runPaceAlert'))?.split('-');
    final pMin = int.tryParse(pace?.firstOrNull ?? ''), pMax = int.tryParse(pace?.lastOrNull ?? '');
    run.paceAlert = pMin != null && pMax != null && pMin < pMax ? HrRange(min: pMin, max: pMax) : null;
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
    run.dispose();
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
