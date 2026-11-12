import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The app's own line emblems (docs/DESIGN.md): one family, 1.8 stroke on a
/// 24 × 24 grid, round ends – the same weight as the tab icons.
enum EmblemKind {
  dumbbell,
  kettlebell,
  plate,
  heart,
  stopwatch,
  interval,
  run,
  abs,
  flag,
  shoe,
  calendar,
  plates,
  route,
}

/// One emblem, drawn in [color] (default: the current icon colour).
class EmblemIcon extends StatelessWidget {
  const EmblemIcon(this.kind, {super.key, this.size, this.color, this.bold = false});

  final EmblemKind kind;
  final double? size;
  final Color? color;

  /// Thicker lines (the selected tab).
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    final s = size ?? icon.size ?? 24;
    return SizedBox(
      width: s,
      height: s,
      child: CustomPaint(painter: _EmblemPainter(kind, color ?? icon.color ?? AppTheme.of(context).ink, bold)),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  _EmblemPainter(this.kind, this.color, this.bold);

  final EmblemKind kind;
  final Color color;
  final bool bold;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = bold ? 2.4 : 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void rrect(double x, double y, double w, double h, double r) =>
        canvas.drawRRect(RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(r)), p);
    void circle(double x, double y, double r) => canvas.drawCircle(Offset(x, y), r, p);
    void line(List<double> pts, {bool close = false}) {
      final path = Path()..moveTo(pts[0], pts[1]);
      for (var i = 2; i < pts.length; i += 2) {
        path.lineTo(pts[i], pts[i + 1]);
      }
      if (close) path.close();
      canvas.drawPath(path, p);
    }

