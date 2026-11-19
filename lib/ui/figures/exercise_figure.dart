import 'dart:convert';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Line figures of the exercises the owner marked "Done" in the figures
/// review (owner, 19 Nov: records use them). `tool/poses/export_figures.js`
/// records the review page's drawing as vector steps for the start (frame 0)
/// and end (frame 1) of the movement; `assets/figures.json.gz` ships them.
///
/// Each step is a list: B begin path, M/L move/line to (x, y), S stroke,
/// F fill, A arc (x, y, r, start, end), E ellipse (x, y, rx, ry, rotation,
/// start, end), R rounded rect (x, y, w, h, r), FR fill rect, C / K stroke /
/// fill colour, W line width, P line cap (r/b/s), G alpha. Sizes are shares of
/// the square. Colours: i figure ink, b working muscle (bright), s helping
/// muscle, f floor, p bench/props, `x` + hex a fixed grey (bars, plates).
const figureAsset = 'assets/figures.json.gz';

class FigureLibrary {
  FigureLibrary._();

  static Map<String, List<List<List<Object>>>>? _figures;
  static Future<void>? _loading;

  /// Tests switch the figures off (no asset loading in widget tests) or put
  /// their own in with [debugSet].
  static bool enabled = true;

  /// Loads the figures once (unpacked off the main thread).
  static Future<void> load([AssetBundle? bundle]) => _loading ??= () async {
    final data = await (bundle ?? rootBundle).load(figureAsset);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    _figures = await compute(decodeFigures, bytes);
  }();

  /// The steps of one frame (0 = start, 1 = end), or null without a figure.
  static List<List<Object>>? frame(String exerciseId, int frame) {
    final f = _figures?[exerciseId];
    if (f == null || f.isEmpty) return null;
    return f[frame.clamp(0, f.length - 1)];
  }

  static bool has(String exerciseId) => _figures?.containsKey(exerciseId) ?? false;

  static bool get loaded => _figures != null;

  @visibleForTesting
  static void debugSet(Map<String, List<List<List<Object>>>>? figures) {
    _figures = figures;
    _loading = figures == null ? null : Future.value();
  }
}

/// Unpacks `figures.json.gz`.
Map<String, List<List<List<Object>>>> decodeFigures(Uint8List packed) {
  final json = jsonDecode(utf8.decode(const GZipDecoder().decodeBytes(packed))) as Map<String, dynamic>;
  return {
    for (final MapEntry(:key, :value) in json.entries)
      key: [
        for (final frame in value as List)
          [
            for (final step in frame as List) [for (final v in step as List) v as Object],
          ],
      ],
  };
}

/// The colours a figure is drawn in.
class FigureColors {
  const FigureColors({
    required this.ink,
    required this.bright,
    required this.second,
    required this.floor,
    required this.prop,
  });

  factory FigureColors.of(BuildContext context) {
    final t = AppTheme.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return FigureColors(
      ink: dark ? Colors.white : t.ink,
      bright: t.bright,
      second: Color.lerp(t.bright, dark ? Colors.black : Colors.white, 0.55)!,
      floor: dark ? const Color(0xFF2E3749) : const Color(0xFFD4D8DF),
      prop: dark ? Colors.white.withValues(alpha: 0.22) : const Color(0x29141B2B),
    );
  }

  final Color ink, bright, second, floor, prop;

  Color resolve(Object code) {
    final c = '$code';
    return switch (c) {
      'i' => ink,
      'b' => bright,
      's' => second,
      'f' => floor,
      'p' => prop,
      _ when c.startsWith('x') && c.length == 7 => Color(0xFF000000 | int.parse(c.substring(1), radix: 16)),
      _ => ink,
    };
  }
}

/// Draws one frame of an exercise's line figure.
class FigurePainter extends CustomPainter {
  FigurePainter(this.steps, this.colors);

