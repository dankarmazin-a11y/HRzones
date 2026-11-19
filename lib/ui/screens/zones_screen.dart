import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../one_line.dart';
import '../../app_services.dart';
import '../../hr/hr_monitor.dart';
import '../../hr/zone_alert_engine.dart';
import '../../hr/zones.dart';
import '../hr_monitor_card.dart';
import '../hr_presets.dart';
import '../hr_source_section.dart';
import '../number_input.dart';
import '../zone_colors.dart';

/// Heart-rate zones: live monitor with beeps, zones, alerts and the source.
class ZonesScreen extends StatelessWidget {
  const ZonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = HrScope.of(context);
    final s = Services.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('HR Zones')),
      body: ValueListenableBuilder<bool>(
        valueListenable: s.zonesEnabled,
        builder: (context, on, _) => ListView(
          // Keep cards that load data built off-screen (no jumping while scrolling).
          scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: SwitchListTile(
                key: const Key('zonesSwitch'),
                secondary: const Icon(Icons.monitor_heart_outlined),
                title: const Text('Use heart-rate zones'),
                subtitle: Text(
                  on
                      ? 'You can pick a zone preset when a workout starts.'
                      : 'Off: workouts start without asking for a zone, no beeps.',
                ),
                value: on,
                onChanged: s.setZonesEnabled,
              ),
            ),
            const SizedBox(height: 12),
            if (on) ..._details(context, m),
          ],
        ),
      ),
    );
  }

  List<Widget> _details(BuildContext context, HrMonitor m) {
    final text = Theme.of(context).textTheme;
    return [
      Text(
        'Start monitoring before or during any workout. You get 3 high beeps above your range and 2 low '
        'beeps below it – also with the screen locked and music playing.',
        style: text.bodySmall,
      ),
      const SizedBox(height: 8),
      const HrPresetsSection(),
      const SizedBox(height: 16),
      const HrMonitorCard(),
      const SizedBox(height: 16),
      const HrSourceSection(),
      const Divider(height: 32),
      Text('Heart-rate zones', style: text.titleMedium),
      const SizedBox(height: 8),
      Row(
        children: [
          const Text('Age '),
          EditableNumber(value: m.age, title: 'Age', min: 10, max: 100, onChanged: (v) => m.setAge(v.round())),
          if (m.maxHrOverride == null) Text(' → max HR ${m.zones.maxHr} bpm (220 − age)'),
        ],
      ),
      const MaxHrPicker(),
      Slider(
        min: 14,
        max: 80,
        divisions: 66,
        value: m.age.clamp(14, 80).toDouble(),
        label: '${m.age}',
        onChanged: (v) => m.setAge(v.round()),
      ),
      for (final z in m.zones.zones)
        ListTile(
          dense: true,
          leading: CircleAvatar(radius: 10, backgroundColor: zoneColor(z.number)),
          title: Text('Zone ${z.number} · ${z.name}'),
          trailing: Text('${z.minBpm}–${z.maxBpm} bpm'),
        ),
      const Divider(height: 32),
      Text('Alerts', style: text.titleMedium),
      const SizedBox(height: 8),
      Text(
        '3 high beeps above range, 2 low beeps below. '
        'First alert after ${m.settings.grace.inSeconds} s out of range.',
      ),
      const SizedBox(height: 8),
      // owner (19 Nov): beep only on one side of the zone
      Text('Beep when', style: text.labelLarge),
      const SizedBox(height: 4),
      SegmentedButton<BeepWhen>(
        key: const Key('monitorBeepWhen'),
        showSelectedIcon: false,
        segments: [
          for (final w in [BeepWhen.high, BeepWhen.low, BeepWhen.both])
            ButtonSegment(value: w, label: OneLine(w.label)),
        ],
        selected: {m.beepWhen},
        onSelectionChanged: (v) => m.setBeepWhen(v.first),
      ),
      SwitchListTile(
        key: const Key('beepFaster'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Faster beeps when far out'),
        subtitle: const Text('10 bpm or more outside the zone: beeps repeat twice as often'),
        value: m.engine.fasterWhenFar,
        onChanged: m.setFasterWhenFar,
      ),
      SwitchListTile(
        key: const Key('backChime'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Chime when back in the zone'),
        subtitle: const Text('One soft sound after a beep, once you are back inside'),
        value: m.backChime,
        onChanged: m.setBackChime,
      ),
      Row(
        children: [
          const Text('Minimum gap between alerts: '),
          EditableNumber(
            value: m.settings.cooldown.inSeconds,
            title: 'Gap between alerts (seconds)',
            min: 1,
            max: 600,
            suffix: 's',
            display: '${m.settings.cooldown.inSeconds} s',
            onChanged: (v) => m.setCooldown(Duration(seconds: v.round())),
          ),
        ],
      ),
      Slider(
        min: 5,
        max: 60,
        divisions: 11,
        value: m.settings.cooldown.inSeconds.clamp(5, 60).toDouble(),
        label: '${m.settings.cooldown.inSeconds} s',
        onChanged: (v) => m.setCooldown(Duration(seconds: v.round())),
      ),
      Row(
        children: [
          const Text('Beep volume: '),
          EditableNumber(
            value: (m.volume * 100).round(),
            title: 'Beep volume (%)',
            max: 100,
            suffix: '%',
            display: '${(m.volume * 100).round()}%',
            onChanged: (v) => m.setVolume(v / 100),
          ),
        ],
      ),
      Slider(value: m.volume, onChanged: m.setVolume),
      const Divider(height: 32),
      const HrWorkoutOptions(),
    ];
  }
}

/// On/off options of the heart-rate ideas (owner, 19 Nov) that work during
/// workouts: rest by heart rate, and the recovery minute after finishing.
class HrWorkoutOptions extends StatefulWidget {
  const HrWorkoutOptions({super.key});

  @override
  State<HrWorkoutOptions> createState() => _HrWorkoutOptionsState();
}

class _HrWorkoutOptionsState extends State<HrWorkoutOptions> {
  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('During workouts and cardio', style: text.titleMedium),
        SwitchListTile(
          key: const Key('recoveryRest'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Rest until your heart rate is down'),
          subtitle: Text(
            'The rest ends when you\'re under ${s.session.recoveryBpm} bpm, '
            'or waits up to 3 more minutes for it. Needs a heart-rate strap.',
          ),
          value: s.session.recoveryRest,
          onChanged: (v) async {
            await s.setRecoveryRest(on: v);
            setState(() {});
          },
        ),
        if (s.session.recoveryRest)
          Row(
            children: [
              const Text('Ready below: '),
              EditableNumber(
                key: const Key('recoveryBpm'),
                value: s.session.recoveryBpm,
                title: 'Rest until under (bpm)',
                min: 60,
                max: 180,
                suffix: 'bpm',
                display: '${s.session.recoveryBpm} bpm',
                onChanged: (v) async {
                  await s.setRecoveryRest(bpm: v.round());
                  setState(() {});
                },
              ),
            ],
          ),
        SwitchListTile(
          key: const Key('driftAlert'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Heart-rate drift alert'),
          subtitle: const Text('On long cardio: said once when your heart rate climbs 8 % at the same speed'),
          value: s.run.driftAlert,
          onChanged: (v) async {
            await s.setDriftAlert(v);
            setState(() {});
          },
        ),
        SwitchListTile(
          key: const Key('hrRecoveryCheck'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Heart-rate recovery after a workout'),
          subtitle: const Text('One more minute of heart rate after you finish: how fast it drops (bigger = fitter)'),
          value: s.hr.recoveryCheck,
          onChanged: (v) async {
            await s.setHrRecoveryCheck(v);
            setState(() {});
          },
        ),
      ],
    );
  }
}

/// Max heart rate for the zones (owner's idea 4): from age, the highest one
/// recorded in your workouts and runs, or typed in (e.g. from a test).
class MaxHrPicker extends StatelessWidget {
  const MaxHrPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final m = HrScope.of(context);
    final text = Theme.of(context).textTheme;
    return FutureBuilder<int?>(
      future: s.workouts.highestHr(),
      builder: (context, snap) {
        final highest = snap.data;
        final fromAge = HrZones.maxHrFromAge(m.age);
        final own = m.maxHrOverride;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Max heart rate for your zones', style: text.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  key: const Key('maxHrAge'),
                  label: Text('From age · $fromAge'),
                  selected: own == null,
                  onSelected: (_) => m.setMaxHr(null),
                ),
                if (highest != null && highest > 100)
                  ChoiceChip(
                    key: const Key('maxHrHighest'),
                    label: Text('Highest recorded · $highest'),
                    selected: own == highest,
                    onSelected: (_) => m.setMaxHr(highest),
                  ),
                ChoiceChip(
                  key: const Key('maxHrOwn'),
                  label: Text(own != null && own != highest ? 'Your own · $own' : 'Type your own'),
                  selected: own != null && own != highest,
                  onSelected: (_) async {
                    final v = await promptNumber(
                      context,
                      title: 'Max heart rate (bpm)',
                      initial: own ?? fromAge,
                      min: 100,
                      max: 240,
                    );
                    if (v != null) m.setMaxHr(v.round());
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Best: your real max from a hard effort (e.g. 3 × 3 min uphill as hard as you can, after a warm-up). '
              'Zones and their colours follow it everywhere.',
              style: text.bodySmall,
            ),
          ],
        );
      },
    );
  }
}
