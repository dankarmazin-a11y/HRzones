import 'package:flutter/material.dart';

/// Where the user trains (setting `place`, default gym). [hybrid] = asked
/// every time a workout starts. Filters the exercise list and the starter
/// programs.
enum TrainingPlace { gym, home, outdoors, hybrid }

extension TrainingPlaceInfo on TrainingPlace {
  String get label => switch (this) {
    TrainingPlace.gym => 'Gym',
    TrainingPlace.home => 'Home',
    TrainingPlace.outdoors => 'Outdoors',
    TrainingPlace.hybrid => 'Hybrid',
  };

  IconData get icon => switch (this) {
    TrainingPlace.gym => Icons.fitness_center,
    TrainingPlace.home => Icons.home_outlined,
    TrainingPlace.outdoors => Icons.park_outlined,
    TrainingPlace.hybrid => Icons.shuffle,
  };

  String get description => switch (this) {
    TrainingPlace.gym => 'Every exercise and machine.',
    TrainingPlace.home => 'Bodyweight, dumbbells, kettlebells, bands and balls.',
    TrainingPlace.outdoors => 'Bodyweight and bands (park bars count as bodyweight).',
    TrainingPlace.hybrid => 'You choose gym, home or outdoors each time you start a workout.',
  };

  /// Equipment (free-exercise-db values) available here; null = everything.
  /// Exercises without equipment (most stretches, cardio) always count.
  Set<String>? get equipment => switch (this) {
    TrainingPlace.gym || TrainingPlace.hybrid => null,
    TrainingPlace.home => const {
      'body only',
      'dumbbell',
      'kettlebells',
      'bands',
      'exercise ball',
      'medicine ball',
      'foam roll',
    },
    TrainingPlace.outdoors => const {'body only', 'bands'},
  };

  /// True when an exercise with [equipment] can be done here.
  bool allows(String? equipment) {
    final set = this.equipment;
    return set == null || equipment == null || set.contains(equipment);
  }

  /// The places a workout can actually happen at (not hybrid).
  static const concrete = [TrainingPlace.gym, TrainingPlace.home, TrainingPlace.outdoors];
}
