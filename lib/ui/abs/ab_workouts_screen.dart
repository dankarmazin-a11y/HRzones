import 'dart:async';

import '../images/cached_image.dart';

import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/exercise_repository.dart';
import '../../workout/ab_workouts.dart';
import '../../workout/interval_runner.dart';
import '../../workout/stats.dart';
import '../exercises/exercise_avatar.dart';
import '../timer_style.dart';

/// Ready-made ab workouts to follow along (Tools › Ab workouts).
class AbWorkoutsScreen extends StatelessWidget {
  const AbWorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ab workouts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Follow along: every move runs on a timer with a picture, a short rest, and "next up". '
            'No equipment needed. Finished workouts go to your history.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final w in abWorkouts)
            Card(
              child: ListTile(
                key: Key('ab_${w.id}'),
                leading: CircleAvatar(child: Text('${w.minutes}')),
                title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${w.minutes} min · ${w.level}\n${w.description}'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AbWorkoutPreview(workout: w))),
              ),
            ),
        ],
      ),
    );
  }
}

/// The moves of one workout, and Start.
class AbWorkoutPreview extends StatelessWidget {
  const AbWorkoutPreview({super.key, required this.workout});

  final AbWorkout workout;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final w = workout;
    return Scaffold(
      appBar: AppBar(title: Text(w.name)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 60,
            child: FilledButton.icon(
              key: const Key('startAbWorkout'),
              icon: const Icon(Icons.play_arrow, size: 30),
              label: const Text('Start', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => FollowAlongScreen(workout: w), fullscreenDialog: true)),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${w.minutes} min · ${w.level} · ${w.rounds > 1 ? '${w.rounds} rounds · ' : ''}'
            '${w.workSeconds} s on, ${w.restSeconds} s rest',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final m in w.moves)
            FutureBuilder<Exercise?>(
              future: s.exercises.byId(m.exerciseId),
              builder: (context, snap) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: snap.data == null
                    ? const CircleAvatar(child: Icon(Icons.fitness_center))
                    : ExerciseAvatar(exercise: snap.data!, radius: 22),
                title: Text(m.name),
                trailing: Text('${m.seconds ?? w.workSeconds} s'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-screen follow-along player: picture of the move (start ↔ end
/// position), big countdown, "Next up" during the rest, spoken cues.
class FollowAlongScreen extends StatefulWidget {
  const FollowAlongScreen({super.key, required this.workout});

  final AbWorkout workout;

  /// How long the ✓ shows at the end before going back.
  static const closeAfter = Duration(milliseconds: 2500);

  @override
  State<FollowAlongScreen> createState() => _FollowAlongScreenState();
}

class _FollowAlongScreenState extends State<FollowAlongScreen> {
  late final plan = widget.workout.plan();
  late final IntervalRunner runner;
  final _exercises = <String, Exercise>{};
  late final DateTime _startedAt;
  int _spokenFor = -2;
  bool _voice = true;
  bool _saved = false;
  Timer? _close;
  late AppServices _s;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    keepScreenOn(true);
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _s = Services.of(context);
    runner = IntervalRunner(
      name: widget.workout.name,
      steps: plan.steps,
      rounds: widget.workout.rounds,
      beeper: _s.hr.beeper,
      readySeconds: 5,
    )..addListener(_onStep);
    for (final id in {for (final m in widget.workout.moves) m.exerciseId}) {
      _s.exercises.byId(id).then((e) {
        if (e != null && mounted) setState(() => _exercises[id] = e);
      });
    }
    runner.start();
  }

  AbMove? _nextMove() {
    for (var i = runner.index + 1; i < plan.moves.length; i++) {
      if (plan.moves[i] != null) return plan.moves[i];
    }
    return null;
  }

  /// Spoken cues (once per step) and the end.
  void _onStep() {
    if (runner.finished) {
      if (runner.completedAll && !_saved) {
        _saved = true;
        _say('Workout complete. Great job!');
        saveAbWorkout(widget.workout, _s.exercises, _s.workouts, startedAt: _startedAt, endedAt: DateTime.now());
        _close = Timer(FollowAlongScreen.closeAfter, () {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
      return;
    }
    if (runner.index == _spokenFor) return;
    _spokenFor = runner.index;
    final step = runner.current;
    final next = _nextMove();
    if (runner.gettingReady) {
      _say('Get ready. First: ${next?.name ?? ''}.');
    } else if (step != null && !step.work && next != null) {
      _say('Rest. Next: ${next.name}.');
    } else if (step != null && step.work) {
      _say(step.label);
    }
  }

  void _say(String text) {
    if (_voice) _s.hr.beeper.speak(text, voice: _s.run.voice?.kind ?? 'default');
  }

  @override
  void dispose() {
    _close?.cancel();
    keepScreenOn(false);
    runner.removeListener(_onStep);
    runner.dispose();
    super.dispose();
  }

  Widget _picture(AbMove? move, {required bool dim}) {
    final e = move == null ? null : _exercises[move.exerciseId];
    // Flip between start and end position every second.
    final path = moveImage(e, second: runner.remaining.isOdd);
    final child = path == null || !ExerciseAvatar.loadImages
        ? const Icon(Icons.self_improvement, size: 96, color: Colors.white54)
        : Image(
            image: cachedNetworkImage('$exerciseImageBase$path'),
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const Icon(Icons.fitness_center, size: 96, color: Colors.white54),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.white,
        child: Opacity(
          opacity: dim ? 0.55 : 1,
          child: Center(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: runner,
      builder: (context, _) {
        final r = runner;
        final step = r.current;
        final work = step?.work ?? false;
        final next = _nextMove();
        final bg = r.finished
            ? TimerStyle.neutralBackground
            : (work ? TimerStyle.workBackground : TimerStyle.restBackground);
        final white = Theme.of(context).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white);
        final moveNo = step == null ? 0 : plan.moves.take(r.index + 1).whereType<AbMove>().length;
        final moveCount = plan.moves.whereType<AbMove>().length;
        final label = r.finished
            ? 'Done'
            : r.gettingReady
            ? 'Get ready'
            : step!.label;
        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(widget.workout.name, style: white.titleMedium)),
                      IconButton(
                        tooltip: _voice ? 'Voice off' : 'Voice on',
                        color: Colors.white,
                        icon: Icon(_voice ? Icons.record_voice_over : Icons.voice_over_off),
                        onPressed: () => setState(() => _voice = !_voice),
                      ),
                      IconButton(
                        key: const Key('closeAbWorkout'),
                        color: Colors.white,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          r.stop();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  Text(
                    label,
                    key: const Key('abStepLabel'),
                    textAlign: TextAlign.center,
                    style: white.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (!r.finished && !work && next != null)
                    Text('Next up: ${next.name}', style: white.titleMedium?.copyWith(color: TimerStyle.restAccent)),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 5,
                    child: r.finished
                        ? const Center(child: Icon(Icons.check_circle, size: 140, color: Colors.white))
                        : _picture(work ? plan.moves[r.index] : next, dim: !work),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 2,
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
                      color: work ? TimerStyle.workAccent : TimerStyle.restAccent,
                      backgroundColor: Colors.white24,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    r.finished
                        ? 'Saved to your history'
                        : [
                            if (moveNo > 0) 'Move $moveNo of $moveCount',
                            if (r.rounds > 1 && step != null) 'Round ${step.round} of ${r.rounds}',
                            '${formatDuration(Duration(seconds: r.totalRemaining))} left',
                          ].join('  ·  '),
                    style: white.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  if (!r.finished)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton.filled(
                          key: const Key('pauseAbWorkout'),
                          iconSize: 44,
                          style: IconButton.styleFrom(backgroundColor: Colors.white24),
                          icon: Icon(r.paused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                          onPressed: r.togglePause,
                        ),
                        IconButton.filled(
                          key: const Key('skipAbStep'),
                          iconSize: 44,
                          style: IconButton.styleFrom(backgroundColor: Colors.white24),
                          icon: const Icon(Icons.skip_next, color: Colors.white),
                          onPressed: r.skip,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
