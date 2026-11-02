import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../workout/stats.dart';
import '../../workout/workout_session.dart';
import '../number_input.dart';

String _buttonLabel(TimerKind kind) => switch (kind) {
  TimerKind.rest => 'Skip',
  TimerKind.setTimer => 'Done',
  _ => 'Stop',
};

/// Bottom bar of a workout showing the running timer.
/// Tap: a stretch/hold opens full screen; other timers grow a little.
class TimerBar extends StatefulWidget {
  const TimerBar({super.key, required this.session});

  final WorkoutSession session;

  @override
  State<TimerBar> createState() => _TimerBarState();
}

class _TimerBarState extends State<TimerBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final t = session.timer!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final countsDown = t.countsDown;
    final shown = countsDown ? t.remaining : t.elapsed;
    final isSet = t.kind == TimerKind.setTimer;
    final big = _expanded;
    final next = session.nextUpLabel;

    Widget icon(double size) =>
        Icon(isSet ? Icons.self_improvement : (countsDown ? Icons.timer_outlined : Icons.av_timer), size: size);
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.label, overflow: TextOverflow.ellipsis, style: big ? text.titleMedium : text.labelMedium),
        Text(
          formatDuration(Duration(seconds: shown)),
          style: (big ? text.displayMedium : text.titleLarge)?.copyWith(
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (next != null) Text('Next: $next', overflow: TextOverflow.ellipsis, style: text.bodySmall),
      ],
    );
    final buttons = <Widget>[
      if (countsDown) ...[
        TextButton(onPressed: () => session.adjustTimer(-15), child: const Text('−15')),
        TextButton(onPressed: () => session.adjustTimer(15), child: const Text('+15')),
      ],
      IconButton(
        tooltip: 'Full screen',
        icon: const Icon(Icons.fullscreen),
        onPressed: () => openFullScreenTimer(context, session),
      ),
      FilledButton(onPressed: session.stopTimer, child: Text(_buttonLabel(t.kind))),
    ];

    return Material(
      color: isSet ? Colors.teal.shade800 : scheme.primaryContainer,
      child: SafeArea(
        top: false,
        child: InkWell(
          key: const Key('timerBar'),
          onTap: () => isSet ? openFullScreenTimer(context, session) : setState(() => _expanded = !_expanded),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 150),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (countsDown)
                  LinearProgressIndicator(value: t.total == 0 ? 0 : shown / t.total, minHeight: big ? 6 : 4),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: big ? 12 : 8),
                  child: big
                      ? Column(
                          children: [
                            Row(
                              children: [
                                icon(40),
                                const SizedBox(width: 12),
                                Expanded(child: info),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(mainAxisAlignment: MainAxisAlignment.end, children: buttons),
                          ],
                        )
                      : Row(
                          children: [
                            icon(24),
                            const SizedBox(width: 8),
                            Expanded(child: info),
                            ...buttons,
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> openFullScreenTimer(BuildContext context, WorkoutSession session) =>
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => FullScreenTimer(session: session), fullscreenDialog: true));

/// Huge sideways timer for stretching / holds: readable from the floor.
/// Follows the whole chain (stretch → rest → next stretch) until closed.
class FullScreenTimer extends StatefulWidget {
  const FullScreenTimer({super.key, required this.session});

  final WorkoutSession session;

  @override
  State<FullScreenTimer> createState() => _FullScreenTimerState();
}

class _FullScreenTimerState extends State<FullScreenTimer> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: RotatedBox(
          // The app is portrait-only, so turn the content sideways instead.
          quarterTurns: portrait ? 1 : 0,
          child: ListenableBuilder(listenable: widget.session, builder: (context, _) => _content(context)),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final session = widget.session;
    final t = session.timer;
    final text = Theme.of(context).textTheme;
    final isSet = t?.kind == TimerKind.setTimer;
    final accent = isSet ? Colors.tealAccent : Theme.of(context).colorScheme.primary;
    final shown = t == null ? 0 : (t.countsDown ? t.remaining : t.elapsed);
    final next = session.nextUpLabel;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t?.label ?? 'Done',
                  overflow: TextOverflow.ellipsis,
                  style: text.headlineMedium?.copyWith(color: Colors.white),
                ),
              ),
              IconButton(
                key: const Key('closeFullScreen'),
                iconSize: 32,
                color: Colors.white,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Expanded(
            child: FittedBox(
              child: Text(
                t == null ? '✓' : formatDuration(Duration(seconds: shown)),
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 200,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          if (t != null && t.countsDown)
            LinearProgressIndicator(
              value: t.total == 0 ? 0 : shown / t.total,
              minHeight: 8,
              color: accent,
              backgroundColor: Colors.white12,
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  next != null ? 'Next: $next' : '',
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(color: Colors.white70),
                ),
              ),
              if (t != null && t.countsDown) ...[
                OutlinedButton(onPressed: () => session.adjustTimer(-15), child: const Text('−15')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () => session.adjustTimer(15), child: const Text('+15')),
                const SizedBox(width: 8),
              ],
              if (t != null) FilledButton(onPressed: session.stopTimer, child: Text(_buttonLabel(t.kind))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Timer button sheet: default rest for all exercises + a standalone timer.
Future<void> showTimerSheet(BuildContext context, WorkoutSession session) {
  const restOptions = [30, 60, 90, 120, 180];
  const timerOptions = [30, 60, 120, 180, 300];
  return showModalBottomSheet<void>(
    context: context,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: session,
          builder: (c, _) {
            final text = Theme.of(c).textTheme;
            final current = session.defaultRestSeconds;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rest between sets', style: text.titleMedium),
                Text(
                  'Applies to every exercise in this workout and becomes your default. '
                  'Change a single exercise from its ⋮ menu.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in restOptions)
                      ChoiceChip(
                        label: Text(formatRest(o)),
                        selected: current == o,
                        onSelected: (_) => session.setDefaultRest(o),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.edit, size: 16),
                      label: Text(restOptions.contains(current) ? 'Custom' : formatRest(current)),
                      onPressed: () async {
                        final v = await promptNumber(
                          c,
                          title: 'Rest (seconds)',
                          initial: current,
                          max: 3600,
                          suffix: 's',
                        );
                        if (v != null) await session.setDefaultRest(v.round());
                      },
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text('Start a timer', style: text.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in timerOptions)
                      ActionChip(
                        label: Text(o < 60 ? '$o s' : '${o ~/ 60} min'),
                        onPressed: () {
                          session.startCountdown(o);
                          Navigator.pop(c);
                        },
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.edit, size: 16),
                      label: const Text('Custom'),
                      onPressed: () async {
                        final v = await promptNumber(
                          c,
                          title: 'Timer (seconds)',
                          initial: 60,
                          min: 1,
                          max: 7200,
                          suffix: 's',
                        );
                        if (v != null && c.mounted) {
                          session.startCountdown(v.round());
                          Navigator.pop(c);
                        }
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.av_timer, size: 16),
                      label: const Text('Stopwatch'),
                      onPressed: () {
                        session.startStopwatch();
                        Navigator.pop(c);
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
