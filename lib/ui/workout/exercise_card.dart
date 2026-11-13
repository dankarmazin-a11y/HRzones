part of 'active_workout_screen.dart';

/// Compact button showing how an exercise is logged; each tap switches
/// weight × reps → reps → time.
class TrackingToggle extends StatelessWidget {
  const TrackingToggle({super.key, required this.type, required this.onChanged});

  final TrackingType type;
  final ValueChanged<TrackingType> onChanged;

  static const _order = [
    TrackingType.weightReps,
    TrackingType.bodyweightReps,
    TrackingType.duration,
    TrackingType.distance,
  ];

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (type) {
      TrackingType.weightReps => (Icons.fitness_center, '${Units.w}×reps'), // unit from Settings › Units only
      TrackingType.bodyweightReps => (Icons.repeat, 'reps'),
      TrackingType.duration => (Icons.timer_outlined, 'time'),
      TrackingType.distance => (Icons.straighten, 'metres'),
    };
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Tap to change how this exercise is logged',
      child: InkWell(
        key: const Key('trackingToggle'),
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final i = _order.indexOf(type);
          onChanged(_order[(i + 1) % _order.length]);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 4),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({super.key, required this.index, required this.entry});

  final int index;
  final LoggedExercise entry;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final e = entry;
    final isSession = e.exercise.isStretchSession;
    final tracking = e.exercise.trackingType;
    final text = Theme.of(context).textTheme;
    final group = e.supersetGroup;
    final list = session.active!.exercises;
    final linkedToNext = group != null && index + 1 < list.length && list[index + 1].supersetGroup == group;

    Future<void> addStretches() async {
      final picked = await ExerciseLibraryScreen.pick(context, group: ExerciseGroup.stretching);
      if (picked != null) session.addStretches(e, picked.where((x) => x.isStretch && !x.isStretchSession).toList());
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      shape: group == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _supersetColors[group % _supersetColors.length], width: 2),
            ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExerciseAvatar(exercise: e.exercise, radius: 16),
                const SizedBox(width: 8),
                Expanded(
                  // Tap: details. Hold: compact list to reorder the workout.
                  child: InkWell(
                    onTap: isSession
                        ? null
                        : () =>
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: e.exercise))),
                    onLongPress: () => startReorder(session),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            // Interval timers: "Timer · Stretching", not a second "Stretching" card.
                            if (e.exercise.isInterval) const TextSpan(text: 'Timer · '),
                            TextSpan(text: e.exercise.name),
                            // A saved permanent note: a small slanted sticky note; tap it to
                            // open or fold the full note.
                            if (e.exercise.hasNote)
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: NoteBadge(open: !e.noteHidden, onTap: () => session.toggleNote(e)),
                                ),
                              ),
                          ],
                        ),
                        style: text.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                ),
                if (!isSession && !e.exercise.isInterval)
                  TrackingToggle(type: tracking, onChanged: (t) => session.setTrackingType(e, t)),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    switch (v) {
                      case 'rest':
                        final r = await pickRestSeconds(context, e.restSeconds);
                        if (r != null) session.setRestSeconds(e, r);
                      case 'superset':
                        session.toggleSupersetWithNext(e);
                      case 'swap':
                        final picked = await ExerciseLibraryScreen.pick(context);
                        final next = picked?.where((x) => !x.isStretchSession).firstOrNull;
                        if (next != null) await session.swapExercise(e, next);
                      case 'calc':
                        final last = e.sets.lastWhere((x) => x.weightKg != null, orElse: () => e.sets.first);
                        if (context.mounted) {
                          await showCalculators(
                            context,
                            weightKg: last.weightKg,
                            reps: last.reps,
                            exerciseId: e.exercise.id,
                          );
                        }
                      case 'reorder':
                        startReorder(session);
                      case 'sides':
                        await session.setUnilateral(e, !e.exercise.unilateral);
                      case 'workoutNote':
                        final t = await askNote(context, 'Note for this workout', e.notes);
                        if (t != null) session.setWorkoutNote(e, t);
                      case 'stickyNote':
                        final t = await askNote(
                          context,
                          'Permanent note',
                          e.exercise.note ?? '',
                          help: 'Shown on this exercise in every workout, with today\'s date.',
                        );
                        if (t != null) await session.setExerciseNote(e, t);
                      case 'remove':
                        session.removeExercise(e);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'rest', child: Text('Rest timer (${formatRest(e.restSeconds)})')),
                    if (index + 1 < list.length && !isSession)
                      PopupMenuItem(
                        value: 'superset',
                        child: Text(linkedToNext ? 'Remove superset with next' : 'Superset with next'),
                      ),
                    if (!isSession) const PopupMenuItem(value: 'swap', child: Text('Swap exercise')),
                    if (!isSession && !e.exercise.isInterval)
                      CheckedPopupMenuItem(
                        value: 'sides',
                        checked: e.exercise.unilateral,
                        child: const Text('Each side (left / right)'),
                      ),
                    PopupMenuItem(
                      value: 'workoutNote',
                      child: Text(e.notes.isEmpty ? 'Add a note (this workout)' : 'Edit note (this workout)'),
                    ),
                    if (!isSession)
                      PopupMenuItem(
                        value: 'stickyNote',
                        child: Text(e.exercise.hasNote ? 'Edit permanent note' : 'Add a permanent note'),
                      ),
                    if (tracking == TrackingType.weightReps && e.sets.isNotEmpty)
                      const PopupMenuItem(value: 'calc', child: Text('Plate & 1RM calculator')),
                    if (list.length > 1) const PopupMenuItem(value: 'reorder', child: Text('Reorder exercises')),
                    const PopupMenuItem(value: 'remove', child: Text('Remove exercise')),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        if (group != null) 'Superset',
                        'Rest ${formatRest(e.restSeconds)}',
                        if (isSession) 'tap ▶ and the stretches run one after another',
                      ].join(' · '),
                      style: text.labelSmall,
                    ),
                  ),
                  // Rounds: the stretch list (or a timed hold) runs N times.
                  if ((isSession || (e.exercise.isTimed && !e.exercise.isInterval)) && e.sets.isNotEmpty)
                    ActionChip(
                      key: Key('rounds_${e.id}'),
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.repeat, size: 16),
                      label: Text(
                        '${isSession ? WorkoutSession.stretchRounds(e) : WorkoutSession.setCount(e)}× '
                        '${isSession ? 'rounds' : 'sets'}',
                      ),
                      onPressed: () async {
                        final current = isSession ? WorkoutSession.stretchRounds(e) : WorkoutSession.setCount(e);
                        final v = await promptNumber(
                          context,
                          title: isSession ? 'How many rounds of the stretches?' : 'How many times?',
                          initial: current,
                          min: 1,
                          max: 20,
                        );
                        if (v == null) return;
                        isSession ? session.setStretchRounds(e, v.round()) : session.setSetCount(e, v.round());
                      },
                    ),
                ],
              ),
            ),
            if (e.exercise.hasNote && !e.noteHidden)
              StickyNote(
                text: e.exercise.note!,
                date: e.exercise.noteAt,
                onTap: () async {
                  final t = await askNote(context, 'Permanent note', e.exercise.note ?? '');
                  if (t != null) await session.setExerciseNote(e, t);
                },
                onClose: () => session.hideNote(e),
              ),
            if (e.notes.isNotEmpty)
              InkWell(
                onTap: () async {
                  final t = await askNote(context, 'Note for this workout', e.notes);
                  if (t != null) session.setWorkoutNote(e, t);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(2, 4, 8, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(e.notes, style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                      ),
                    ],
                  ),
                ),
              ),
            if (e.exercise.isInterval)
              const SizedBox.shrink()
            else if (isSession)
              const _StretchHeaderRow()
            else
              _HeaderRow(
                tracking: tracking,
                showRpe: !e.exercise.isStretch && Services.of(context).level.value.showsAdvancedSetOptions,
                pairs: e.sets.any((x) => x.side != null),
              ),
            for (final (i, s) in e.sets.indexed)
              if (!_isRightOfPair(e.sets, i))
                Dismissible(
                  key: ValueKey(s.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete),
                  ),
                  onDismissed: (_) => session.removeSet(e, s),
                  child: e.exercise.isInterval
                      ? IntervalRow(entry: e, set: s, index: i)
                      : SetRow(entry: e, set: s, index: i, partner: _partnerOf(e.sets, i)),
                ),
            TextButton.icon(
              onPressed: isSession ? addStretches : () => session.addSet(e),
              icon: const Icon(Icons.add),
              label: Text(isSession ? 'Add stretch' : (e.exercise.isInterval ? 'Add round' : 'Add set')),
            ),
          ],
        ),
      ),
    );
  }
}

