import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/exercise_repository.dart';
import '../../hr/ble_hr_source.dart';
import '../../hr/hr_monitor.dart';
import '../../run/location_source.dart';
import '../hr_presets.dart';
import '../zone_colors.dart';
import '../screens/workouts_screen.dart';
import 'live_run_screen.dart';

/// Start a run: the "Ready to run" sheet (heart-rate zone), location
/// permission, a vibration, then the live run screen.
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
  final choice = await showModalBottomSheet<PresetChoice>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const ReadyToRunSheet(),
  );
  if (choice == null || !context.mounted) return;
  await s.db.setSetting('runPresetId', choice.preset?.id ?? '');
  final access = await s.run.start(preset: s.zonesEnabled.value ? choice.preset : null);
  if (!context.mounted) return;
  if (access == LocationAccess.granted) {
    runVibration(start: true);
    return openLiveRun(context);
  }
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

/// A noticeable buzz when a run starts (once) and finishes (twice) – you
/// feel it with the phone in an armband or pocket.
void runVibration({required bool start}) {
  HapticFeedback.vibrate();
  if (!start) Timer(const Duration(milliseconds: 600), HapticFeedback.vibrate);
}

/// Before a run: pick the heart-rate zone (or none), then Start. The last
/// choice is remembered (setting `runPresetId`). Returns null if closed.
class ReadyToRunSheet extends StatefulWidget {
  const ReadyToRunSheet({super.key});

  @override
  State<ReadyToRunSheet> createState() => _ReadyToRunSheetState();
}

class _ReadyToRunSheetState extends State<ReadyToRunSheet> {
  List<HrPreset> _presets = const [];
  String? _selected;
  bool _loaded = false;

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: ValueListenableBuilder<bool>(
          valueListenable: s.zonesEnabled,
          builder: (context, on, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Ready to run', style: text.headlineSmall),
              const SizedBox(height: 8),
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
                        avatar: Icon(Icons.favorite, size: 16, color: zoneColor(2)),
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
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 64,
                child: FilledButton.icon(
                  key: const Key('goRun'),
                  icon: const Icon(Icons.play_arrow, size: 32),
                  label: const Text('Start', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  onPressed: () => Navigator.pop(
                    context,
                    PresetChoice(on ? _presets.where((p) => p.id == _selected).firstOrNull : null),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
