import 'package:flutter/material.dart';

import '../../workout/interval_runner.dart';
import '../../workout/stats.dart';

/// Full-screen interval timer: big digits, green = work, blue = rest.
class IntervalRunScreen extends StatefulWidget {
  const IntervalRunScreen({super.key, required this.runner});

  final IntervalRunner runner;

  @override
  State<IntervalRunScreen> createState() => _IntervalRunScreenState();
}

class _IntervalRunScreenState extends State<IntervalRunScreen> {
  @override
  void initState() {
    super.initState();
    widget.runner.start();
  }

  @override
  void dispose() {
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
        final color = r.finished
            ? Colors.grey.shade800
            : r.gettingReady
            ? Colors.orange.shade800
            : (step!.work ? Colors.green.shade700 : Colors.blue.shade700);
        final label = r.finished ? 'Done 🎉' : (r.gettingReady ? 'Get ready' : step!.label);
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
                  Text(label, style: white.displaySmall, textAlign: TextAlign.center),
                  if (step != null && r.rounds > 1)
                    Text('Round ${step.round} of ${r.rounds}', style: white.titleMedium),
                  Expanded(
                    flex: 4,
                    child: FittedBox(
                      child: Text(
                        r.finished ? '0:00' : formatDuration(Duration(seconds: r.remaining)),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 200,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  if (!r.finished)
                    LinearProgressIndicator(
                      value: r.stepTotal == 0 ? 0 : r.remaining / r.stepTotal,
                      minHeight: 8,
                      color: Colors.white,
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
