import 'package:flutter/material.dart';

/// A muscle region of the schematic body, in coordinates relative to one
/// figure (0–1 horizontally and vertically).
class MuscleRegion {
  const MuscleRegion(this.muscle, this.rect);

  final String muscle;
  final Rect rect;
}

Rect _r(double x, double y, double w, double h) => Rect.fromLTWH(x, y, w, h);

/// Both sides of a region (left/right mirror of [x]).
List<MuscleRegion> _pair(String m, double x, double y, double w, double h) => [
  MuscleRegion(m, _r(x, y, w, h)),
  MuscleRegion(m, _r(1 - x - w, y, w, h)),
];

final frontRegions = <MuscleRegion>[
  const MuscleRegion('neck', Rect.fromLTWH(0.44, 0.115, 0.12, 0.035)),
  ..._pair('shoulders', 0.19, 0.155, 0.13, 0.08),
  ..._pair('chest', 0.33, 0.16, 0.165, 0.10),
  ..._pair('biceps', 0.16, 0.245, 0.10, 0.12),
  ..._pair('forearms', 0.11, 0.375, 0.10, 0.14),
  const MuscleRegion('abdominals', Rect.fromLTWH(0.385, 0.27, 0.23, 0.19)),
  ..._pair('abductors', 0.28, 0.46, 0.06, 0.09),
  ..._pair('quadriceps', 0.335, 0.49, 0.14, 0.23),
  const MuscleRegion('adductors', Rect.fromLTWH(0.475, 0.50, 0.05, 0.12)),
  ..._pair('calves', 0.345, 0.75, 0.115, 0.17),
];

final backRegions = <MuscleRegion>[
  const MuscleRegion('traps', Rect.fromLTWH(0.37, 0.115, 0.26, 0.09)),
  ..._pair('shoulders', 0.19, 0.155, 0.13, 0.08),
  ..._pair('triceps', 0.16, 0.245, 0.10, 0.12),
  ..._pair('forearms', 0.11, 0.375, 0.10, 0.14),
  ..._pair('lats', 0.30, 0.215, 0.115, 0.17),
  const MuscleRegion('middle back', Rect.fromLTWH(0.415, 0.21, 0.17, 0.12)),
  const MuscleRegion('lower back', Rect.fromLTWH(0.40, 0.335, 0.20, 0.10)),
  ..._pair('glutes', 0.335, 0.445, 0.155, 0.10),
  ..._pair('hamstrings', 0.335, 0.555, 0.14, 0.17),
  ..._pair('calves', 0.345, 0.75, 0.115, 0.17),
];

/// The muscle at a point of a figure (relative coordinates), or null.
String? muscleAt(Offset p, {required bool back}) {
  for (final r in (back ? backRegions : frontRegions).reversed) {
    if (r.rect.contains(p)) return r.muscle;
  }
  return null;
}

/// Tappable front + back body. [selected] is highlighted; [heat] (0–1 per
/// muscle) can colour muscles by training load (used later for the heat map).
class BodyMap extends StatelessWidget {
  const BodyMap({super.key, this.selected, this.onTap, this.heat = const {}});

  final String? selected;
  final ValueChanged<String?>? onTap;
  final Map<String, double> heat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget figure(bool back) => Expanded(
      child: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 0.5,
              child: LayoutBuilder(
                builder: (context, c) => GestureDetector(
                  key: Key(back ? 'bodyMapBack' : 'bodyMapFront'),
                  onTapUp: onTap == null
                      ? null
                      : (d) {
                          final p = Offset(d.localPosition.dx / c.maxWidth, d.localPosition.dy / c.maxHeight);
                          final m = muscleAt(p, back: back);
                          if (m != null) onTap!(m == selected ? null : m);
                        },
                  child: CustomPaint(
                    size: Size(c.maxWidth, c.maxHeight),
                    painter: _BodyPainter(
                      regions: back ? backRegions : frontRegions,
                      selected: selected,
                      heat: heat,
                      base: scheme.surfaceContainerHigh,
                      muscle: scheme.secondaryContainer,
                      highlight: scheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            back ? 'Back' : (selected == null ? 'Front · tap a muscle' : 'Front'),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
    return Row(children: [figure(false), figure(true)]);
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.regions,
    required this.selected,
    required this.heat,
    required this.base,
    required this.muscle,
    required this.highlight,
  });

  final List<MuscleRegion> regions;
  final String? selected;
  final Map<String, double> heat;
  final Color base;
  final Color muscle;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    Rect s(Rect r) =>
        Rect.fromLTWH(r.left * size.width, r.top * size.height, r.width * size.width, r.height * size.height);
    RRect rr(Rect r, [double radius = 0.04]) => RRect.fromRectAndRadius(s(r), Radius.circular(radius * size.width));
    final body = Paint()..color = base;

    // Silhouette: head, torso, arms, legs.
    canvas.drawCircle(Offset(0.5 * size.width, 0.06 * size.height), 0.075 * size.width, body);
    canvas.drawRRect(rr(_r(0.29, 0.13, 0.42, 0.36), 0.08), body);
    for (final x in [0.11, 0.79]) {
      canvas.drawRRect(rr(_r(x, 0.15, 0.10, 0.37), 0.05), body);
    }
    for (final x in [0.32, 0.505]) {
      canvas.drawRRect(rr(_r(x, 0.47, 0.175, 0.47), 0.06), body);
    }

    for (final r in regions) {
      final h = heat[r.muscle];
      final color = r.muscle == selected
          ? highlight
          : (h != null && h > 0 ? Color.lerp(muscle, highlight, h.clamp(0, 1) * 0.8)! : muscle);
      canvas.drawRRect(rr(r.rect, 0.03), Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_BodyPainter old) => old.selected != selected || old.heat != heat || old.highlight != highlight;
}
