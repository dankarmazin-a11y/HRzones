import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/exercise_repository.dart';
import '../workout/active_workout_screen.dart';
import 'exercise_progress.dart';

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late Exercise _exercise = widget.exercise;

  Future<void> _editNote() async {
    final t = await askNote(
      context,
      'Permanent note',
      _exercise.note ?? '',
      help: 'Shown on this exercise in every workout, with today\'s date.',
    );
    if (t == null || !mounted) return;
    final updated = await Services.of(context).exercises.setNote(_exercise.id, t);
    if (mounted) setState(() => _exercise = updated);
  }

  Future<void> _setUnilateral(bool on) async {
    final updated = await Services.of(context).exercises.setUnilateral(_exercise.id, on);
    if (mounted) setState(() => _exercise = updated);
  }

  Future<void> _setTracking(TrackingType t) async {
    final updated = await Services.of(context).exercises.setTrackingType(_exercise.id, t);
    if (mounted) setState(() => _exercise = updated);
  }

  @override
  Widget build(BuildContext context) {
    final e = _exercise;
    final text = Theme.of(context).textTheme;
    final secondary = e.secondaryMuscles.split(',').where((m) => m.isNotEmpty).map(titleCase).join(', ');
    final steps = e.instructions.split('\n').where((s) => s.trim().isNotEmpty).toList();
    return Scaffold(
      appBar: AppBar(title: Text(e.name)),
      body: ListView(
        // Keep cards that load data built off-screen (no jumping while scrolling).
        scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
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
          const SizedBox(height: 8),
          if (e.hasNote)
            StickyNote(text: e.note!, date: e.noteAt, onTap: _editNote)
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('addStickyNote'),
                icon: const Icon(Icons.push_pin_outlined),
                label: const Text('Add a permanent note'),
                onPressed: _editNote,
              ),
            ),
          const SizedBox(height: 8),
          Text('Log this exercise as', style: text.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<TrackingType>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: TrackingType.weightReps, label: Text('Weight × reps')),
              ButtonSegment(value: TrackingType.bodyweightReps, label: Text('Reps')),
              ButtonSegment(value: TrackingType.duration, label: Text('Time')),
            ],
            selected: {e.trackingType == TrackingType.distance ? TrackingType.duration : e.trackingType},
            onSelectionChanged: (s) => _setTracking(s.first),
          ),
          SwitchListTile(
            key: const Key('unilateralSwitch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Each side (left / right)'),
            subtitle: const Text('Every set is logged for the left and the right side'),
            value: e.unilateral,
            onChanged: _setUnilateral,
          ),
          ExerciseProgressSection(key: ValueKey(e.trackingType), exercise: e),
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
