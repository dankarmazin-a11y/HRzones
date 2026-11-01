import 'package:flutter/material.dart';

import '../../hr/hr_monitor.dart';
import '../zone_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = HrScope.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Heart-rate zones', style: text.titleMedium),
          const SizedBox(height: 8),
          Text('Age ${m.age} → max HR ${m.zones.maxHr} bpm (220 − age)'),
          Slider(
            min: 14,
            max: 80,
            divisions: 66,
            value: m.age.toDouble(),
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
          Text('Minimum gap between alerts: ${m.settings.cooldown.inSeconds} s'),
          Slider(
            min: 5,
            max: 60,
            divisions: 11,
            value: m.settings.cooldown.inSeconds.toDouble(),
            label: '${m.settings.cooldown.inSeconds} s',
            onChanged: (v) => m.setCooldown(Duration(seconds: v.round())),
          ),
          Text('Beep volume: ${(m.volume * 100).round()}%'),
          Slider(value: m.volume, onChanged: m.setVolume),
          const Divider(height: 32),
          const ListTile(
            leading: Icon(Icons.bluetooth),
            title: Text('Bluetooth heart-rate strap'),
            subtitle: Text('Coming soon'),
          ),
          const ListTile(
            leading: Icon(Icons.headphones),
            title: Text('AirPods / Apple Health'),
            subtitle: Text('Needs the paid Apple Developer account'),
          ),
        ],
      ),
    );
  }
}
