import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/exercise_repository.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final e = exercise;
    final text = Theme.of(context).textTheme;
    final secondary = e.secondaryMuscles.split(',').where((m) => m.isNotEmpty).map(titleCase).join(', ');
    final steps = e.instructions.split('\n').where((s) => s.trim().isNotEmpty).toList();
    return Scaffold(
      appBar: AppBar(title: Text(e.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (e.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                '$exerciseImageBase${e.imagePath}',
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Primary: ${titleCase(e.primaryMuscle)}')),
              if (secondary.isNotEmpty) Chip(label: Text('Secondary: $secondary')),
              if (e.equipment != null) Chip(label: Text(titleCase(e.equipment!))),
              Chip(label: Text(titleCase(e.category))),
            ],
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('How to', style: text.titleMedium),
            const SizedBox(height: 8),
            for (final (i, s) in steps.indexed)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('${i + 1}. $s')),
          ],
        ],
      ),
    );
  }
}
