import 'dart:async';

import 'package:flutter/material.dart';

import '../../workout/interval_runner.dart';
import '../../workout/stats.dart';
import '../timer_style.dart';

/// Full-screen interval timer: big digits, green = work, blue = rest.
class IntervalRunScreen extends StatefulWidget {
  const IntervalRunScreen({super.key, required this.runner});

  final IntervalRunner runner;

  @override
  State<IntervalRunScreen> createState() => _IntervalRunScreenState();
}

class _IntervalRunScreenState extends State<IntervalRunScreen> {
  /// How long the big ✓ shows before the screen closes by itself.
  static const closeAfter = Duration(milliseconds: 1800);
  Timer? _close;

  @override
  void initState() {
    super.initState();
    widget.runner.start();
    widget.runner.addListener(_closeWhenDone);
    keepScreenOn(true);
  }

  /// Finished: show ✓, then go back (to the workout) without a tap.
  void _closeWhenDone() {
    if (!widget.runner.finished || _close != null) return;
    _close = Timer(closeAfter, () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _close?.cancel();
    widget.runner.removeListener(_closeWhenDone);
    keepScreenOn(false);
    widget.runner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.runner;
    return ListenableBuilder(
      listenable: r,
      builder: (context, _) {
        final step = r.current;
        final color = r.finished || r.gettingReady
            ? TimerStyle.neutralBackground
            : (step!.work ? TimerStyle.workBackground : TimerStyle.restBackground);
        final accent = r.finished
            ? Colors.white
            : r.gettingReady
            ? TimerStyle.readyAccent
            : (step!.work ? TimerStyle.workAccent : TimerStyle.restAccent);
        final label = r.finished ? 'Done' : (r.gettingReady ? 'Get ready' : step!.label);
        final white = Theme.of(context).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white);
        return Scaffold(
          backgroundColor: color,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(r.name, style: white.titleMedium, overflow: TextOverflow.ellipsis),
                      ),
                      IconButton(
                        key: const Key('closeIntervals'),
                        color: Colors.white,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          r.stop();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: white.displaySmall?.copyWith(color: accent, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (step != null && r.rounds > 1)
                    Text('Round ${step.round} of ${r.rounds}', style: white.titleMedium),
                  Expanded(
                    flex: 4,
                    child: FittedBox(
                      child: Text(
                        r.finished ? '✓' : formatDuration(Duration(seconds: r.remaining)),
                        style: TimerStyle.digits,
                      ),
                    ),
                  ),
                  if (!r.finished)
                    LinearProgressIndicator(
                      value: r.stepTotal == 0 ? 0 : r.remaining / r.stepTotal,
                      minHeight: 8,
                      color: accent,
                      backgroundColor: Colors.white24,
                    ),
                  const SizedBox(height: 12),
                  Text(
                    r.finished
                        ? ''
                        : [
                            if (r.next != null) 'Next: ${r.next!.label}',
                            'Total left ${formatDuration(Duration(seconds: r.totalRemaining))}',
                          ].join('  ·  '),
                    style: white.titleMedium,
                  ),
                  const Spacer(),
                  if (!r.finished)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton.filled(
                          key: const Key('pauseIntervals'),
                          iconSize: 48,
                          style: IconButton.styleFrom(backgroundColor: Colors.white24),
                          icon: Icon(r.paused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                          onPressed: r.togglePause,
                        ),
                        IconButton.filled(
                          iconSize: 48,
                          style: IconButton.styleFrom(backgroundColor: Colors.white24),
                          icon: const Icon(Icons.skip_next, color: Colors.white),
                          onPressed: r.skip,
                        ),
                      ],
                    )
                  else
                    FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
