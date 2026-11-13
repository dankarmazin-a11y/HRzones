import 'package:flutter/material.dart';

import '../app_services.dart';
import 'run/run_start.dart';
import 'screens/workouts_screen.dart';
import 'theme/app_theme.dart';
import 'timers/timers_screen.dart';

/// The big round Start button in the middle of the tab bar.
/// Opens the Start menu, or goes back to a running workout / run.
class StartButton extends StatelessWidget {
  const StartButton({super.key});

  /// The circle; the tab bar rises around it (`StartBump`).
  static const size = 70.0;

  /// How far the circle sticks up above the tab bar.
  static const overhang = size / 2 + 6;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final scheme = Theme.of(context).colorScheme;
    final t = AppTheme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([s.session, s.run]),
      builder: (context, _) {
        final busy = s.session.active != null || s.run.active;
        // Owner pick (2026-11-13): big outlined play icon, the word solid and
        // bold, a soft glow of the bright colour around the circle.
        return Semantics(
          button: true,
          label: busy ? 'Back to your workout' : 'Train',
          child: GestureDetector(
            key: const Key('startButton'),
            onTap: () => openStart(context),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: t.bright.withValues(alpha: 0.22), spreadRadius: 6),
                  BoxShadow(color: t.bright.withValues(alpha: 0.42), blurRadius: 22, offset: const Offset(0, 8)),
                ],
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(size: const Size.square(30), painter: _OutlinedPlay(scheme.onPrimary)),
                  Text(
                    busy ? 'Back' : 'Train',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      height: 1.1,
                      letterSpacing: 0.2,
                    ),
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

/// ▷ with rounded corners, drawn as an outline.
class _OutlinedPlay extends CustomPainter {
  _OutlinedPlay(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(
      Path()
        ..moveTo(8, 5.2)
        ..lineTo(8, 18.8)
        ..lineTo(18.8, 12)
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_OutlinedPlay old) => old.color != color;
}

/// The tab bar's top edge rising like a hill around the Start button.
class StartBump extends StatelessWidget {
  const StartBump({super.key, required this.color});

  static const width = 200.0;
  static const height = 28.0;

  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(width, height + 1), painter: _BumpPainter(color));
}

class _BumpPainter extends CustomPainter {
  _BumpPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = StartBump.height;
    final path = Path()
      ..moveTo(0, h)
      ..cubicTo(w * 0.22, h, w * 0.24, 0, w * 0.5, 0)
      ..cubicTo(w * 0.76, 0, w * 0.78, h, w, h)
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BumpPainter old) => old.color != color;
}

/// Start button: back to a running workout or run, else the Start menu.
Future<void> openStart(BuildContext context) async {
  final s = Services.of(context);
  if (s.session.active != null) return openActiveWorkout(context);
  if (s.run.active) return openLiveRun(context);
  final pick = await showModalBottomSheet<Future<void> Function(BuildContext)>(
    context: context,
    builder: (_) => const StartMenu(),
  );
  if (pick != null && context.mounted) await pick(context);
}

/// Big tiles: strength, run, empty workout, timer. Pops with what to start
/// (run with the caller's context, which outlives the sheet).
class StartMenu extends StatelessWidget {
  const StartMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = Theme.of(context).textTheme;
    void pick(Future<void> Function(BuildContext) f) => Navigator.of(context).pop(f);
    Widget tile({
      required Key key,
      required IconData icon,
      required String title,
      required String subtitle,
      required Color bg,
      required Color fg,
      required Future<void> Function(BuildContext) action,
    }) => Expanded(
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(10),
          onTap: () => pick(action),
          child: Container(
            height: 112,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: fg.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: fg, size: 19),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      subtitle,
                      style: text.bodySmall?.copyWith(color: fg.withValues(alpha: 0.75)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Train', style: text.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                tile(
                  key: const Key('startStrength'),
                  icon: Icons.fitness_center,
                  title: 'Strength',
                  subtitle: 'Pick a template',
                  // Light: the dark ink tile. Dark: the bright colour (ink is light there).
                  bg: dark ? t.bright : t.ink,
                  fg: onColor(dark ? t.bright : t.ink),
                  action: quickStartStrength,
                ),
                const SizedBox(width: 8),
                tile(
                  key: const Key('startRunHome'),
                  icon: Icons.directions_run,
                  title: 'Run',
                  subtitle: 'Outdoor or treadmill',
                  bg: t.second,
                  fg: t.onSecond,
                  action: (c) => startRun(c),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                tile(
                  key: const Key('startEmpty'),
                  icon: Icons.add,
                  title: 'Empty workout',
                  subtitle: 'Pick as you go',
                  bg: t.field,
                  fg: t.ink,
                  action: startEmptyWorkout,
                ),
                const SizedBox(width: 8),
                tile(
                  key: const Key('startTimer'),
                  icon: Icons.timer_outlined,
                  title: 'Timer',
                  subtitle: 'Tabata, EMOM…',
                  bg: t.field,
                  fg: t.ink,
                  action: (c) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => const TimersScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
