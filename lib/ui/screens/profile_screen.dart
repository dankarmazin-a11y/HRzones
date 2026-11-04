import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../goals_section.dart';
import '../measurements_section.dart';
import '../number_input.dart';
import '../streak_card.dart';

/// You: streak, goals, body measurements and settings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Services.of(context).session;
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
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.favorite_outline),
            title: Text('Heart-rate zones, alerts and strap'),
            subtitle: Text('On the Zones tab'),
          ),
        ],
      ),
    );
  }
}
