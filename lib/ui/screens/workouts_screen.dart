import 'package:flutter/material.dart';

import '../placeholder_section.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workouts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          PlaceholderTile(icon: Icons.list_alt, title: 'Templates', subtitle: 'Push A, Pull A, Legs…'),
          PlaceholderTile(icon: Icons.search, title: 'Exercise library', subtitle: '~800 exercises, filter by muscle'),
          PlaceholderTile(icon: Icons.history, title: 'History', subtitle: 'All strength workouts and runs'),
        ],
      ),
    );
  }
}
