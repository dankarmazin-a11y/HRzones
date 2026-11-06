import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../goals_section.dart';
import '../measurements_section.dart';
import '../backup_section.dart';
import '../export_action.dart';
import '../streak_card.dart';
import 'settings_screen.dart';

/// You: streak, goals, body measurements and your data. Settings: ⚙ top right.
/// Set by CI (`--dart-define=APP_BUILD=<commit> <date>`) so you can see which
/// version is running; "dev" for local builds.
const appBuild = String.fromEnvironment('APP_BUILD', defaultValue: 'dev');

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            key: const Key('openSettings'),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: ListView(
        // Keep cards that load data built off-screen (no jumping while scrolling).
        scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
        padding: const EdgeInsets.all(16),
        children: [
          const StreakCard(editable: true),
          const SizedBox(height: 16),
          const GoalsSection(),
          const SizedBox(height: 16),
          const MeasurementsSection(),
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
          const BackupTiles(),
          const SizedBox(height: 16),
          Center(
            child: Text('HR Zones · version $appBuild', key: const Key('appVersion'), style: text.bodySmall),
          ),
        ],
      ),
    );
  }
}
