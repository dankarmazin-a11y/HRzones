import 'package:flutter/material.dart';

import '../../hr/hr_monitor.dart';
import '../../app_services.dart';
import '../hr_source_section.dart';
import '../number_input.dart';
import '../zone_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = HrScope.of(context);
    final session = Services.of(context).session;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HrSourceSection(),
          const Divider(height: 32),
          Text('Heart-rate zones', style: text.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Age '),
              EditableNumber(value: m.age, title: 'Age', min: 10, max: 100, onChanged: (v) => m.setAge(v.round())),
              Text(' → max HR ${m.zones.maxHr} bpm (220 − age)'),
            ],
          ),
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
          Text('Workouts', style: text.titleMedium),
          ListenableBuilder(
            listenable: session,
            builder: (context, _) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Default rest between sets'),
              subtitle: const Text('Stretches use 10 s. Change single exercises in a workout from their ⋮ menu.'),
              trailing: Text(formatRest(session.defaultRestSeconds), style: text.titleMedium),
              onTap: () async {
                final v = await pickRestSeconds(context, session.defaultRestSeconds, title: 'Default rest');
                if (v != null) await session.setDefaultRest(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
