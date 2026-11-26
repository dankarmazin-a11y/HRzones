import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/exercise_repository.dart';
import '../../hr/ble_hr_source.dart';
import '../../hr/hr_monitor.dart';
import '../../run/location_source.dart';
import '../../beep/sounds.dart';
import '../hr_presets.dart';
import '../timer_style.dart';
import '../screens/settings_screen.dart';
import '../screens/workouts_screen.dart';
import 'live_run_screen.dart';
import 'run_summary_screen.dart' show activityWord, runTitle;
import '../theme/emblems.dart';
import '../../run/geo.dart';
import '../../units/units.dart';
import 'pace_alert.dart';
import '../../run/run_plan.dart';
import '../../run/run_session.dart';
import '../../live/live_activity.dart';
import '../../data/shoe_repository.dart';
import 'shoes.dart' show editShoe;
import 'bike_sensors_sheet.dart';
import '../../platform/phone_system.dart';
import '../battery_guide.dart';
import '../one_line.dart';

/// Start a run: the "Ready to run" sheet (heart-rate zone), location
/// permission, a vibration, then the live run screen.
Future<void> startRun(BuildContext context, {Run? ghostOf, RunPlan? plan}) async {
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
  final choice = await showModalBottomSheet<RunSetup>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ReadyToRunSheet(ghostOf: ghostOf, plan: plan),
  );
  if (choice == null || !context.mounted) return;
  await s.db.setSetting('runPresetId', choice.preset?.id ?? '');
  await s.db.setSetting('runTreadmill', choice.treadmill ? '1' : '0');
  await s.db.setSetting('runActivity', choice.activity.name);
  // Permission first, so the iPhone question doesn't interrupt the countdown.
  // (A treadmill run doesn't use GPS.)
  final access = choice.treadmill ? LocationAccess.granted : await s.run.location.ensureAccess();
  if (!context.mounted) return;
  if (access == LocationAccess.granted) {
    // Android: steps / cadence need "Physical activity"; the workout card needs notifications;
    // Samsung & co. must not stop the app with the screen off (asked once).
    // (Skipped where there is no native side: iPhone, web, tests.)
    if (isAndroidApp && PhoneSystem.hasNative) {
      await PhoneSystem.activity();
      await s.askNotificationsOnce(force: await s.db.getSetting('notifyAsked') != '1');
      if (!context.mounted) return;
      await askBatteryOnce(context);
      if (!context.mounted) return;
    }
    final preset = s.zonesEnabled.value ? choice.preset : null;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RunCountdownScreen(
          preset: preset,
          treadmill: choice.treadmill,
          shoeId: choice.shoeId,
          ghostOf: choice.treadmill ? null : ghostOf,
          plan: plan,
          activity: choice.activity,
        ),
        fullscreenDialog: true,
      ),
    );
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Location needed'),
      content: Text(switch (access) {
        LocationAccess.serviceOff =>
          isAndroidApp
              ? 'Location is off. Turn it on in the quick settings (swipe down from the top) or phone Settings › Location.'
              : 'Location Services are off. Turn them on in the iPhone Settings › Privacy & Security › Location Services.',
        _ =>
          'HR Zones needs your location to record the route, distance and pace. '
              '${isAndroidApp ? 'In $appSettingsPath › Permissions › Location choose "Allow only while using the app".' : 'In Settings › HR Zones › Location choose "While Using the App".'}',
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
      title: const Text('Cardio in progress'),
      content: const Text('Finish your run, walk or ride before you start a strength workout.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('OK')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Open it')),
      ],
    ),
  );
  if (open == true && context.mounted) await openLiveRun(context);
  return false;
}

/// A noticeable buzz – you feel it with the phone in an armband or pocket.
/// Once when a run starts, pauses or resumes; twice when it finishes.
void runVibration({int times = 1}) {
  for (var i = 0; i < times; i++) {
    i == 0 ? HapticFeedback.vibrate() : Timer(Duration(milliseconds: 600 * i), HapticFeedback.vibrate);
  }
}

/// Length of the countdown before a run starts (0 in some tests).
int runCountdownSeconds = 3;

/// 3-2-1 before the run starts: big white digits, a tick each second, then
/// the run starts with a vibration and the live screen takes over. Tap ✕ to
/// cancel, or "Start now" to skip the countdown.
class RunCountdownScreen extends StatefulWidget {
  const RunCountdownScreen({
    super.key,
    this.preset,
    this.treadmill = false,
    this.shoeId,
    this.ghostOf,
    this.plan,
    this.activity = RunActivity.run,
  });

