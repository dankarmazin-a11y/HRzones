import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../app_services.dart';
import '../../data/database.dart';
import '../hr_presets.dart';
import '../../workout/training_place.dart';
import '../../data/template_repository.dart';
import '../exercises/exercise_library_screen.dart';
import '../history/history_screen.dart';
import '../programs/starter_programs_screen.dart';
import '../workout/workout_editor.dart';
import '../workout/active_workout_screen.dart';
import '../run/run_start.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Strength')),
      body: ListView(
        // Keep cards that load data built off-screen (no jumping while scrolling).
        scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
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
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              key: const Key('starterPrograms'),
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Starter programs'),
              subtitle: const Text('Ready-made plans for your level'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StarterProgramsScreen())),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Templates', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New'),
                onPressed: () => openTemplateEditor(context, null),
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
                  child: Text('No templates yet. Tap "New" to create one, or pick a starter program above.'),
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
                    await openTemplateEditor(context, template);
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
  if (!await confirmNoRun(context) || !context.mounted) return false;
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

/// Hybrid trainers say where they train today (filters the exercise list
/// in this workout). Returns false when cancelled. [known] skips the
/// question (e.g. a starter program made for that place).
Future<bool> _pickPlaceIfHybrid(BuildContext context, {TrainingPlace? known}) async {
  final s = Services.of(context);
  if (s.place.value != TrainingPlace.hybrid) return true;
  final place =
      known ??
      await showModalBottomSheet<TrainingPlace>(
        context: context,
        builder: (c) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Where are you training today?')),
              for (final p in TrainingPlaceInfo.concrete)
                ListTile(
                  key: Key('place-${p.name}'),
                  leading: Icon(p.icon),
                  title: Text(p.label),
                  subtitle: Text(p.description),
                  onTap: () => Navigator.pop(c, p),
                ),
            ],
          ),
        ),
      );
  if (place == null) return false;
  await s.session.setWorkoutPlace(place);
  return true;
}

/// Home › Strength: pick one of your templates or an empty workout (straight
/// to an empty workout when there are no templates yet).
Future<void> quickStartStrength(BuildContext context) async {
  final templates = await Services.of(context).templates.watchAll().first;
  if (!context.mounted) return;
  if (templates.isEmpty) return startEmptyWorkout(context);
  // Templates by folder (no folder first), names A–Z inside.
  final byFolder = <String, List<TemplateWithSlots>>{};
  for (final t in templates) {
    byFolder.putIfAbsent(t.template.folder ?? '', () => []).add(t);
  }
  final folders = byFolder.keys.toList()..sort();
  final picked = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.75),
        child: ListView(
          key: const Key('quickStartSheet'),
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Start a workout', style: Theme.of(c).textTheme.titleLarge),
            ),
            ListTile(
              key: const Key('quickEmpty'),
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Empty workout'),
              subtitle: const Text('Add exercises as you go'),
              onTap: () => Navigator.pop(c, 'empty'),
            ),
            for (final f in folders) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(f.isEmpty ? 'My templates' : f, style: Theme.of(c).textTheme.labelLarge),
              ),
              for (final t
                  in byFolder[f]!
                    ..sort((a, b) => a.template.name.toLowerCase().compareTo(b.template.name.toLowerCase())))
                ListTile(
                  key: Key('quickTemplate_${t.template.id}'),
                  leading: const Icon(Icons.fitness_center),
                  title: Text(t.template.name),
                  subtitle: Text('${t.slots.length} ${t.slots.length == 1 ? 'exercise' : 'exercises'}'),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () => Navigator.pop(c, t),
                ),
            ],
          ],
        ),
      ),
    ),
  );
  if (!context.mounted || picked == null) return;
  if (picked is TemplateWithSlots) return startTemplateWorkout(context, picked);
  return startEmptyWorkout(context);
}

Future<void> startEmptyWorkout(BuildContext context) async {
  if (!await _confirmReplace(context) || !context.mounted) return;
  await Services.of(context).askNotificationsOnce();
  if (!context.mounted) return;
  if (!await _pickPlaceIfHybrid(context) || !context.mounted) return;
  // Heart-rate zone preset for this workout (only asked if presets exist).
  final choice = await pickPreset(context, PresetUse.strength);
  if (choice == null || !context.mounted) return;
  await Services.of(context).session.startEmpty(preset: choice.preset);
  if (context.mounted) await openActiveWorkout(context);
}

Future<void> startTemplateWorkout(BuildContext context, TemplateWithSlots t, {TrainingPlace? place}) async {
  if (!await _confirmReplace(context) || !context.mounted) return;
  await Services.of(context).askNotificationsOnce();
  if (!context.mounted) return;
  if (!await _pickPlaceIfHybrid(context, known: place) || !context.mounted) return;
  await Services.of(context).session.startFromTemplate(t);
  if (context.mounted) await openActiveWorkout(context);
}

Future<void> openActiveWorkout(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen(), fullscreenDialog: true));
