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
          Text('Reminders', style: text.titleMedium),
          const _IdleReminderSwitch(),
          const Divider(height: 32),
          Text('Running', style: text.titleMedium),
          const RunVoiceSettings(),
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

class _IdleReminderSwitch extends StatefulWidget {
  const _IdleReminderSwitch();

  @override
  State<_IdleReminderSwitch> createState() => _IdleReminderSwitchState();
}

class _IdleReminderSwitchState extends State<_IdleReminderSwitch> {
  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return SwitchListTile(
      key: const Key('idleReminder'),
      contentPadding: EdgeInsets.zero,
      secondary: const Icon(Icons.alarm_outlined),
      title: const Text('Forgotten workout'),
      subtitle: Text(
        'If nothing changes in a running workout for ${s.session.idleReminderText}, '
        'a notification asks "Still working out?".',
      ),
      value: s.session.idleReminder,
      onChanged: (v) async {
        await s.setIdleReminder(v);
        if (mounted) setState(() {});
      },
    );
  }
}

/// Voice updates during runs: on/off and how often. Also in the
/// "Ready to run" sheet.
class RunVoiceSettings extends StatefulWidget {
  const RunVoiceSettings({super.key, this.compact = false});

  /// Only the switch (for the "Ready to run" sheet).
  final bool compact;

  @override
  State<RunVoiceSettings> createState() => _RunVoiceSettingsState();
}

class _RunVoiceSettingsState extends State<RunVoiceSettings> {
  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final v = s.run.voice!;
    String every(int m) => m == 500 ? '½ km' : '${m ~/ 1000} km';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const Key('runVoiceSwitch'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.record_voice_over_outlined),
          title: const Text('Voice updates'),
          subtitle: Text(v.enabled ? 'Every ${every(v.everyM)}: distance, time, pace, heart rate' : 'Off'),
          value: v.enabled,
          onChanged: (on) async {
            await s.setRunVoice(on: on);
            setState(() {});
          },
        ),
        if (!widget.compact && v.enabled)
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: SegmentedButton<int>(
              key: const Key('runVoiceEvery'),
              segments: [
                for (final m in const [500, 1000, 2000]) ButtonSegment(value: m, label: Text(every(m))),
              ],
              selected: {v.everyM},
              onSelectionChanged: (sel) async {
                await s.setRunVoice(everyM: sel.first);
                setState(() {});
              },
            ),
          ),
      ],
    );
  }
}
