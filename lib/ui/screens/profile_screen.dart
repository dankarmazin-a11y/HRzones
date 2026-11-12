import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../app_services.dart';
import '../../data/exercise_repository.dart';
import '../../workout/training_level.dart';
import '../backup_section.dart';
import '../export_action.dart';
import '../goals_section.dart';
import '../measurements_section.dart';
import '../profile/profile_widgets.dart';
import '../run/run_records.dart';
import '../run/shoes.dart';
import '../stats/stats_screen.dart';
import '../streak_card.dart';
import '../theme/app_theme.dart';
import '../theme/emblems.dart';
import 'settings_screen.dart';
import 'tools_screen.dart';

/// Set by CI (`--dart-define=APP_BUILD=<commit> <date>`) so you can see which
/// version is running; "dev" for local builds.
const appBuild = String.fromEnvironment('APP_BUILD', defaultValue: 'dev');

enum ProfileTab {
  overview('Overview'),
  records('Records'),
  body('Body & gear');

  const ProfileTab(this.label);
  final String label;
}

/// You: Overview (all time, calendar, streak, recap, goals, tools, your data) ·
/// Records (strength, running, milestones) · Body & gear (measurements, shoes).
/// Settings: the gear top right.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileTab _tab = ProfileTab.overview;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = AppTheme.of(context);
    final children = switch (_tab) {
      ProfileTab.overview => [
        const AllTimeCard(),
        const SizedBox(height: 4),
        const MonthCalendarCard(),
        const StreakCard(editable: true),
        const MonthlyRecapCard(),
        const SizedBox(height: 12),
        const GoalsSection(),
        const SizedBox(height: 16),
        const ToolsList(),
        const SizedBox(height: 16),
        Text('Your data', style: text.titleMedium),
        ListTile(
          key: const Key('profileStats'),
          contentPadding: EdgeInsets.zero,
          leading: const Emblem.icon(Icons.insights),
          title: const Text('Stats'),
          subtitle: const Text('Totals, training time per week, muscles worked'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
        ),
        ListTile(
          key: const Key('export'),
          contentPadding: EdgeInsets.zero,
          leading: const Emblem.icon(Icons.table_view_outlined),
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
      ProfileTab.records => [
        const StrengthRecordsCard(),
        const SizedBox(height: 12),
        TrainingDataBuilder(builder: (context, d) => RunRecordsCard(runs: d.runs)),
        const SizedBox(height: 12),
        const MilestonesCard(),
      ],
      ProfileTab.body => const [MeasurementsSection(), SizedBox(height: 12), ShoesCard()],
    };
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: Text('Profile', style: text.headlineMedium),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              key: const Key('openSettings'),
              tooltip: 'Settings',
              style: IconButton.styleFrom(
                backgroundColor: t.card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
                shadowColor: Colors.black26,
              ),
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ),
        ],
      ),
      body: ListView(
        // Keep cards that load data built off-screen (no jumping while scrolling).
        scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          const _ProfileHeader(),
          const SizedBox(height: 12),
          SegmentedButton<ProfileTab>(
            key: const Key('profileTabs'),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              backgroundColor: t.field,
              selectedBackgroundColor: t.card,
              selectedForegroundColor: t.ink,
              side: BorderSide.none,
            ),
            segments: [
              for (final p in ProfileTab.values)
                ButtonSegment(
                  value: p,
                  label: Text(p.label, key: Key('profileTab_${p.name}')),
                ),
            ],
            selected: {_tab},
            onSelectionChanged: (v) => setState(() => _tab = v.first),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Square with an icon, what you train, your level, since when.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<String?>(
      future: s.db.getSetting('focus'),
      builder: (context, focus) => ValueListenableBuilder<TrainingLevel>(
        valueListenable: s.level,
        builder: (context, level, _) => TrainingDataBuilder(
          builder: (context, d) {
            final what = switch (focus.data) {
              'strength' => 'Strength',
              'running' => 'Running',
              _ => 'Hybrid',
            };
            final first = d.first;
            return Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.person, color: scheme.onPrimary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$what · ${level.label}', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        first == null
                            ? 'Your first workout starts it all'
                            : 'Training since ${monthName(first)} ${first.year}',
                        style: text.bodySmall?.copyWith(color: t.muted),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
