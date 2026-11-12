import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../workout/stats.dart';
import '../../workout/workout_session.dart';
import '../timer_style.dart';
import '../number_input.dart';
import '../theme/app_theme.dart';

String _buttonLabel(TimerKind kind) => switch (kind) {
  TimerKind.rest => 'Skip',
  TimerKind.setTimer => 'Done',
  _ => 'Stop',
};

/// Bottom bar of a workout showing the running timer.
/// A slim dark bar; tap it and it opens big (−15 s / +15 s / Skip).
/// A stretch/hold opens the full-screen timer instead.
class TimerBar extends StatefulWidget {
  const TimerBar({super.key, required this.session});

  final WorkoutSession session;

  @override
  State<TimerBar> createState() => _TimerBarState();
}

class _TimerBarState extends State<TimerBar> {
  bool _expanded = false;

  // Repaints only this bar once per second (see WorkoutSession.ticks).
  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: widget.session.ticks, builder: (context, _) => _bar(context));

  Widget _bar(BuildContext context) {
    final session = widget.session;
    final t = session.timer;
    if (t == null) return const SizedBox.shrink();
    final theme = AppTheme.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? Theme.of(context).colorScheme.surfaceContainerHigh : theme.ink;
    final countsDown = t.countsDown;
    final shown = countsDown ? t.remaining : t.elapsed;
    final isSet = t.kind == TimerKind.setTimer;
    final big = _expanded;
    final next = session.nextUpLabel;
    final progress = countsDown && t.total > 0 ? shown / t.total : null;
    const white = Colors.white;
    final digits = TextStyle(
      fontFamily: 'Inter',
      color: white,
      fontWeight: FontWeight.w900,
      fontSize: big ? 76 : 17,
      height: 1,
      letterSpacing: big ? -3 : -0.3,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final label = Text(
      t.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Inter',
        color: theme.bright,
        fontWeight: FontWeight.w800,
        fontSize: big ? 13 : 11.5,
        letterSpacing: big ? 1.2 : 0,
      ),
    );
    Widget bar(double h) => ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: progress ?? 1,
        minHeight: h,
        color: theme.bright,
        backgroundColor: white.withValues(alpha: 0.18),
      ),
    );
    Widget pill(String text, VoidCallback onTap, {bool main = false, Key? key}) => Material(
      color: main ? theme.bright : white.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: big ? 0 : 11, vertical: big ? 13 : 6),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: main ? theme.onBright : white,
              fontWeight: FontWeight.w800,
              fontSize: big ? 14 : 12,
            ),
          ),
        ),
      ),
    );

    final collapsed = Row(
      children: [
        Flexible(
          flex: 0,
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 110), child: label),
        ),
        const SizedBox(width: 8),
        Text(formatDuration(Duration(seconds: shown)), style: digits),
        const SizedBox(width: 12),
        Expanded(child: bar(4)),
        const SizedBox(width: 10),
        pill(_buttonLabel(t.kind), session.stopTimer),
      ],
    );
    final expanded = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Spacer(),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Full screen',
                  color: white,
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () => openFullScreenTimer(context, session),
                ),
              ),
            ),
          ],
        ),
        label,
        const SizedBox(height: 6),
        Text(formatDuration(Duration(seconds: shown)), style: digits),
        if (next != null) ...[
          const SizedBox(height: 8),
          Text(
            'Next: $next',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'Inter', color: white.withValues(alpha: 0.7), fontSize: 13),
          ),
        ],
        const SizedBox(height: 14),
        bar(6),
        const SizedBox(height: 14),
        Row(
          children: [
            if (countsDown) ...[
              Expanded(child: pill('−15 s', () => session.adjustTimer(-15))),
              const SizedBox(width: 8),
              Expanded(child: pill('+15 s', () => session.adjustTimer(15))),
              const SizedBox(width: 8),
            ],
            Expanded(child: pill(_buttonLabel(t.kind), session.stopTimer, main: true)),
          ],
        ),
      ],
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Material(
          color: bg,
          elevation: 8,
          shadowColor: Colors.black54,
          borderRadius: BorderRadius.circular(big ? 16 : 10),
          child: InkWell(
            key: const Key('timerBar'),
            borderRadius: BorderRadius.circular(big ? 16 : 10),
            onTap: () => isSet ? openFullScreenTimer(context, session) : setState(() => _expanded = !_expanded),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: Padding(
                padding: big ? const EdgeInsets.fromLTRB(16, 0, 16, 16) : const EdgeInsets.fromLTRB(14, 8, 8, 8),
                child: big ? expanded : collapsed,
              ),
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
  /// How long the big ✓ shows before going back to the workout.
  static const closeAfter = Duration(milliseconds: 1800);
  Timer? _close;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    keepScreenOn(true);
    widget.session.addListener(_closeWhenDone);
  }

  /// The chain is over (no timer left): show ✓, then close by itself. A
  /// timer that starts again in the meantime keeps the screen open.
  void _closeWhenDone() {
    if (widget.session.timer != null) {
      _close?.cancel();
      _close = null;
      return;
    }
    _close ??= Timer(closeAfter, () {
      _close = null;
      if (mounted && widget.session.timer == null) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _close?.cancel();
    widget.session.removeListener(_closeWhenDone);
    keepScreenOn(false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final kind = widget.session.timer?.kind;
        return Scaffold(
          backgroundColor: kind == TimerKind.setTimer
              ? TimerStyle.workBackground
              : (kind == TimerKind.rest ? TimerStyle.restBackground : TimerStyle.neutralBackground),
          body: SafeArea(
            child: RotatedBox(
              // The app is portrait-only, so turn the content sideways instead.
              quarterTurns: portrait ? 1 : 0,
              child: ListenableBuilder(listenable: widget.session.ticks, builder: (context, _) => _content(context)),
            ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context) {
    final session = widget.session;
    final t = session.timer;
    final text = Theme.of(context).textTheme;
    final isSet = t?.kind == TimerKind.setTimer;
    final accent = isSet ? TimerStyle.workAccent : TimerStyle.restAccent;
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
              child: Text(t == null ? '✓' : formatDuration(Duration(seconds: shown)), style: TimerStyle.digits),
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
