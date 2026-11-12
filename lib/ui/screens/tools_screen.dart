import 'package:flutter/material.dart';

import '../abs/ab_workouts_screen.dart';

import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../app_services.dart';
import '../../data/exercise_repository.dart';
import '../plate_calculator.dart';
import '../timers/timers_screen.dart';
import '../theme/app_theme.dart';
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
        // Keep cards that load data built off-screen (no jumping while scrolling).
        scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
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
          const SizedBox(height: 12),
          _ToolBox(
            key: const Key('toolAbs'),
            icon: Icons.self_improvement,
            color: Colors.deepOrange,
            title: 'Ab workouts',
            subtitle: 'Ready-made 5–20 min ab workouts to follow along: picture, timer and "next up"',
            onTap: () => open(const AbWorkoutsScreen()),
          ),
          const SizedBox(height: 12),
          _ToolBox(
            key: const Key('toolPlates'),
            icon: Icons.fitness_center,
            color: Colors.teal,
            title: 'Plate calculator',
            subtitle: 'Which plates to load for any weight – with your bar and the plates in your gym',
            onTap: () => open(const PlateCalculatorScreen()),
          ),
          const SizedBox(height: 12),
          const ToolsGuide(),
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

/// "How the tools work": a short guide below the tool boxes. Open until the
/// user closes it once (setting `toolsGuideClosed`).
class ToolsGuide extends StatefulWidget {
  const ToolsGuide({super.key});

  @override
  State<ToolsGuide> createState() => _ToolsGuideState();
}

class _ToolsGuideState extends State<ToolsGuide> {
  bool? _open;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_open != null) return;
    Services.of(context).db.getSetting('toolsGuideClosed').then((v) {
      if (mounted) setState(() => _open = v != '1');
    });
  }

  @override
  Widget build(BuildContext context) {
    final open = _open;
    if (open == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    Widget section(IconData icon, String title, List<String> lines) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(title, style: text.titleSmall),
            ],
          ),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 4),
              child: Text('• $l', style: text.bodyMedium),
            ),
        ],
      ),
    );
    return Card(
      key: const Key('toolsGuide'),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: open,
        leading: const Icon(Icons.info_outline),
        title: const Text('How the tools work'),
        shape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        onExpansionChanged: (v) {
          _open = v;
          Services.of(context).db.setSetting('toolsGuideClosed', v ? '0' : '1');
        },
        children: [
          section(Icons.monitor_heart_outlined, 'Heart-rate zones', const [
            'Pick a target range (or a zone Z1–Z5) and tap Start monitoring.',
            'Above the range: 3 high beeps. Below it: 2 low beeps. Also with the screen locked and music on.',
            'Save ranges you use often as presets (e.g. "Easy run") and choose one when a workout starts.',
            'Connect a Bluetooth chest strap or arm band for your real heart rate (the slider is for testing).',
            "Don't want zones at all? Turn them off with the switch at the top.",
          ]),
          section(Icons.timer_outlined, 'Timers', const [
            'Quick: one tap starts a countdown (30 s, 1 min…) or type your own.',
            'Interval timers: work and rest rounds, e.g. Tabata or EMOM. Tap the play button to start, ⋯ to edit.',
            'Sounds: 2 high beeps = work, 1 low beep = rest, short ticks = last 3 seconds, 3 high beeps = done.',
            '"New timer" builds your own (any number of steps and rounds).',
            'Your interval timers are also in the exercise list (type "Timers"): add one to a workout and start it there.',
          ]),
          section(Icons.fitness_center, 'Plate calculator', const [
            'Type the weight you want and pick your bar – it shows the plates for each side.',
            'Switch off plates your gym doesn\'t have; the bar is remembered for each exercise.',
          ]),
          section(Icons.lightbulb_outline, 'Good to know', const [
            'Rest between sets runs inside a workout – it ends with a ding.',
            'Tap a tab again to jump back to the top.',
          ]),
        ],
      ),
    );
  }
}

/// One tool: what Home's row and Profile's list show.
class ToolInfo {
  const ToolInfo(this.id, this.icon, this.title, this.subtitle, this.screen, {this.heart = false});

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function() screen;

  /// Heart-rate tool: red emblem.
  final bool heart;

  static final all = [
    ToolInfo(
      'zones',
      Icons.monitor_heart_outlined,
      'Zones',
      'Presets, strap, alerts',
      () => const ZonesScreen(),
      heart: true,
    ),
    ToolInfo('timers', Icons.timer_outlined, 'Timers', 'Tabata, EMOM, your own', () => const TimersScreen()),
    ToolInfo('abs', Icons.self_improvement, 'Abs', 'Follow along, 5–20 min', () => const AbWorkoutsScreen()),
    ToolInfo('plates', Icons.fitness_center, 'Plates', 'Which plates to load', () => const PlateCalculatorScreen()),
  ];

  void open(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen()));
}

/// Soft tinted box with a centred emblem (red for heart rate).
class Emblem extends StatelessWidget {
  const Emblem(this.icon, {super.key, this.heart = false, this.size = 36});

  final IconData icon;
  final bool heart;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: heart ? (dark ? const Color(0xFF3A1A1E) : const Color(0xFFFFE3E5)) : t.emblem,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(icon, size: size * 0.56, color: heart ? AppColors.heart : t.ink),
    );
  }
}

/// Home: a row of tool boxes with "All ›" (opens [ToolsScreen]).
class ToolsRow extends StatelessWidget {
  const ToolsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Tools', style: text.titleMedium)),
            TextButton(
              key: const Key('openTools'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ToolsScreen())),
              child: const Text('All ›'),
            ),
          ],
        ),
        Row(
          children: [
            for (final (i, tool) in ToolInfo.all.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: t.cardShadow,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      key: Key('homeTool_${tool.id}'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => tool.open(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Emblem(tool.icon, heart: tool.heart),
                            const SizedBox(height: 6),
                            Text(tool.title, style: text.labelLarge?.copyWith(fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Profile: the tools as a list.
class ToolsList extends StatelessWidget {
  const ToolsList({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tools', style: text.titleMedium),
        const SizedBox(height: 4),
        for (final tool in ToolInfo.all)
          Card(
            child: ListTile(
              key: Key('profileTool_${tool.id}'),
              leading: Emblem(tool.icon, heart: tool.heart),
              title: Text(
                tool.id == 'zones'
                    ? 'Heart-rate zones'
                    : (tool.id == 'abs' ? 'Ab workouts' : (tool.id == 'plates' ? 'Plate calculator' : tool.title)),
              ),
              subtitle: Text(tool.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => tool.open(context),
            ),
          ),
      ],
    );
  }
}