  final List<List<Object>> steps;
  final FigureColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.shortestSide;
    double n(Object v) => (v as num).toDouble();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final fill = Paint()..style = PaintingStyle.fill;
    var alpha = 1.0;
    var path = Path();
    Color withAlpha(Color c) => alpha >= 1 ? c : c.withValues(alpha: c.a * alpha);
    for (final s in steps) {
      final a = s.length > 1 ? s.sublist(1) : const <Object>[];
      switch (s.first) {
        case 'B':
          path = Path();
        case 'M':
          path.moveTo(n(a[0]) * w, n(a[1]) * w);
        case 'L':
          path.lineTo(n(a[0]) * w, n(a[1]) * w);
        case 'S':
          canvas.drawPath(path, stroke);
        case 'F':
          canvas.drawPath(path, fill);
        case 'A':
          _arc(path, n(a[0]) * w, n(a[1]) * w, n(a[2]) * w, n(a[2]) * w, 0, n(a[3]), n(a[4]));
        case 'E':
          _arc(path, n(a[0]) * w, n(a[1]) * w, n(a[2]) * w, n(a[3]) * w, n(a[4]), n(a[5]), n(a[6]));
        case 'R':
          path.addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(n(a[0]) * w, n(a[1]) * w, n(a[2]) * w, n(a[3]) * w),
              Radius.circular(n(a[4]) * w),
            ),
          );
        case 'FR':
          canvas.drawRect(Rect.fromLTWH(n(a[0]) * w, n(a[1]) * w, n(a[2]) * w, n(a[3]) * w), fill);
        case 'C':
          stroke.color = withAlpha(colors.resolve(a[0]));
        case 'K':
          fill.color = withAlpha(colors.resolve(a[0]));
        case 'W':
          stroke.strokeWidth = math.max(0.6, n(a[0]) * w);
        case 'P':
          stroke.strokeCap = switch (a[0]) {
            'b' => StrokeCap.butt,
            's' => StrokeCap.square,
            _ => StrokeCap.round,
          };
        case 'G':
          alpha = n(a[0]);
      }
    }
  }

  /// Canvas-style arc / ellipse: a full turn is a closed oval, otherwise an arc
  /// joined to the current point like the browser does.
  static void _arc(Path p, double x, double y, double rx, double ry, double rot, double start, double end) {
    final sweep = end - start;
    if (sweep.abs() >= 2 * math.pi - 0.001 && rot == 0) {
      p.addOval(Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2));
      return;
    }
    if (rot == 0) {
      p.arcTo(Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2), start, sweep, false);
      return;
    }
    final m = Matrix4.identity()
      ..translateByDouble(x, y, 0, 1)
      ..rotateZ(rot);
    final o = Path()..addArc(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), start, sweep);
    p.addPath(o.transform(m.storage), Offset.zero);
  }

  @override
  bool shouldRepaint(FigurePainter old) => old.steps != steps || old.colors.ink != colors.ink;
}

/// The exercise's line figure (end of the movement by default), or
/// [fallback] when there is none yet (or the figures haven't loaded).
class ExerciseFigure extends StatefulWidget {
  const ExerciseFigure({super.key, required this.exerciseId, this.size = 40, this.frame = 1, required this.fallback});

  final String exerciseId;
  final double size;
  final int frame;
  final Widget fallback;

  @override
  State<ExerciseFigure> createState() => _ExerciseFigureState();
}

class _ExerciseFigureState extends State<ExerciseFigure> {
  @override
  void initState() {
    super.initState();
    if (FigureLibrary.enabled && !FigureLibrary.loaded) {
      FigureLibrary.load().then((_) {
        if (mounted) setState(() {});
      }, onError: (Object _) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = FigureLibrary.enabled ? FigureLibrary.frame(widget.exerciseId, widget.frame) : null;
    if (steps == null) return widget.fallback;
    return SizedBox.square(
      key: Key('figure_${widget.exerciseId}'),
      dimension: widget.size,
      child: CustomPaint(painter: FigurePainter(steps, FigureColors.of(context))),
    );
  }
}