const _setW = 32.0, _prevW = 80.0, _rpeW = 40.0, _doneW = 44.0, _kgW = 56.0, _secW = 64.0;

/// A one-sided set is stored as a left + right pair; it shows as one row
/// (shared values, a tick per side). Stretch rows keep one row per side.
LoggedSet? _partnerOf(List<LoggedSet> sets, int i) =>
    sets[i].side == Side.left && sets[i].subExercise == null && i + 1 < sets.length && sets[i + 1].side == Side.right
    ? sets[i + 1]
    : null;

bool _isRightOfPair(List<LoggedSet> sets, int i) => i > 0 && _partnerOf(sets, i - 1) != null;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.tracking, required this.showRpe, this.pairs = false});

  final TrackingType tracking;
  final bool showRpe;

  /// One-sided exercise: the tick column holds L and R.
  final bool pairs;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).textTheme.labelSmall;
    Widget cell(String t) => Text(t, style: s, textAlign: TextAlign.center);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: _setW, child: cell('SET')),
          SizedBox(width: _prevW, child: cell('PREVIOUS')),
          if (tracking == TrackingType.duration) ...[
            Expanded(child: cell('+${Units.w.toUpperCase()}')),
            Expanded(child: cell('SECONDS')),
          ] else if (tracking == TrackingType.distance) ...[
            Expanded(child: cell('METRES')),
            Expanded(child: cell('SECONDS')),
          ] else ...[
            Expanded(child: cell('${tracking == TrackingType.bodyweightReps ? '+' : ''}${Units.w.toUpperCase()}')),
            Expanded(child: cell('REPS')),
          ],
          if (showRpe) SizedBox(width: _rpeW, child: cell('RPE')),
          SizedBox(
            width: _doneW,
            child: SessionScope.of(context).templateMode ? null : const Icon(Icons.check, size: 16),
          ),
        ],
      ),
    );
  }
}

class _StretchHeaderRow extends StatelessWidget {
  const _StretchHeaderRow();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).textTheme.labelSmall;
    Widget cell(String t) => Text(t, style: s, textAlign: TextAlign.center);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: _setW, child: cell('#')),
          Expanded(child: Text('STRETCH', style: s)),
          SizedBox(width: _kgW, child: cell('+${Units.w.toUpperCase()}')),
          SizedBox(width: _secW, child: cell('SEC')),
          const SizedBox(width: _doneW, child: Icon(Icons.play_arrow, size: 16)),
        ],
      ),
    );
  }
}
