import 'package:flutter/material.dart';

/// Tools tab icon: a stopwatch with a small heart overlapping its lower
/// right corner. The heart has a thin ring in the background colour so the
/// two shapes stay apart.
class ToolsIcon extends StatelessWidget {
  const ToolsIcon({super.key, this.selected = false});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 24;
    final color = theme.color;
    final scheme = Theme.of(context).colorScheme;
    // Behind the heart: the selected pill or the navigation bar itself.
    final ring = selected ? scheme.secondaryContainer : scheme.surfaceContainer;
    final heart = size * 0.52;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -size * 0.08,
            top: -size * 0.04,
            child: Icon(selected ? Icons.timer : Icons.timer_outlined, size: size, color: color),
          ),
          Positioned(
            right: -size * 0.22,
            bottom: -size * 0.14,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.favorite, size: heart + size * 0.2, color: ring),
                Icon(Icons.favorite, size: heart, color: selected ? Colors.red.shade600 : color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