    switch (kind) {
      case EmblemKind.dumbbell:
        rrect(5.5, 7, 3, 10, 1);
        rrect(15.5, 7, 3, 10, 1);
        rrect(2.5, 9.5, 3, 5, 1);
        rrect(18.5, 9.5, 3, 5, 1);
        line([8.5, 12, 15.5, 12]);
      case EmblemKind.kettlebell:
        canvas.drawPath(
          Path()
            ..moveTo(9, 10.4)
            ..lineTo(9, 8.5)
            ..arcToPoint(const Offset(15, 8.5), radius: const Radius.circular(3))
            ..lineTo(15, 10.4),
          p,
        );
        canvas.drawPath(
          Path()
            ..addArc(Rect.fromCircle(center: const Offset(12, 14.9), radius: 5.8), 2.36, 4.71)
            ..close(),
          p,
        );
      case EmblemKind.plate:
        circle(12, 12, 8.8);
        circle(12, 12, 5.2);
        circle(12, 12, 1.6);
      case EmblemKind.heart:
        canvas.drawPath(
          Path()
            ..moveTo(12, 20)
            ..cubicTo(7, 16.5, 3, 13.5, 3, 9.5)
            ..cubicTo(3, 6.8, 5, 5, 7.4, 5)
            ..cubicTo(9.3, 5, 11, 6.2, 12, 7.8)
            ..cubicTo(13, 6.2, 14.7, 5, 16.6, 5)
            ..cubicTo(19, 5, 21, 6.8, 21, 9.5)
            ..cubicTo(21, 13.5, 17, 16.5, 12, 20)
            ..close(),
          p,
        );
        line([6.4, 12.4, 8.8, 12.4, 10.2, 10.2, 12.4, 14.4, 14, 11.8, 17.6, 11.8]);
      case EmblemKind.stopwatch:
        circle(12, 13.5, 7);
        line([12, 13.5, 12, 10]);
        line([10, 3, 14, 3]);
        line([12, 3, 12, 6.5]);
        line([18.2, 6.8, 19.6, 5.4]);
      case EmblemKind.interval:
        line([
          3,
          16.5,
          6.5,
          16.5,
          6.5,
          7.5,
          10.5,
          7.5,
          10.5,
          16.5,
          13.5,
          16.5,
          13.5,
          7.5,
          17.5,
          7.5,
          17.5,
          16.5,
          21,
          16.5,
        ]);
      case EmblemKind.run:
        circle(14.8, 4.6, 1.9);
        line([13.2, 8, 11, 13.2, 14.3, 15.8, 13.2, 20.8]);
        line([11, 13.2, 8.5, 16.6, 4.9, 17.1]);
        line([12.9, 9.4, 16.2, 10.9, 18.6, 8.9]);
        line([12.6, 9.2, 9.3, 10.6, 7.7, 12.9]);
      case EmblemKind.abs:
        line([8, 3.5, 16, 3.5, 17.4, 10, 16, 20.5, 8, 20.5, 6.6, 10], close: true);
        line([12, 4, 12, 20]);
        line([8.2, 9, 15.8, 9]);
        line([8.4, 13.2, 15.6, 13.2]);
        line([8.6, 17.2, 15.4, 17.2]);
      case EmblemKind.flag:
        line([6, 21, 6, 3.5]);
        line([6, 4.5, 17.5, 4.5, 14.9, 8.5, 17.5, 12.5, 6, 12.5]);
      case EmblemKind.shoe:
        canvas.drawPath(
          Path()
            ..moveTo(3, 17.8)
            ..lineTo(3, 16.2)
            ..quadraticBezierTo(3, 14.6, 4.6, 14.6)
            ..lineTo(7.8, 14.6)
            ..quadraticBezierTo(9.6, 14.6, 10.3, 13.2)
            ..lineTo(12.3, 9.7)
            ..lineTo(14.5, 11.4)
            ..quadraticBezierTo(15.6, 12.4, 17.7, 12.4)
            ..quadraticBezierTo(21, 12.6, 21, 15.6)
            ..lineTo(21, 17.8)
            ..close(),
          p,
        );
        line([3, 19.8, 21, 19.8]);
      case EmblemKind.calendar:
        rrect(3.5, 5, 17, 15.5, 2.5);
        line([3.5, 10, 20.5, 10]);
        line([8.5, 3, 8.5, 7]);
        line([15.5, 3, 15.5, 7]);
      case EmblemKind.plates:
        line([2.5, 12, 21.5, 12]);
        rrect(6, 6, 3, 12, 1);
        rrect(9.5, 8, 2.5, 8, 1);
        rrect(15, 6, 3, 12, 1);
      case EmblemKind.route:
        canvas.drawPath(
          Path()
            ..moveTo(6, 18.5)
            ..cubicTo(8.5, 13.5, 6.5, 10, 10, 8)
            ..cubicTo(13.5, 6, 16, 9.5, 19, 5.5),
          p,
        );
        circle(6, 18.5, 2.2);
        circle(19, 5.5, 2.2);
    }
  }

  @override
  bool shouldRepaint(_EmblemPainter old) => old.kind != kind || old.color != color || old.bold != bold;
}

/// An emblem centred in a soft tinted box (red heart on pale red for heart rate).
class Emblem extends StatelessWidget {
  const Emblem(this.kind, {super.key, this.size = 36}) : icon = null;

  /// A Material icon in the same box (for things without an emblem).
  const Emblem.icon(IconData this.icon, {super.key, this.size = 36}) : kind = null;

  final EmblemKind? kind;
  final IconData? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final heart = kind == EmblemKind.heart;
    final fg = heart ? AppColors.heart : t.ink;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: heart ? (dark ? const Color(0xFF3A1A1E) : const Color(0xFFFFE3E5)) : t.emblem,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: kind != null ? EmblemIcon(kind!, size: size * 0.58, color: fg) : Icon(icon, size: size * 0.56, color: fg),
    );
  }
}

/// Text where every ♥ is the heart-rate red.
class HeartText extends StatelessWidget {
  const HeartText(this.text, {super.key, this.style, this.maxLines, this.overflow});

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('♥');
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0)
              const TextSpan(
                text: '♥',
                style: TextStyle(color: AppColors.heart),
              ),
            TextSpan(text: parts[i]),
          ],
        ],
      ),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
