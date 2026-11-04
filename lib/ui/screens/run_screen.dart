import 'package:flutter/material.dart';

import 'zones_screen.dart';

/// Running (Phase 2): GPS tracking comes next; until then, HR zones work.
class RunScreen extends StatelessWidget {
  const RunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const features = [
      (Icons.map_outlined, 'GPS route on a map'),
      (Icons.speed, 'Pace, distance and km splits'),
      (Icons.record_voice_over_outlined, 'Voice update every km'),
      (Icons.favorite_outline, 'Heart-rate zones along the route, with beeps'),
      (Icons.emoji_events_outlined, 'Records: 1 km, 5 km, 10 km, half marathon'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Run')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(Icons.directions_run, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text('Run tracking is coming next', textAlign: TextAlign.center, style: text.headlineSmall),
          const SizedBox(height: 4),
          Text('Phase 2 of the plan', textAlign: TextAlign.center, style: text.bodySmall),
          const SizedBox(height: 16),
          for (final (icon, label) in features) ListTile(leading: Icon(icon), title: Text(label)),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.monitor_heart_outlined),
            label: const Text('Run with heart-rate beeps now'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ZonesScreen())),
          ),
          const SizedBox(height: 4),
          Text(
            'Start monitoring on the HR zones screen, lock the phone and run – you get beeps when you leave your zone.',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}
