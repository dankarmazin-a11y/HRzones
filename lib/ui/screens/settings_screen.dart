import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../app_services.dart';
import '../../live/live_activity.dart';
import '../../run/run_voice.dart';
import '../run/pace_alert.dart';
import '../../beep/sounds.dart';
import '../../workout/training_level.dart';
import '../../workout/training_place.dart';
import '../number_input.dart';
import '../theme/app_theme.dart';

/// Settings (⚙ on Profile): theme, training, rest timer alerts, sounds.
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
        // Keep cards that load data built off-screen (no jumping while scrolling).
        scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Look', style: text.titleMedium),
          const ThemeRow(),
          const Divider(height: 32),
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
          Text('Lock screen', style: text.titleMedium),
          const LockScreenCardCheck(),
          const Divider(height: 32),
          ListTile(
            key: const Key('rerunSetup'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.restart_alt),
            title: const Text('Run the setup again'),
            subtitle: const Text('Level, where you train, age, workouts per week, weight'),
            onTap: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              s.needsOnboarding.value = true;
            },
          ),
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
        if (!widget.compact && v.enabled) ...[
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
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 12, 0, 0),
            child: Text('What it says', style: Theme.of(context).textTheme.labelLarge),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Wrap(
              spacing: 6,
              children: [
                for (final item in VoiceItem.values)
                  FilterChip(
                    key: Key('voiceItem_${item.name}'),
                    label: Text(item.label),
                    selected: v.items.contains(item),
                    onSelected: (on) async {
                      await s.setRunVoice(items: on ? {...v.items, item} : ({...v.items}..remove(item)));
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
        ],
        if (!widget.compact) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 12, 0, 0),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    key: const Key('voiceKind'),
                    segments: const [
                      ButtonSegment(value: 'default', label: Text('Default')),
                      ButtonSegment(value: 'female', label: Text('Female')),
                      ButtonSegment(value: 'male', label: Text('Male')),
                    ],
                    selected: {v.kind},
                    onSelectionChanged: (sel) async {
                      await s.setRunVoice(kind: sel.first);
                      setState(() {});
                    },
                  ),
                ),
                IconButton(
                  key: const Key('testVoice'),
                  tooltip: 'Test voice',
                  icon: const Icon(Icons.play_circle_outline),
                  onPressed: v.test,
                ),
              ],
            ),
          ),
          SwitchListTile(
            key: const Key('spokenAlertsSwitch'),
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.campaign_outlined),
            title: const Text('Say the alerts'),
            subtitle: const Text('During runs: "Heart rate 168. Slow down." after the beeps'),
            value: v.spokenAlerts,
            onChanged: (on) async {
              await s.setRunVoice(spokenAlerts: on);
              setState(() {});
            },
          ),
          const PaceAlertRow(),
        ],
      ],
    );
  }
}

/// Settings › Lock screen: is the workout card working, and why not.
class LockScreenCardCheck extends StatefulWidget {
  const LockScreenCardCheck({super.key});

  @override
  State<LockScreenCardCheck> createState() => _LockScreenCardCheckState();
}

class _LockScreenCardCheckState extends State<LockScreenCardCheck> {
  Map<String, Object?>? _status;
  bool _loaded = false, _testing = false;
  LiveActivity? _live;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _live = Services.of(context).live;
    if (!_loaded) {
      _loaded = true;
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final m = await Services.of(context).live.status();
    if (mounted) setState(() => _status = m);
  }

  Future<void> _test() async {
    final s = Services.of(context);
    if (s.run.active || s.session.active != null) return; // the real card is up
    final live = s.live;
    if (_testing) {
      await live.end();
    } else {
      await live.start(
        'strength',
        'Test card',
        LiveCard(title: 'Lock the phone to see me', detail: 'HR Zones', clockStart: DateTime.now()),
      );
    }
    setState(() => _testing = !_testing);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _refresh();
  }

  @override
  void dispose() {
    if (_testing) _live?.end();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final busy = s.run.active || s.session.active != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_outline),
          title: const Text('Workout card on the lock screen'),
          subtitle: Text(_loaded ? liveStatusText(_status) : '…', key: const Key('liveStatus')),
          trailing: IconButton(tooltip: 'Check again', icon: const Icon(Icons.refresh), onPressed: _refresh),
        ),
        if (_status != null && !busy)
          OutlinedButton.icon(
            key: const Key('testLiveCard'),
            icon: Icon(_testing ? Icons.close : Icons.play_arrow),
            label: Text(_testing ? 'Remove test card' : 'Show a test card'),
            onPressed: _test,
          ),
      ],
    );
  }
}

/// Settings › Theme: one row (palette + light/dark); tapping opens [showThemeSheet].
class ThemeRow extends StatelessWidget {
  const ThemeRow({super.key});

  static String modeLabel(ThemeMode m) => switch (m) {
    ThemeMode.system => 'follows the phone',
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
  };

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([s.palette, s.themeMode]),
      builder: (context, _) => ListTile(
        key: const Key('themeRow'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.palette_outlined),
        title: const Text('Theme'),
        subtitle: Text('${s.palette.value.label} · ${modeLabel(s.themeMode.value)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [PaletteSwatch(s.palette.value), const Icon(Icons.chevron_right)],
        ),
        onTap: () => showThemeSheet(context),
      ),
    );
  }
}

/// Three small colour blocks for a palette.
class PaletteSwatch extends StatelessWidget {
  const PaletteSwatch(this.palette, {super.key, this.height = 16, this.width = 30});

  final AppPalette palette;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(5),
    child: SizedBox(
      width: width,
      height: height,
      child: Row(
        children: [
          for (final c in [palette.ink, palette.bright, palette.second]) Expanded(child: ColoredBox(color: c)),
        ],
      ),
    ),
  );
}

/// The theme menu: Mint / Orange / Pink and Phone / Light / Dark.
Future<void> showThemeSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    final t = AppTheme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([s.palette, s.themeMode]),
      builder: (context, _) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme', style: text.titleLarge),
              const SizedBox(height: 12),
              for (final p in AppPalette.values) ...[
                Material(
                  color: t.field,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                    side: p == s.palette.value ? BorderSide(color: t.ink, width: 2) : BorderSide.none,
                  ),
                  child: InkWell(
                    key: Key('palette_${p.name}'),
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => s.setPalette(p),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          PaletteSwatch(p, width: 36, height: 18),
                          const SizedBox(width: 12),
                          Expanded(child: Text(p.label, style: text.titleSmall)),
                          if (p == s.palette.value) Icon(Icons.check, color: t.ink),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  key: const Key('themePicker'),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Phone')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {s.themeMode.value},
                  onSelectionChanged: (v) => s.setThemeMode(v.first),
                ),
              ),
              const SizedBox(height: 6),
              Text('Phone = follows the iPhone: light in the day, dark at night.', style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  },
);
