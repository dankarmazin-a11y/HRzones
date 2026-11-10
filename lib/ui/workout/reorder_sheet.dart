import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/database.dart';
import '../../workout/workout_session.dart';
import '../exercises/exercise_avatar.dart';

/// Hold an exercise name: every card shrinks in place to a compact row (like
/// Hevy), you drag one, and when you let go the cards open again.
void startReorder(WorkoutSession session) {
  HapticFeedback.mediumImpact();
  session.reorderMode.value = true;
}

/// The workout as compact rows while reordering (shown instead of the cards).
class InPlaceReorder extends StatelessWidget {
  const InPlaceReorder({super.key, required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final list = session.active?.exercises ?? const [];
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Expanded(child: Text('Drag to reorder', style: text.titleMedium)),
              FilledButton(onPressed: () => session.reorderMode.value = false, child: const Text('Done')),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            key: const Key('reorderList'),
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: list.length,
            onReorderItem: (from, to) {
              session.moveExercise(from, to);
              HapticFeedback.selectionClick();
              // Let go → the cards open again.
              session.reorderMode.value = false;
            },
            itemBuilder: (c, i) {
              final e = list[i];
              final done = e.sets.where((s) => s.done).length;
              // Touch anywhere on the row and drag – no extra long press.
              return ReorderableDragStartListener(
                key: ValueKey(e.id),
                index: i,
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: ListTile(
                    dense: true,
                    leading: ExerciseAvatar(exercise: e.exercise, radius: 16),
                    title: Text(e.exercise.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      e.exercise.isStretchSession ? '${e.sets.length} stretches' : '$done / ${e.sets.length} sets done',
                    ),
                    trailing: const Icon(Icons.drag_handle),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
