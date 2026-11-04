import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../timers/timers_screen.dart';
import 'zones_screen.dart';

/// One box per tool. New tools (plate calculator, pace calculator…) get a
/// box here.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    return Scaffold(
      appBar: AppBar(title: const Text('Tools')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: Services.of(context).zonesEnabled,
            builder: (context, on, _) => _ToolBox(
              key: const Key('toolZones'),
              icon: Icons.monitor_heart_outlined,
              color: Colors.red,
              title: 'Heart-rate zones',
              subtitle: on ? 'Program your zone presets, alerts, beeps and your strap' : 'Off – tap to turn them on',
              onTap: () => open(const ZonesScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ToolBox(
            key: const Key('toolTimers'),
            icon: Icons.timer_outlined,
            color: Colors.indigo,
            title: 'Timers',
            subtitle: 'Intervals (Tabata, EMOM…), your own timers and quick countdowns',
            onTap: () => open(const TimersScreen()),
          ),
        ],
      ),
    );
  }
}

class _ToolBox extends StatelessWidget {
  const _ToolBox({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleLarge),
                    const SizedBox(height: 4),
                    Text(subtitle, style: text.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
