import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/exercise_repository.dart' show SettingsAccess;
import '../platform/phone_system.dart';

/// Android only: Samsung and other phones stop apps in the background to save
/// battery, which would stop beeps, timers and the route with the screen off
/// (docs/ANDROID.md rule 15). Asked once at the first workout or run (setting
/// `batteryAsked`), and always in Settings › Keep running.
Future<void> askBatteryOnce(BuildContext context) async {
  final db = Services.of(context).db;
  if (await db.getSetting('batteryAsked') == '1') return;
  final state = await PhoneSystem.battery();
  if (state == null || state.unrestricted || !context.mounted) return;
  await db.setSetting('batteryAsked', '1');
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      key: const Key('batteryDialog'),
      title: const Text('Keep HR Zones running'),
      content: Text(
        'To save battery, your phone may stop HR Zones when the screen is off – then beeps, timers '
        'and the route stop too.\n\n${batterySteps(state.brand).join('\n\n')}\n\n'
        'You can do this later in Settings › Keep running.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Not now')),
        FilledButton(
          key: const Key('batteryOpen'),
          onPressed: () {
            Navigator.pop(c);
            PhoneSystem.openAppSettings();
          },
          child: const Text('Open App info'),
        ),
      ],
    ),
  );
}

/// Settings › Keep running (Android only): whether the phone may stop the app,
/// the steps for this phone's maker and buttons to App info / help page.
class BatteryGuide extends StatefulWidget {
  const BatteryGuide({super.key});

  @override
  State<BatteryGuide> createState() => _BatteryGuideState();
}

class _BatteryGuideState extends State<BatteryGuide> {
  late Future<BatteryState?> _state = PhoneSystem.battery();
  late final AppLifecycleListener _life = AppLifecycleListener(
    // Coming back from App info: show the new state.
    onResume: () => setState(() => _state = PhoneSystem.battery()),
  );

  @override
  void initState() {
    super.initState();
    _life;
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return FutureBuilder<BatteryState?>(
      future: _state,
      builder: (context, snap) {
        final state = snap.data;
        if (state == null) return const SizedBox.shrink();
        return Column(
          key: const Key('batteryGuide'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(state.unrestricted ? Icons.check_circle_outline : Icons.battery_alert_outlined),
              title: Text(
                state.unrestricted ? 'Battery: unrestricted' : 'Your phone may stop HR Zones in the background',
              ),
              subtitle: Text(
                state.unrestricted
                    ? 'Good – beeps, timers and the route keep going with the screen off.'
                    : 'Then beeps, timers and the route stop when the screen is off.',
              ),
            ),
            for (final step in batterySteps(state.brand))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $step', style: text.bodySmall),
              ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  key: const Key('batteryAppInfo'),
                  onPressed: PhoneSystem.openAppSettings,
                  child: const Text('Open App info'),
                ),
                TextButton(
                  key: const Key('batteryHelp'),
                  onPressed: () => PhoneSystem.openUrl(batteryHelpUrl(state.brand)),
                  child: const Text('Help for your phone'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Settings heading + [BatteryGuide], only in the Android app.
class BatterySettingsSection extends StatelessWidget {
  const BatterySettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!isAndroidApp) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Keep running', style: Theme.of(context).textTheme.titleMedium),
        const BatteryGuide(),
        const Divider(height: 32),
      ],
    );
  }
}
