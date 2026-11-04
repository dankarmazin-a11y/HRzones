import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../workout/starter_programs.dart';
import '../../workout/training_level.dart';
import '../../workout/training_place.dart';
import '../screens/workouts_screen.dart';

/// Ready-made programs, filtered by level (your level first) and place.
class StarterProgramsScreen extends StatefulWidget {
  const StarterProgramsScreen({super.key});

  @override
  State<StarterProgramsScreen> createState() => _StarterProgramsScreenState();
}

class _StarterProgramsScreenState extends State<StarterProgramsScreen> {
  TrainingLevel? _level;
  TrainingPlace? _place;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final level = _level ?? s.level.value;
    // Where you train (Profile); hybrid starts on gym.
    final place = _place ?? (s.place.value == TrainingPlace.hybrid ? TrainingPlace.gym : s.place.value);
    final text = Theme.of(context).textTheme;
    final list = starterPrograms.where((p) => p.level == level && p.place == place).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Starter programs')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Ready-made plans. Add one to your templates (you can change everything later) or start a workout '
            'right away.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final p in TrainingPlaceInfo.concrete)
                ChoiceChip(
                  avatar: Icon(p.icon, size: 18),
                  label: Text(p.label),
                  selected: p == place,
                  onSelected: (_) => setState(() => _place = p),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (final l in TrainingLevel.values)
                ChoiceChip(label: Text(l.label), selected: l == level, onSelected: (_) => setState(() => _level = l)),
            ],
          ),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No programs here yet – try another level.', textAlign: TextAlign.center),
            ),
          const SizedBox(height: 8),
          for (final p in list)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                title: Text(p.name, style: text.titleMedium),
                subtitle: Text('${p.place.label} · ${p.schedule}\n${p.description}'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => StarterProgramScreen(program: p))),
              ),
            ),
        ],
      ),
    );
  }
}

/// One program: its workouts with sets × reps, start one or add them all.
class StarterProgramScreen extends StatelessWidget {
  const StarterProgramScreen({super.key, required this.program});

  final StarterProgram program;

  Future<void> _add(BuildContext context) async {
    final s = Services.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if ((await s.templates.folders()).contains(program.name) && context.mounted) {
      final again = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Already in your templates'),
          content: Text('You already have a "${program.name}" folder. Add the workouts again?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Add again')),
          ],
        ),
      );
      if (again != true) return;
    }
    await addProgramToTemplates(s.templates, program);
    messenger.showSnackBar(
      SnackBar(content: Text('Added ${program.workouts.length} templates to the folder "${program.name}"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(program.name)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton.icon(
            key: const Key('addProgram'),
            icon: const Icon(Icons.playlist_add),
            label: const Text('Add to my templates'),
            onPressed: () => _add(context),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${program.level.label} · ${program.place.label} · ${program.schedule}', style: text.labelLarge),
          const SizedBox(height: 4),
          Text(program.description),
          for (final w in program.workouts)
            Card(
              margin: const EdgeInsets.only(top: 12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(w.name, style: text.titleMedium)),
                        FilledButton.tonal(
                          onPressed: () =>
                              startTemplateWorkout(context, starterTemplate(program, w), place: program.place),
                          child: const Text('Start'),
                        ),
                      ],
                    ),
                    for (final e in w.exercises)
                      FutureBuilder<Exercise?>(
                        future: s.exercises.byId(e.id),
                        builder: (context, snap) => Padding(
                          padding: const EdgeInsets.only(top: 4, right: 8),
                          child: Row(
                            children: [
                              Expanded(child: Text(snap.data?.name ?? '')),
                              Text(e.scheme, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
