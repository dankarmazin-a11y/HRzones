import 'package:flutter/material.dart';

import '../images/cached_image.dart';
import '../../data/database.dart';
import '../../data/exercise_repository.dart';

/// Round picture of an exercise (first photo from free-exercise-db), with the
/// first letter (or a stretch icon) as fallback while loading / offline.
class ExerciseAvatar extends StatelessWidget {
  const ExerciseAvatar({super.key, required this.exercise, this.radius = 20});

  final Exercise exercise;
  final double radius;

  /// Off in widget tests (no network there).
  static bool loadImages = true;

  @override
  Widget build(BuildContext context) {
    final path = exercise.imagePath;
    // An interval timer must not look like the Stretching card.
    final fallback = exercise.isInterval
        ? Icon(Icons.timer_outlined, size: radius)
        : exercise.isStretch
        ? Icon(Icons.self_improvement, size: radius)
        : Text(exercise.name.isEmpty ? '?' : exercise.name[0], style: TextStyle(fontSize: radius * 0.8));
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return CircleAvatar(
      radius: radius,
      foregroundImage: loadImages && path != null
          ? ResizeImage(cachedNetworkImage('$exerciseImageBase$path'), width: (radius * 2 * dpr).round())
          : null,
      onForegroundImageError: loadImages && path != null ? (_, _) {} : null,
      child: fallback,
    );
  }
}
