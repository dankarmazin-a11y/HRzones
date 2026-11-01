import 'package:flutter/material.dart';

import '../placeholder_section.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          PlaceholderTile(icon: Icons.emoji_events_outlined, title: 'Personal records', subtitle: 'Lifts and runs'),
          PlaceholderTile(icon: Icons.accessibility_new, title: 'Muscle map', subtitle: 'Sets per muscle this week'),
          PlaceholderTile(
            icon: Icons.monitor_weight_outlined,
            title: 'Body',
            subtitle: 'Weight, body fat, circumferences',
          ),
        ],
      ),
    );
  }
}
