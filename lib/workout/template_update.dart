import '../data/database.dart';
import '../data/template_repository.dart';
import 'active_workout.dart';
import 'workout_session.dart';

/// How a finished workout differs from the template it was started from.
enum TemplateChange {
  /// Same exercises, sets and values – nothing to ask.
  none,

  /// Same exercises and number of sets, other weights/reps/times.
  valuesOnly,

  /// Exercises added, removed, swapped or reordered, or sets added/removed.
  structure,
}

String _setKey(SetType type, double? kg, int? reps, int? secs, Side? side) =>
    '${type.index}|${kg ?? ''}|${reps ?? ''}|${secs ?? ''}|${side?.index ?? ''}';

/// A template slot as the workout shows it: an exercise now logged per side
/// turns each planned set into a left + right pair (the workout does the
/// same), so an unchanged workout doesn't look different.
TemplateSlot _asLogged(TemplateSlot a, TemplateSlot logged) {
  final split = logged.sets.any((s) => s.side != null);
  if (!split || a.sets.any((s) => s.side != null) || a.exerciseId == stretchingSessionId) return a;
  final planned = a.sets.isEmpty ? [for (var i = 0; i < a.targetSets; i++) const TemplateSet()] : a.sets;
  final pairs = [
    for (final s in planned) ...[
      TemplateSet(type: s.type, weightKg: s.weightKg, reps: s.reps, durationS: s.durationS, side: Side.left),
      TemplateSet(type: s.type, weightKg: s.weightKg, reps: s.reps, durationS: s.durationS, side: Side.right),
    ],
  ];
  return TemplateSlot(
    exerciseId: a.exerciseId,
    targetSets: pairs.length,
    restSeconds: a.restSeconds,
    supersetGroup: a.supersetGroup,
    subExerciseIds: [...a.subExerciseIds],
    sets: a.sets.isEmpty ? const [] : pairs,
  );
}

/// Compares the finished workout [w] (done sets only) with template [t].
TemplateChange compareToTemplate(TemplateWithSlots t, ActiveWorkout w) {
  final now = WorkoutSession.slotsFrom(w);
  final before = [
    for (final (i, a) in t.slots.indexed)
      i < now.length && now[i].exerciseId == a.exerciseId ? _asLogged(a, now[i]) : a,
  ];
  if (now.length != before.length) return TemplateChange.structure;
  var values = false;
  for (var i = 0; i < now.length; i++) {
    final a = before[i], b = now[i];
    if (a.exerciseId != b.exerciseId || a.subExerciseIds.join(',') != b.subExerciseIds.join(',')) {
      return TemplateChange.structure;
    }
    final aCount = a.sets.isEmpty ? a.targetSets : a.sets.length;
    if (aCount != b.targetSets) return TemplateChange.structure;
    if (a.sets.isEmpty) {
      // Old template without targets: any logged value is new.
      if (b.sets.any((s) => s.weightKg != null || s.reps != null || s.durationS != null)) values = true;
      continue;
    }
    for (var j = 0; j < a.sets.length && j < b.sets.length; j++) {
      final x = a.sets[j], y = b.sets[j];
      if (_setKey(x.type, x.weightKg, x.reps, x.durationS, x.side) !=
          _setKey(y.type, y.weightKg, y.reps, y.durationS, y.side)) {
        values = true;
      }
    }
  }
  return values ? TemplateChange.valuesOnly : TemplateChange.none;
}

/// "Values only": the template keeps its exercises and number of sets; the
/// targets become what was done (matched by exercise, in order). Sets that
/// weren't done keep their old target.
List<TemplateSlot> templateWithNewValues(TemplateWithSlots t, ActiveWorkout w) {
  final done = WorkoutSession.slotsFrom(w);
  final used = <int>{};
  return [
    for (final original in t.slots)
      () {
        final i = done.indexWhere((d) => d.exerciseId == original.exerciseId && !used.contains(done.indexOf(d)));
        if (i < 0 || original.exerciseId == stretchingSessionId) return original;
        used.add(i);
        final slot = _asLogged(original, done[i]);
        final logged = done[i].sets;
        final count = slot.sets.isEmpty ? slot.targetSets : slot.sets.length;
        return TemplateSlot(
          exerciseId: slot.exerciseId,
          targetSets: count,
          restSeconds: slot.restSeconds,
          supersetGroup: slot.supersetGroup,
          subExerciseIds: [...slot.subExerciseIds],
          sets: [
            for (var j = 0; j < count; j++)
              if (j < logged.length) logged[j] else if (j < slot.sets.length) slot.sets[j] else const TemplateSet(),
          ],
        );
      }(),
  ];
}
