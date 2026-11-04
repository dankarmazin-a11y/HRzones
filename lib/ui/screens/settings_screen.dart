import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../beep/sounds.dart';
import '../../workout/training_level.dart';
import '../../workout/training_place.dart';
import '../number_input.dart';

/// Settings (⚙ on Profile): training, rest timer alerts, sounds, theme.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final session = s.session;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Training', style: text.titleMedium),
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
          ValueListenableBuilder<TrainingLevel>(
            valueListenable: s.level,
            builder: (context, level, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text('Training level'),
                const SizedBox(height: 6),
                SegmentedButton<TrainingLevel>(
                  key: const Key('levelPicker'),
                  showSelectedIcon: false,
                  segments: [for (final l in TrainingLevel.values) ButtonSegment(value: l, label: Text(l.label))],
                  selected: {level},
                  onSelectionChanged: (v) => s.setLevel(v.first),
                ),
                const SizedBox(height: 4),
                Text(level.description, style: text.bodySmall),
              ],
            ),
          ),
          ValueListenableBuilder<TrainingPlace>(
            valueListenable: s.place,
            builder: (context, place, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text('Where you train'),
                const SizedBox(height: 6),
                SegmentedButton<TrainingPlace>(
                  key: const Key('placePicker'),
                  showSelectedIcon: false,
                  segments: [
                    for (final p in TrainingPlace.values)
                      ButtonSegment(value: p, label: Text(p.label, maxLines: 1, softWrap: false)),
                  ],
                  selected: {place},
                  onSelectionChanged: (v) => s.setPlace(v.first),
                ),
                const SizedBox(height: 4),
                Text('${place.description} Changes the exercise list and the starter programs.', style: text.bodySmall),
              ],
            ),
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: s.themeMode,
            builder: (context, mode, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text('Theme'),
                const SizedBox(height: 6),
                SegmentedButton<ThemeMode>(
                  key: const Key('themePicker'),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                    ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                  ],
                  selected: {mode},
                  onSelectionChanged: (v) => s.setThemeMode(v.first),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Text('When rest is over', style: text.titleMedium),
          const _RestAlerts(),
          const Divider(height: 32),
          Text('Sounds', style: text.titleMedium),
          Text('Pick the sound for each moment. Tap ▷ to hear it.', style: text.bodySmall),
          const SizedBox(height: 4),
          for (final e in SoundEvent.values) _SoundRow(event: e),
        ],
      ),
    );
  }
}

class _RestAlerts extends StatefulWidget {
  const _RestAlerts();

  @override
  State<_RestAlerts> createState() => _RestAlertsState();
}

class _RestAlertsState extends State<_RestAlerts> {
  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final session = s.session;
    return Column(
      children: [
        SwitchListTile(
          key: const Key('restVibrate'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.vibration),
          title: const Text('Vibrate'),
          subtitle: const Text('A light vibration when the rest timer ends (with the app open)'),
          value: session.vibrateRestOver,
          onChanged: (v) async {
            await s.setRestVibrate(v);
            setState(() {});
          },
        ),
        SwitchListTile(
          key: const Key('restNotify'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.notifications_active_outlined),
          title: const Text('Notification'),
          subtitle: const Text(
            'When the phone is locked or you are in another app: a notification with vibration. '
            'iPhone asks for permission the first time.',
          ),
          value: session.notifyRestOver,
          onChanged: (v) async {
            final messenger = ScaffoldMessenger.of(context);
            final ok = await s.setRestNotify(v);
            if (!ok) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Notifications are off for HR Zones – allow them in iPhone Settings.')),
              );
            }
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}

class _SoundRow extends StatefulWidget {
  const _SoundRow({required this.event});

  final SoundEvent event;

  @override
  State<_SoundRow> createState() => _SoundRowState();
}

class _SoundRowState extends State<_SoundRow> {
  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final e = widget.event;
    final choice = s.sounds[e] ?? SoundChoice.classic;
    return ListTile(
      key: Key('sound-${e.name}'),
      contentPadding: EdgeInsets.zero,
      title: Text(e.label),
      subtitle: Text(e.description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<SoundChoice>(
            value: choice,
            underline: const SizedBox.shrink(),
            items: [for (final c in SoundChoice.values) DropdownMenuItem(value: c, child: Text(c.label))],
            onChanged: (c) async {
              if (c == null) return;
              await s.setSound(e, c);
              s.hr.beeper.preview(e, c);
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            tooltip: 'Play',
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () => s.hr.beeper.preview(e, choice),
          ),
        ],
      ),
    );
  }
}
