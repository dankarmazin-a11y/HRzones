import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../goals_section.dart';
import '../measurements_section.dart';
import '../number_input.dart';
import '../../workout/training_level.dart';
import '../../workout/training_place.dart';
import '../export_action.dart';
import '../streak_card.dart';

/// You: streak, goals, body measurements and settings.
/// Set by CI (`--dart-define=APP_BUILD=<commit> <date>`) so you can see which
/// version is running; "dev" for local builds.
const appBuild = String.fromEnvironment('APP_BUILD', defaultValue: 'dev');

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final session = s.session;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const StreakCard(editable: true),
          const SizedBox(height: 16),
          const GoalsSection(),
          const SizedBox(height: 16),
          const MeasurementsSection(),
          const Divider(height: 32),
          Text('Settings', style: text.titleMedium),
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
          Text('Your data', style: text.titleMedium),
          ListTile(
            key: const Key('export'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.table_view_outlined),
            title: const Text('Export to spreadsheet'),
            subtitle: const Text('All workouts, sets and measurements as an Excel file (.xlsx)'),
            onTap: () => exportAndShare(context),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('HR Zones · version $appBuild', key: const Key('appVersion'), style: text.bodySmall),
          ),
        ],
      ),
    );
  }
}
