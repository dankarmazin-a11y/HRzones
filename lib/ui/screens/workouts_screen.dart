import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/template_repository.dart';
import '../exercises/exercise_library_screen.dart';
import '../history/history_screen.dart';
import '../templates/template_editor_screen.dart';
import '../workout/active_workout_screen.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Workouts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Start empty workout'),
            onPressed: () => startEmptyWorkout(context),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Exercises'),
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen())),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Templates', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New'),
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TemplateEditorScreen())),
              ),
            ],
          ),
          StreamBuilder<List<TemplateWithSlots>>(
            stream: s.templates.watchAll(),
            builder: (context, snap) {
              final list = snap.data ?? const [];
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No templates yet. Tap "New" to create one, e.g. "Push A".'),
                );
              }
              // Templates without a folder first, then one section per folder.
              final loose = list.where((t) => (t.template.folder ?? '').isEmpty).toList();
              final folders = <String, List<TemplateWithSlots>>{};
              for (final t in list.where((t) => (t.template.folder ?? '').isNotEmpty)) {
                folders.putIfAbsent(t.template.folder!, () => []).add(t);
              }
              final names = folders.keys.toList()..sort();
              return Column(
                children: [
                  for (final t in loose) TemplateCard(template: t),
                  for (final f in names)
                    ExpansionTile(
                      key: PageStorageKey('folder-$f'),
                      initiallyExpanded: true,
                      tilePadding: EdgeInsets.zero,
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(f),
                      subtitle: Text('${folders[f]!.length} templates'),
                      children: [for (final t in folders[f]!) TemplateCard(template: t)],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class TemplateCard extends StatelessWidget {
  const TemplateCard({super.key, required this.template});

  final TemplateWithSlots template;

  @override
  Widget build(BuildContext context) {
    final repo = Services.of(context).exercises;
    return Card(
      child: ListTile(
        title: Text(template.template.name),
        subtitle: FutureBuilder(
          future: Future.wait(template.slots.map((s) => repo.byId(s.exerciseId))),
          builder: (context, snap) => Text(
            (snap.data ?? const []).nonNulls.map((e) => e.name).join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              onSelected: (v) async {
                final repo = Services.of(context).templates;
                switch (v) {
                  case 'edit':
                    await Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => TemplateEditorScreen(existing: template)));
                  case 'duplicate':
                    await repo.duplicate(template);
                  case 'delete':
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text('Delete "${template.template.name}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (ok == true) await repo.delete(template.template.id);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
            FilledButton.tonal(onPressed: () => startTemplateWorkout(context, template), child: const Text('Start')),
          ],
        ),
      ),
    );
  }
}

/// Asks before replacing a workout that is already in progress.
Future<bool> _confirmReplace(BuildContext context) async {
  final session = Services.of(context).session;
  if (session.active == null) return true;
  final choice = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Workout in progress'),
      content: const Text('You already have a workout running.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, 'resume'), child: const Text('Resume it')),
        TextButton(onPressed: () => Navigator.pop(c, 'discard'), child: const Text('Discard & start new')),
      ],
    ),
  );
  if (choice == 'discard') {
    await session.discard();
    return true;
  }
  if (choice == 'resume' && context.mounted) await openActiveWorkout(context);
  return false;
}

Future<void> startEmptyWorkout(BuildContext context) async {
  if (!await _confirmReplace(context) || !context.mounted) return;
  await Services.of(context).session.startEmpty();
  if (context.mounted) await openActiveWorkout(context);
}

Future<void> startTemplateWorkout(BuildContext context, TemplateWithSlots t) async {
  if (!await _confirmReplace(context) || !context.mounted) return;
  await Services.of(context).session.startFromTemplate(t);
  if (context.mounted) await openActiveWorkout(context);
}

Future<void> openActiveWorkout(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen(), fullscreenDialog: true));
