/// The user's training level: changes which exercises are listed, how
/// detailed muscle groups are and how many options the workout screen shows.
enum TrainingLevel { beginner, intermediate, advanced }

extension TrainingLevelInfo on TrainingLevel {
  String get label => switch (this) {
    TrainingLevel.beginner => 'Beginner',
    TrainingLevel.intermediate => 'Intermediate',
    TrainingLevel.advanced => 'Advanced',
  };

  String get description => switch (this) {
    TrainingLevel.beginner =>
      'Beginner exercises and simple muscle groups (Back, Arms, Legs…). Workout screen without RPE and set types.',
    TrainingLevel.intermediate => 'Beginner + intermediate exercises, detailed muscle groups, RPE and set types.',
    TrainingLevel.advanced => 'Every exercise incl. expert ones (Olympic lifts, advanced variations).',
  };

  /// Exercise levels (free-exercise-db) shown in the list. Popular exercises
  /// are always shown.
  Set<String> get exerciseLevels => switch (this) {
    TrainingLevel.beginner => {'beginner'},
    TrainingLevel.intermediate => {'beginner', 'intermediate'},
    TrainingLevel.advanced => {'beginner', 'intermediate', 'expert'},
  };

  bool get detailedMuscles => this != TrainingLevel.beginner;

  /// RPE column and warm-up/drop/failure set types in a workout.
  bool get showsAdvancedSetOptions => this != TrainingLevel.beginner;
}

/// Simple muscle groups for beginners → the detailed muscles they include.
const simpleMuscleGroups = {
  'chest': ['chest'],
  'back': ['lats', 'middle back', 'lower back', 'traps'],
  'shoulders': ['shoulders', 'neck'],
  'arms': ['biceps', 'triceps', 'forearms'],
  'core': ['abdominals'],
  'legs': ['quadriceps', 'hamstrings', 'calves', 'adductors', 'abductors'],
  'glutes': ['glutes'],
};

/// The detailed muscles a filter value stands for.
List<String> musclesOf(String filter) => simpleMuscleGroups[filter] ?? [filter];

/// The simple group a detailed muscle belongs to.
String simpleGroupOf(String muscle) =>
    simpleMuscleGroups.entries.firstWhere((e) => e.value.contains(muscle), orElse: () => MapEntry(muscle, [])).key;
