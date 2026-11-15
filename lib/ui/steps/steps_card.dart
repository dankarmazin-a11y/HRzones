import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../workout/streak.dart';
import '../number_input.dart';
import '../run/run_records.dart' show formatThousands;
import '../theme/app_theme.dart';

/// Home: today's steps as a ring towards the step goal, the last 7 days as
/// bars (full = goal reached). Counted by the iPhone all day – no workout, no
/// GPS. Hidden when the phone can't tell or the goal is 0.
class StepsTodayCard extends StatefulWidget {
  const StepsTodayCard({super.key});

  /// Average stride for "km on foot" (rough – the iPhone knows better, but
  /// only gives distance for its own count).
  static const strideM = 0.75;

  @override
  State<StepsTodayCard> createState() => _StepsTodayCardState();
}

class _StepsTodayCardState extends State<StepsTodayCard> with WidgetsBindingObserver {
  List<int>? _days;
  Timer? _timer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
    // a fresh count every minute while Home is open
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    final d = await Services.of(context).run.motion.dailySteps(7);
    if (mounted) setState(() => _days = d);
  }

  Future<void> _editGoal(AppServices s) async {
    final n = await promptNumber(
      context,
      title: 'Steps a day',
      initial: s.stepGoal.value.toDouble(),
      min: 1000,
      max: 50000,
      suffix: 'steps',
    );
    if (n != null) await s.setStepGoal(n.round());
  }

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final days = _days;
    if (days == null || days.isEmpty) return const SizedBox.shrink();
    return ValueListenableBuilder<int>(
      valueListenable: s.stepGoal,
      builder: (context, goal, _) {
        if (goal <= 0) return const SizedBox.shrink();
        final t = AppTheme.of(context);
        final text = Theme.of(context).textTheme;
        final today = days.last;
        final reached = days.where((d) => d >= goal).length;
        final left = goal - today;
        final now = DateTime.now();
        return Card(
          key: const Key('stepsToday'),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _editGoal(s),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 92,
                        height: 92,
                        child: CustomPaint(
                          painter: _Ring(progress: (today / goal).clamp(0.0, 1.0), color: t.second, track: t.track),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formatThousands(today),
                                  key: const Key('stepsTodayCount'),
                                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                Text('of ${formatThousands(goal)}', style: text.bodySmall),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Steps today', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              left > 0 ? '${formatThousands(left)} to go' : 'Goal reached',
                              key: const Key('stepsLeft'),
                              style: text.bodyMedium,
                            ),
                            Text(
                              'Goal reached $reached of ${days.length} days',
                              style: text.bodySmall?.copyWith(color: t.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 0; i < days.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: SizedBox(
                                    height: 34,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(child: ColoredBox(color: t.track)),
                                        Align(
                                          alignment: Alignment.bottomCenter,
                                          child: FractionallySizedBox(
                                            heightFactor: (days[i] / goal).clamp(0.0, 1.0),
                                            widthFactor: 1,
                                            child: ColoredBox(color: t.second),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  weekLetters[dayIndex(now.subtract(Duration(days: days.length - 1 - i)).weekday)],
                                  style: text.bodySmall?.copyWith(
                                    color: t.muted,
                                    fontWeight: i == days.length - 1 ? FontWeight.w800 : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

class _Ring extends CustomPainter {
  _Ring({required this.progress, required this.color, required this.track});

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2 - 6;
    final c = size.center(Offset.zero);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, p..color = track);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        p..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_Ring old) => old.progress != progress || old.color != color || old.track != track;
}
