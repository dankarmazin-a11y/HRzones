import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../workout/workout_session.dart';
import '../exercises/exercise_avatar.dart';

/// Compact list of the whole workout (names only) to drag exercises into a
/// new order. Opened by holding an exercise name.
Future<void> showReorderSheet(BuildContext context, WorkoutSession session) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.85),
      child: ListenableBuilder(
        listenable: session,
        builder: (c, _) {
          final list = session.active?.exercises ?? const [];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                child: Row(
                  children: [
                    Expanded(child: Text('Drag to reorder', style: Theme.of(c).textTheme.titleMedium)),
                    FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Done')),
                  ],
                ),
              ),
              Flexible(
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: list.length,
                  onReorderItem: session.moveExercise,
                  itemBuilder: (c, i) {
                    final e = list[i];
                    final done = e.sets.where((s) => s.done).length;
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(e.id),
                      index: i,
                      child: ListTile(
                        leading: ExerciseAvatar(exercise: e.exercise, radius: 18),
                        title: Text(e.exercise.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          e.exercise.isStretchSession
                              ? '${e.sets.length} stretches'
                              : '$done / ${e.sets.length} sets done',
                        ),
                        trailing: ReorderableDragStartListener(
                          index: i,
                          child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.drag_handle)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    ),
  );
}