  final HrPreset? preset;

  /// Run, walk or hike (picked in the Ready sheet).
  final RunActivity activity;
  final bool treadmill;
  final String? shoeId;

  /// Race against this earlier run.
  final Run? ghostOf;

  /// Follow this planned run.
  final RunPlan? plan;

  @override
  State<RunCountdownScreen> createState() => _RunCountdownScreenState();
}

class _RunCountdownScreenState extends State<RunCountdownScreen> {
  late int _left = runCountdownSeconds;
  Timer? _timer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Services can't be read in initState: begin after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _begin() : null);
  }

  LiveActivity? _live;

  void _begin() {
    // owner (22 + 26 Nov): no card on cardio. iOS only lets the app put a card up while it is
    // on screen – the run starts at GO, often after the phone was locked. So the card goes up
    // now ("Get ready" counting down) and the run only updates it.
    final s = Services.of(context);
    if (!s.run.active) {
      final now = DateTime.now();
      _live = s.live;
      s.live.start(
        'run',
        RunSession.cardName(plan: widget.plan?.name, treadmill: widget.treadmill, activity: widget.activity),
        LiveCard(
          title: 'Get ready',
          detail: RunSession.cardName(treadmill: widget.treadmill, activity: widget.activity),
          clockStart: now,
          countdownStart: now,
          countdownEnd: now.add(Duration(seconds: _left)),
          countdownLabel: 'Starting',
        ),
      );
    }
    if (_left <= 0) {
      _go();
      return;
    }
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (--_left <= 0) {
        _go();
      } else {
        setState(() {});
        _tick();
      }
    });
  }

  void _tick() {
    Services.of(context).hr.beeper.play(SoundEvent.intervalTick);
    HapticFeedback.lightImpact();
  }

  Future<void> _go() async {
    if (_started) return;
    _started = true;
    _timer?.cancel();
    setState(() => _left = 0); // "GO"
    final s = Services.of(context);
    final nav = Navigator.of(context);
    s.hr.beeper.play(SoundEvent.intervalWork);
    final g = widget.ghostOf;
    final ghost = g == null ? null : await s.runs.ghostOf(g);
    final access = await s.run.start(
      preset: widget.preset,
      treadmill: widget.treadmill,
      shoeId: widget.shoeId,
      ghost: ghost,
      plan: widget.plan,
      activity: widget.activity,
    );
    if (!mounted) return;
    if (access != LocationAccess.granted) {
      if (!s.run.active) s.live.end(kind: 'run');
      nav.pop();
      return;
    }
    runVibration();
    await nav.pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const LiveRunScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Cancelled before GO (or no location): take the "Get ready" card away.
    if (!_started) _live?.end(kind: 'run');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TimerStyle.neutralBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          key: const Key('cancelCountdown'),
          tooltip: 'Cancel',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Text(
              'Get ready',
              style: TextStyle(color: TimerStyle.readyAccent, fontSize: 28, fontWeight: FontWeight.w700),
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  child: Text(
                    _left > 0 ? '$_left' : 'GO',
                    key: const Key('runCountdown'),
                    style: TimerStyle.digits.copyWith(fontSize: 260),
                  ),
                ),
              ),
            ),
            TextButton(
              key: const Key('startNow'),
              onPressed: _go,
              child: const Text('Start now', style: TextStyle(color: Colors.white70, fontSize: 18)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// What the "Ready to run" sheet returns.
class RunSetup {
  const RunSetup({this.preset, this.treadmill = false, this.shoeId, this.activity = RunActivity.run});

  final HrPreset? preset;
  final bool treadmill;
  final String? shoeId;
  final RunActivity activity;
}

/// Before a run: outdoor or treadmill, the heart-rate zone (or none), then
/// Start. The last choices are remembered (settings `runPresetId`,
/// `runTreadmill`). Returns null if closed.
class ReadyToRunSheet extends StatefulWidget {
  const ReadyToRunSheet({super.key, this.ghostOf, this.plan});

  /// "Run this route again": the run to race against.
  final Run? ghostOf;

  /// A planned run to follow.
  final RunPlan? plan;

  @override
  State<ReadyToRunSheet> createState() => _ReadyToRunSheetState();
}

class _ReadyToRunSheetState extends State<ReadyToRunSheet> {
  List<HrPreset> _presets = const [];
  String? _selected;
  bool _loaded = false;
  bool _treadmill = false;
  RunActivity _activity = RunActivity.run;
  List<ShoeKm> _shoes = const [];
  List<ShoeKm> _bikes = const [];
  String? _bikeId;
  String? _shoeId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load(initial: true);
    }
  }

  Future<void> _load({bool initial = false}) async {
    final s = Services.of(context);
    final presets = await s.presets.forUse(PresetUse.run);
    final last = initial ? await s.db.getSetting('runPresetId') : _selected;
    if (initial) _treadmill = await s.db.getSetting('runTreadmill') == '1';
    if (initial) {
      final a = await s.db.getSetting('runActivity');
      _activity = RunActivity.values.where((x) => x.name == a).firstOrNull ?? RunActivity.run;
      if (widget.plan != null || widget.ghostOf != null) _activity = RunActivity.run;
    }
    final shoes = (await s.shoes.all()).where((x) => !x.shoe.retired).toList();
    if (initial) _shoeId = shoes.where((x) => x.shoe.isDefault).firstOrNull?.shoe.id;
    _shoes = shoes;
    final bikes = (await s.shoes.all(kind: GearKind.bike)).where((x) => !x.shoe.retired).toList();
    if (initial) _bikeId = bikes.where((x) => x.shoe.isDefault).firstOrNull?.shoe.id;
    _bikes = bikes;
    if (!mounted) return;
    setState(() {
      _presets = presets;
      _selected = presets.any((p) => p.id == last) ? last : null;
    });
  }

  Future<void> _newPreset() async {
    final before = {for (final p in _presets) p.id};
    await editPreset(context);
    if (!mounted) return;
    await _load();
    final added = _presets.where((p) => !before.contains(p.id)).firstOrNull;
    if (added != null) setState(() => _selected = added.id);
  }

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final hr = HrScope.of(context);
    final text = Theme.of(context).textTheme;
    final source = hr.source is BleHrSource
        ? 'Heart rate from ${(hr.source as BleHrSource).deviceName}'
        : 'Heart rate: simulated – connect a strap in Tools › Heart-rate zones';
    return SafeArea(
      child: ValueListenableBuilder<bool>(
        valueListenable: s.zonesEnabled,
        builder: (context, on, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Ready to ${activityWord(_activity)}', style: text.headlineSmall),
                    const SizedBox(height: 8),
                    _ActivityPicker(value: _activity, onChanged: (a) => setState(() => _activity = a)),
                    if (widget.plan != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${widget.plan!.name}: ${PlanSpec.fromJson(widget.plan!.specJson).description}',
                          key: const Key('planInfo'),
                          style: text.titleSmall,
                        ),
                      ),
                    if (widget.ghostOf != null && !_treadmill)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Racing your run of ${runTitle(widget.ghostOf!)} – you\'ll see and hear if you\'re ahead or behind.',
                          key: const Key('ghostInfo'),
                          style: text.bodyMedium,
                        ),
                      ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      key: const Key('runKind'),
                      segments: [
                        const ButtonSegment(
                          value: false,
                          label: OneLine('Outdoor'),
                          icon: Icon(Icons.landscape_outlined),
                        ),
                        ButtonSegment(
                          value: true,
                          label: OneLine(_activity == RunActivity.ride ? 'Indoor' : 'Treadmill'),
                          icon: const Icon(Icons.home_outlined),
                        ),
                      ],
                      selected: {_treadmill},
                      onSelectionChanged: (v) => setState(() => _treadmill = v.first),
                    ),
                    if (_treadmill)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'No GPS: time and heart rate; you type the distance at the end.',
                          style: text.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      key: const Key('runZonesSwitch'),
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.monitor_heart_outlined),
                      title: const Text('Heart-rate zone beeps'),
                      subtitle: Text(on ? source : 'Off – no beeps during this run'),
                      value: on,
                      onChanged: s.setZonesEnabled,
                    ),
                    if (on) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            key: const Key('runZoneNone'),
                            label: const Text('No zone'),
                            selected: _selected == null,
                            onSelected: (_) => setState(() => _selected = null),
                          ),
                          for (final p in _presets)
                            ChoiceChip(
                              key: Key('runZone_${p.id}'),
                              avatar: const Icon(Icons.favorite, size: 16, color: AppColors.heart),
                              label: Text('${p.name} · ${p.minBpm}–${p.maxBpm}'),
                              selected: _selected == p.id,
                              onSelected: (_) => setState(() => _selected = p.id),
                            ),
                          ActionChip(
                            key: const Key('runZoneNew'),
                            avatar: const Icon(Icons.add, size: 18),
                            label: const Text('New zone'),
                            onPressed: _newPreset,
                          ),
                        ],
                      ),
                      if (_presets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Make a zone (e.g. "Easy run 130–145") to get beeps when you run too hard or too easy.',
                            style: text.bodySmall,
                          ),
                        ),
                      if (_selected != null) const ZoneGoalRow(),
                    ],
                    if (!_treadmill && _activity == RunActivity.run) const PaceAlertRow(),
                    if (!_treadmill && _activity == RunActivity.ride) ...[
                      const SpeedAlertRow(),
                      SwitchListTile(
                        key: const Key('autoPauseRide'),
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.pause_circle_outline),
                        title: const Text('Auto-pause'),
                        subtitle: const Text('Pauses when you stop, goes on when you ride'),
                        value: s.run.autoPauseRide,
                        onChanged: (v) async {
                          await s.setAutoPauseRide(v);
                          setState(() {});
                        },
                      ),
                      SwitchListTile(
                        key: const Key('rideScreenOn'),
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.light_mode_outlined),
                        title: const Text('Keep the screen on'),
                        subtitle: const Text('For a phone on the handlebars'),
                        value: s.rideScreenOn,
                        onChanged: (v) async {
                          await s.setRideScreenOn(v);
                          setState(() {});
                        },
                      ),
                    ],
                    if (_activity != RunActivity.ride)
                      _WalkingOptions(activity: _activity, presets: _presets, zonesOn: on, treadmill: _treadmill),
                    if (_shoes.isNotEmpty && _activity != RunActivity.ride) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(Icons.directions_walk, size: 20),
                          for (final x in _shoes)
                            ChoiceChip(
                              key: Key('runShoe_${x.shoe.id}'),
                              label: Text(x.shoe.name),
                              selected: _shoeId == x.shoe.id,
                              onSelected: (on) => setState(() => _shoeId = on ? x.shoe.id : null),
                            ),
                        ],
                      ),
                    ],
                    if (_activity == RunActivity.ride) ...[
                      const BikeSensorsRow(),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(Icons.directions_bike, size: 20),
                          for (final x in _bikes)
                            ChoiceChip(
                              key: Key('runBike_${x.shoe.id}'),
                              label: Text(x.shoe.name),
                              selected: _bikeId == x.shoe.id,
                              onSelected: (on) => setState(() => _bikeId = on ? x.shoe.id : null),
                            ),
                          if (_bikes.isEmpty)
                            ActionChip(
                              key: const Key('addBikeChip'),
                              avatar: const Icon(Icons.add, size: 18),
                              label: const Text('Add your bike'),
                              onPressed: () async {
                                await editShoe(context, null, GearKind.bike);
                                await _load();
                              },
                            ),
                        ],
                      ),
                    ],
                    const RunVoiceSettings(compact: true),
                  ],
                ),
              ),
            ),
            // Start stays on screen however long the options get.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 64,
                    child: FilledButton.icon(
                      key: const Key('goRun'),
                      icon: const Icon(Icons.play_arrow, size: 32),
                      label: const Text('Start', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      onPressed: () => Navigator.pop(
                        context,
                        RunSetup(
                          preset: on ? _presets.where((p) => p.id == _selected).firstOrNull : null,
                          treadmill: _treadmill,
                          shoeId: _activity == RunActivity.ride ? _bikeId : _shoeId,
                          activity: _activity,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Run · Walk · Hike, big tiles at the top of the Ready sheet.
class _ActivityPicker extends StatelessWidget {
  const _ActivityPicker({required this.value, required this.onChanged});

  final RunActivity value;
  final ValueChanged<RunActivity> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    Widget tile(RunActivity a, EmblemKind e, String label, String hint) {
      final on = a == value;
      return Expanded(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: on ? t.bright : Colors.transparent, width: 2),
          ),
          child: InkWell(
            key: Key('activity_${a.name}'),
            borderRadius: BorderRadius.circular(10),
            onTap: () => onChanged(a),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  EmblemIcon(e, size: 26),
                  const SizedBox(height: 4),
                  Text(label, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(hint, style: text.bodySmall),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tile(RunActivity.run, EmblemKind.run, 'Run', 'pace first'),
        tile(RunActivity.walk, EmblemKind.walk, 'Walk', 'steps first'),
        tile(RunActivity.hike, EmblemKind.hike, 'Hike', 'climb first'),
        tile(RunActivity.ride, EmblemKind.bike, 'Ride', 'speed first'),
      ],
    );
  }
}

/// Walking: notice it by itself, pace beep while walking, the walking
/// heart-rate zone, and "Walking / Running again" said out loud.
class _WalkingOptions extends StatefulWidget {
  const _WalkingOptions({
    required this.activity,
    required this.presets,
    required this.zonesOn,
    required this.treadmill,
  });

  final RunActivity activity;
  final List<HrPreset> presets;
  final bool zonesOn;
  final bool treadmill;

  @override
  State<_WalkingOptions> createState() => _WalkingOptionsState();
}

class _WalkingOptionsState extends State<_WalkingOptions> {
  static const _paces = [600, 630, 660, 720]; // 10:00, 10:30, 11:00, 12:00 /km

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final run = s.run;
    final text = Theme.of(context).textTheme;
    final walkPace = run.walkPaceAlert;
    final summary = [
      run.autoDetect ? 'Noticed by itself' : 'Not noticed',
      if (walkPace != null) 'beep slower than ${formatPace(walkPace.toDouble())}',
      if (run.walkPreset != null) run.walkPreset!.name,
    ].join(' · ');
    // Folded by default so Start stays on screen.
    return ExpansionTile(
      key: const Key('walkingOptions'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: const EmblemIcon(EmblemKind.walk),
      title: const Text('Walking'),
      subtitle: Text(summary),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const Key('autoDetectWalk'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Notice walking by itself'),
          subtitle: Text(
            run.autoDetect
                ? 'Walk breaks are marked, walk alerts take over, and the outing is labelled run or walk at the end'
                : 'Off – the outing keeps what you picked',
          ),
          value: run.autoDetect,
          onChanged: (v) async {
            await s.setAutoDetectWalk(v);
            setState(() {});
          },
        ),
        if (run.autoDetect || widget.activity != RunActivity.run) ...[
          if (!widget.treadmill) ...[
            Text('While walking: beep when slower than', style: text.bodyMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  key: const Key('walkPace_off'),
                  label: const Text('Off'),
                  selected: walkPace == null,
                  onSelected: (_) async {
                    await s.setWalkPaceAlert(null);
                    setState(() {});
                  },
                ),
                for (final p in _paces)
                  ChoiceChip(
                    key: Key('walkPace_$p'),
                    label: Text('${formatPace(p.toDouble())} ${Units.pace}'),
                    selected: walkPace == p,
                    onSelected: (_) async {
                      await s.setWalkPaceAlert(p);
                      setState(() {});
                    },
                  ),
              ],
            ),
          ],
          if (widget.zonesOn && widget.presets.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('While walking: heart-rate zone', style: text.bodyMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  key: const Key('walkZone_same'),
                  label: const Text('Same as running'),
                  selected: run.walkPreset == null,
                  onSelected: (_) async {
                    await s.setWalkPreset(null);
                    setState(() {});
                  },
                ),
                for (final p in widget.presets)
                  ChoiceChip(
                    key: Key('walkZone_${p.id}'),
                    avatar: const Icon(Icons.favorite, size: 16, color: AppColors.heart),
                    label: Text('${p.name} · ${p.minBpm}–${p.maxBpm}'),
                    selected: run.walkPreset?.id == p.id,
                    onSelected: (_) async {
                      await s.setWalkPreset(p);
                      setState(() {});
                    },
                  ),
              ],
            ),
          ],
          if (run.autoDetect)
            SwitchListTile(
              key: const Key('voiceGait'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Say "Walking" / "Running again"'),
              value: run.voice?.gaitChanges ?? false,
              onChanged: (v) async {
                await s.setVoiceGait(v);
                setState(() {});
              },
            ),
        ],
      ],
    );
  }
}

/// Time-in-zone goal for this outing (owner's idea 2, 19 Nov): Off / 10 /
/// 20 / 30 / 45 / 60 minutes; remembered (setting `zoneGoalMin`).
class ZoneGoalRow extends StatefulWidget {
  const ZoneGoalRow({super.key});

  @override
  State<ZoneGoalRow> createState() => _ZoneGoalRowState();
}

class _ZoneGoalRowState extends State<ZoneGoalRow> {
  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Time in zone goal', style: text.labelLarge),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in const [0, 10, 20, 30, 45, 60])
                ChoiceChip(
                  key: Key('zoneGoal_$m'),
                  label: Text(m == 0 ? 'Off' : '$m min'),
                  selected: s.run.zoneGoalMin == m,
                  onSelected: (_) async {
                    await s.setZoneGoal(m);
                    setState(() {});
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
