import 'package:flutter/material.dart';

import '../zone_colors.dart';
import 'app_theme.dart';

/// The app icon's heart: red, with a white pulse line (same shape as the
/// heart emblem, 24 grid).
class HeartLogo extends StatelessWidget {
  const HeartLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _HeartPainter());
}

class _HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final heart = Path()
      ..moveTo(12, 20)
      ..cubicTo(7, 16.5, 3, 13.5, 3, 9.5)
      ..cubicTo(3, 6.8, 5, 5, 7.4, 5)
      ..cubicTo(9.3, 5, 11, 6.2, 12, 7.8)
      ..cubicTo(13, 6.2, 14.7, 5, 16.6, 5)
      ..cubicTo(19, 5, 21, 6.8, 21, 9.5)
      ..cubicTo(21, 13.5, 17, 16.5, 12, 20)
      ..close();
    canvas.drawPath(heart, Paint()..color = AppColors.heart);
    final pulse = Path()
      ..moveTo(5.4, 12.2)
      ..lineTo(8.6, 12.2)
      ..lineTo(10.0, 9.4)
      ..lineTo(12.3, 15.0)
      ..lineTo(14.0, 11.0)
      ..lineTo(15.2, 12.2)
      ..lineTo(18.6, 12.2);
    canvas.drawPath(
      pulse,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_HeartPainter old) => false;
}

/// Loading screen (owner pick "B", 2026-11-13): the heart beats lub-dub and
/// the five zone colours light up one after another underneath.
class BeatingHeart extends StatefulWidget {
  const BeatingHeart({super.key, this.size = 96});

  final double size;

  @override
  State<BeatingHeart> createState() => _BeatingHeartState();
}

class _BeatingHeartState extends State<BeatingHeart> with TickerProviderStateMixin {
  late final _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  late final _zones = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

  // lub (big) – dub (smaller) – rest.
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.13).chain(CurveTween(curve: Curves.easeOut)), weight: 14),
    TweenSequenceItem(tween: Tween(begin: 1.13, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 14),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08).chain(CurveTween(curve: Curves.easeOut)), weight: 14),
    TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 28),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
  ]).animate(_beat);

  @override
  void dispose() {
    _beat.dispose();
    _zones.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ScaleTransition(
        scale: _scale,
        child: HeartLogo(size: widget.size),
      ),
      SizedBox(height: widget.size * 0.22),
      AnimatedBuilder(
        animation: _zones,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var z = 1; z <= 5; z++)
              Container(
                key: Key('loadingZone_$z'),
                width: 20,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  color: zoneColor(z).withValues(alpha: _zoneOpacity(z)),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ),
    ],
  );

  /// Each bar lights up for a moment, 0.1 s after the one before.
  double _zoneOpacity(int z) {
    final t = (_zones.value - (z - 1) * 0.1) % 1.0;
    const on = 0.3;
    if (t < on) {
      final k = t / on;
      return 0.25 + 0.75 * (k < 0.5 ? k * 2 : (1 - k) * 2);
    }
    return 0.25;
  }
}
