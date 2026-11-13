part of 'active_workout_screen.dart';

/// The permanent note of an exercise: a bold yellow sticky note that is hard
/// to miss, with the date it was written.
class StickyNote extends StatelessWidget {
  const StickyNote({super.key, required this.text, this.date, this.onTap, this.onClose});

  final String text;
  final DateTime? date;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final d = date;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 8, 6),
      child: Material(
        key: const Key('stickyNote'),
        color: const Color(0xFFFFE066), // sticky-note yellow
        elevation: 3,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFFE6A700), width: 6)),
            ),
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.push_pin, size: 18, color: Color(0xFF5D4300)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      if (d != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Note from ${d.day}.${d.month}.${d.year}',
                            style: const TextStyle(color: Color(0xFF5D4300), fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    tooltip: 'Hide for this workout',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF5D4300)),
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One round of an interval timer inside a workout: ▶ opens the full-screen
/// interval timer (any running rest stops); when it runs to the end the
/// round is ticked and the normal rest starts.
class IntervalRow extends StatelessWidget {
  const IntervalRow({super.key, required this.entry, required this.set, required this.index});

  final LoggedExercise entry;
  final LoggedSet set;
  final int index;

  Future<void> _run(BuildContext context, WorkoutSession session) async {
    final s = Services.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final preset = await s.intervals.byId(entry.exercise.intervalPresetId!);
    if (!context.mounted) return;
    if (preset == null) {
      messenger.showSnackBar(const SnackBar(content: Text('This interval timer was deleted in Tools › Timers.')));
      return;
    }
    session.stopTimer(); // the interval timer takes over; rest waits
    final runner = IntervalRunner(
      name: preset.name,
      rounds: preset.rounds,
      steps: expandSegments(decodeSegments(preset.segmentsJson), preset.rounds),
      beeper: s.hr.beeper,
    );
    final total = runner.steps.fold(0, (sum, x) => sum + x.seconds);
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => IntervalRunScreen(runner: runner), fullscreenDialog: true));
    if (runner.completedAll) session.completeInterval(entry, set, seconds: total);
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final text = Theme.of(context).textTheme;
    final secs = set.durationS;
    return Container(
      color: set.done ? Colors.green.withValues(alpha: 0.18) : null,
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: _setW,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ['Round ${index + 1}', if (secs != null) formatDuration(Duration(seconds: secs))].join(' · '),
              style: text.bodyLarge,
            ),
          ),
          if (session.templateMode)
            const SizedBox.shrink()
          else if (set.done)
            IconButton(
              tooltip: 'Undo',
              icon: const Icon(Icons.check_box, color: Colors.green),
              onPressed: () => session.toggleDone(entry, set),
            )
          else if (!session.editMode)
            IconButton(
              key: const Key('runInterval'),
              tooltip: 'Start the interval timer',
              icon: Icon(Icons.play_circle, color: timedColor(context), size: 30),
              onPressed: () => _run(context, session),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_box_outline_blank),
              onPressed: () => session.toggleDone(entry, set),
            ),
        ],
      ),
    );
  }
}

/// Small slanted sticky note next to an exercise name that has a permanent
/// note; tap it to open or fold the full note.
class NoteBadge extends StatelessWidget {
  const NoteBadge({super.key, this.open = false, this.onTap});

  final bool open;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: open ? 'Hide note' : 'Show note',
    child: GestureDetector(
      key: const Key('noteBadge'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4), // a bigger tap target
        child: Transform.rotate(
          angle: open ? 0 : -0.16,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE066),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
                bottomLeft: Radius.circular(3),
                bottomRight: Radius.circular(9), // the curled corner
              ),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(1, 2))],
              border: open ? Border.all(color: const Color(0xFFE6A700), width: 1.5) : null,
            ),
            padding: const EdgeInsets.fromLTRB(4, 6, 6, 5),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_NoteLine(width: 12), _NoteLine(width: 12), _NoteLine(width: 7)],
            ),
          ),
        ),
      ),
    ),
  );
}

class _NoteLine extends StatelessWidget {
  const _NoteLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 1.6,
    decoration: BoxDecoration(color: const Color(0xFF8A6A00), borderRadius: BorderRadius.circular(1)),
  );
}
