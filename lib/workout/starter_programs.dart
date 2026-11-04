import '../data/database.dart';
import '../data/template_repository.dart';
import 'training_level.dart';

/// Where a program can be done. Only [gym] has programs for now; home,
/// outdoors etc. come later and get their own chip automatically.
enum ProgramPlace { gym }

extension ProgramPlaceInfo on ProgramPlace {
  String get label => switch (this) {
    ProgramPlace.gym => 'Gym',
  };
}

/// One exercise of a starter workout. [reps] or [seconds] is the target;
/// [warmups] extra warm-up sets come first (advanced programs).
class StarterExercise {
  const StarterExercise(this.id, this.sets, {this.reps, this.seconds, this.rest = 90, this.warmups = 0});

  final String id;
  final int sets;
  final int? reps;
  final int? seconds;
  final int rest;
  final int warmups;

  /// "3 × 10", "3 × 30 s", "2 W + 4 × 6".
  String get scheme {
    final target = seconds != null ? '$seconds s' : '$reps';
    return '${warmups > 0 ? '$warmups W + ' : ''}$sets × $target';
  }

  TemplateSlot toSlot() => TemplateSlot(
    exerciseId: id,
    targetSets: warmups + sets,
    restSeconds: rest,
    sets: [
      for (var i = 0; i < warmups; i++) TemplateSet(type: SetType.warmup, reps: reps, durationS: seconds),
      for (var i = 0; i < sets; i++) TemplateSet(reps: reps, durationS: seconds),
    ],
  );
}

class StarterWorkout {
  const StarterWorkout(this.name, this.exercises);

  final String name;
  final List<StarterExercise> exercises;
}

class StarterProgram {
  const StarterProgram({
    required this.name,
    required this.level,
    required this.schedule,
    required this.description,
    required this.workouts,
    this.place = ProgramPlace.gym,
  });

  final String name;
  final TrainingLevel level;
  final ProgramPlace place;

  /// e.g. "3× a week".
  final String schedule;
  final String description;
  final List<StarterWorkout> workouts;
}

/// A starter workout as an (unsaved) template, to start it right away.
TemplateWithSlots starterTemplate(StarterProgram p, StarterWorkout w) => TemplateWithSlots(
  template: Template(id: '', updatedAt: DateTime.now(), name: w.name, folder: p.name, notes: '', position: 0),
  slots: [for (final e in w.exercises) e.toSlot()],
);

/// Saves all workouts of [p] as templates in a folder named after it.
Future<void> addProgramToTemplates(TemplateRepository repo, StarterProgram p) async {
  for (final w in p.workouts) {
    await repo.save(name: w.name, folder: p.name, slots: [for (final e in w.exercises) e.toSlot()]);
  }
}

typedef _E = StarterExercise;

/// Ready-made programs with regular gym equipment. Exercise ids come from
/// assets/exercises.json (checked by test/starter_programs_test.dart).
const starterPrograms = <StarterProgram>[
  // ---- Beginner ------------------------------------------------------------
  StarterProgram(
    name: 'Full Body A/B',
    level: TrainingLevel.beginner,
    schedule: '3× a week, alternate A and B',
    description: 'The classic first program: every muscle three times a week with simple, safe exercises.',
    workouts: [
      StarterWorkout('Full Body A', [
        _E('Leg_Press', 3, reps: 10),
        _E('Leverage_Chest_Press', 3, reps: 10),
        _E('Wide-Grip_Lat_Pulldown', 3, reps: 10),
        _E('Dumbbell_Shoulder_Press', 3, reps: 10),
        _E('Lying_Leg_Curls', 3, reps: 12, rest: 60),
        _E('Plank', 3, seconds: 30, rest: 45),
      ]),
      StarterWorkout('Full Body B', [
        _E('Goblet_Squat', 3, reps: 10),
        _E('Dumbbell_Bench_Press', 3, reps: 10),
        _E('Seated_Cable_Rows', 3, reps: 10),
        _E('Side_Lateral_Raise', 3, reps: 12, rest: 60),
        _E('hz_glute_bridge', 3, reps: 12, rest: 60),
        _E('Crunches', 3, reps: 15, rest: 45),
      ]),
    ],
  ),
  StarterProgram(
    name: 'Machine Circuit',
    level: TrainingLevel.beginner,
    schedule: '2–3× a week',
    description: 'Machines only – easy to learn and safe without a spotter. Great for your first weeks.',
    workouts: [
      StarterWorkout('Machine Circuit', [
        _E('Leg_Press', 3, reps: 12, rest: 75),
        _E('Leverage_Chest_Press', 3, reps: 12, rest: 75),
        _E('hz_seated_machine_row', 3, reps: 12, rest: 75),
        _E('Machine_Shoulder_Military_Press', 3, reps: 12, rest: 75),
        _E('Leg_Extensions', 2, reps: 15, rest: 60),
        _E('Seated_Leg_Curl', 2, reps: 15, rest: 60),
        _E('Ab_Crunch_Machine', 2, reps: 15, rest: 45),
      ]),
    ],
  ),
  // ---- Intermediate --------------------------------------------------------
  StarterProgram(
    name: 'Upper / Lower',
    level: TrainingLevel.intermediate,
    schedule: '4× a week',
    description: 'Upper body and lower body on separate days, each twice a week. Strength first, then volume.',
    workouts: [
      StarterWorkout('Upper A', [
        _E('Barbell_Bench_Press_-_Medium_Grip', 4, reps: 6, rest: 150),
        _E('Bent_Over_Barbell_Row', 4, reps: 8, rest: 120),
        _E('Standing_Military_Press', 3, reps: 8, rest: 120),
        _E('Wide-Grip_Lat_Pulldown', 3, reps: 10),
        _E('Barbell_Curl', 3, reps: 10, rest: 60),
        _E('Triceps_Pushdown', 3, reps: 12, rest: 60),
      ]),
      StarterWorkout('Lower A', [
        _E('Barbell_Squat', 4, reps: 6, rest: 180),
        _E('Romanian_Deadlift', 3, reps: 8, rest: 120),
        _E('Leg_Press', 3, reps: 10),
        _E('Lying_Leg_Curls', 3, reps: 12, rest: 60),
        _E('Standing_Calf_Raises', 4, reps: 12, rest: 60),
        _E('Hanging_Leg_Raise', 3, reps: 12, rest: 60),
      ]),
      StarterWorkout('Upper B', [
        _E('Incline_Dumbbell_Press', 4, reps: 8, rest: 120),
        _E('Pullups', 4, reps: 8, rest: 120),
        _E('Dumbbell_Shoulder_Press', 3, reps: 10),
        _E('Seated_Cable_Rows', 3, reps: 10),
        _E('Side_Lateral_Raise', 3, reps: 15, rest: 60),
        _E('Hammer_Curls', 3, reps: 10, rest: 60),
        _E('Cable_Rope_Overhead_Triceps_Extension', 3, reps: 12, rest: 60),
      ]),
      StarterWorkout('Lower B', [
        _E('Barbell_Deadlift', 3, reps: 5, rest: 180),
        _E('hz_bulgarian_split_squat', 3, reps: 10),
        _E('Leg_Extensions', 3, reps: 12, rest: 60),
        _E('Seated_Leg_Curl', 3, reps: 12, rest: 60),
        _E('Seated_Calf_Raise', 4, reps: 15, rest: 60),
        _E('Cable_Crunch', 3, reps: 15, rest: 60),
      ]),
    ],
  ),
  StarterProgram(
    name: 'Push / Pull / Legs',
    level: TrainingLevel.intermediate,
    schedule: '3× a week (or 6× for twice through)',
    description: 'Pushing muscles, pulling muscles and legs on their own days. Easy to fit around runs.',
    workouts: [
      StarterWorkout('Push', [
        _E('Barbell_Bench_Press_-_Medium_Grip', 4, reps: 8, rest: 150),
        _E('Incline_Dumbbell_Press', 3, reps: 10),
        _E('Standing_Military_Press', 3, reps: 8, rest: 120),
        _E('Side_Lateral_Raise', 3, reps: 15, rest: 60),
        _E('Triceps_Pushdown_-_Rope_Attachment', 3, reps: 12, rest: 60),
        _E('Cable_Rope_Overhead_Triceps_Extension', 3, reps: 12, rest: 60),
      ]),
      StarterWorkout('Pull', [
        _E('Pullups', 4, reps: 8, rest: 120),
        _E('Bent_Over_Barbell_Row', 4, reps: 8, rest: 120),
        _E('Seated_Cable_Rows', 3, reps: 10),
        _E('Face_Pull', 3, reps: 15, rest: 60),
        _E('Barbell_Curl', 3, reps: 10, rest: 60),
        _E('Hammer_Curls', 3, reps: 12, rest: 60),
      ]),
      StarterWorkout('Legs', [
        _E('Barbell_Squat', 4, reps: 8, rest: 180),
        _E('Romanian_Deadlift', 3, reps: 10, rest: 120),
        _E('Leg_Press', 3, reps: 12),
        _E('Lying_Leg_Curls', 3, reps: 12, rest: 60),
        _E('Standing_Calf_Raises', 4, reps: 15, rest: 60),
        _E('Plank', 3, seconds: 45, rest: 45),
      ]),
    ],
  ),
  StarterProgram(
    name: 'Strength 5×5',
    level: TrainingLevel.intermediate,
    schedule: '3× a week, alternate A and B',
    description: 'Few big barbell lifts, heavy and simple. Add 2.5 kg when you hit all 5×5.',
    workouts: [
      StarterWorkout('5×5 A', [
        _E('Barbell_Squat', 5, reps: 5, rest: 180),
        _E('Barbell_Bench_Press_-_Medium_Grip', 5, reps: 5, rest: 180),
        _E('Bent_Over_Barbell_Row', 5, reps: 5, rest: 150),
      ]),
      StarterWorkout('5×5 B', [
        _E('Barbell_Squat', 5, reps: 5, rest: 180),
        _E('Standing_Military_Press', 5, reps: 5, rest: 180),
        _E('Barbell_Deadlift', 1, reps: 5, rest: 180),
      ]),
    ],
  ),
  // ---- Advanced ------------------------------------------------------------
  StarterProgram(
    name: 'Powerbuilding',
    level: TrainingLevel.advanced,
    schedule: '4× a week',
    description: 'A heavy main lift with warm-up sets, then bodybuilding work. Strength and size together.',
    workouts: [
      StarterWorkout('Bench Day', [
        _E('Barbell_Bench_Press_-_Medium_Grip', 4, reps: 4, rest: 180, warmups: 2),
        _E('Barbell_Incline_Bench_Press_-_Medium_Grip', 3, reps: 8, rest: 120),
        _E('Dips_-_Chest_Version', 3, reps: 10),
        _E('Cable_Crossover', 3, reps: 15, rest: 60),
        _E('EZ-Bar_Skullcrusher', 3, reps: 10, rest: 75),
        _E('Side_Lateral_Raise', 4, reps: 15, rest: 45),
      ]),
      StarterWorkout('Squat Day', [
        _E('Barbell_Squat', 4, reps: 4, rest: 210, warmups: 2),
        _E('Front_Barbell_Squat', 3, reps: 8, rest: 150),
        _E('hz_bulgarian_split_squat', 3, reps: 10),
        _E('Leg_Extensions', 3, reps: 15, rest: 60),
        _E('Standing_Calf_Raises', 4, reps: 12, rest: 60),
        _E('Ab_Roller', 3, reps: 10, rest: 60),
      ]),
      StarterWorkout('Overhead Day', [
        _E('Standing_Military_Press', 4, reps: 5, rest: 180, warmups: 2),
        _E('Pullups', 4, reps: 8, rest: 120),
        _E('Arnold_Dumbbell_Press', 3, reps: 10),
        _E('T-Bar_Row_with_Handle', 3, reps: 10),
        _E('Face_Pull', 3, reps: 15, rest: 60),
        _E('Barbell_Curl', 3, reps: 10, rest: 60),
      ]),
      StarterWorkout('Deadlift Day', [
        _E('Barbell_Deadlift', 3, reps: 3, rest: 240, warmups: 2),
        _E('Romanian_Deadlift', 3, reps: 8, rest: 150),
        _E('Bent_Over_Barbell_Row', 3, reps: 8, rest: 120),
        _E('Barbell_Hip_Thrust', 3, reps: 10, rest: 120),
        _E('Lying_Leg_Curls', 3, reps: 12, rest: 60),
        _E('Hanging_Leg_Raise', 3, reps: 12, rest: 60),
      ]),
    ],
  ),
  StarterProgram(
    name: '5-Day Split',
    level: TrainingLevel.advanced,
    schedule: '5× a week',
    description: 'One muscle group a day with lots of volume – for experienced lifters with time to train.',
    workouts: [
      StarterWorkout('Chest', [
        _E('Barbell_Bench_Press_-_Medium_Grip', 4, reps: 6, rest: 150, warmups: 1),
        _E('Incline_Dumbbell_Press', 4, reps: 10),
        _E('Dips_-_Chest_Version', 3, reps: 12),
        _E('Butterfly', 3, reps: 15, rest: 60),
        _E('Cable_Crossover', 3, reps: 15, rest: 60),
      ]),
      StarterWorkout('Back', [
        _E('Barbell_Deadlift', 3, reps: 5, rest: 180, warmups: 1),
        _E('Pullups', 4, reps: 8, rest: 120),
        _E('T-Bar_Row_with_Handle', 4, reps: 10),
        _E('One-Arm_Dumbbell_Row', 3, reps: 12),
        _E('Straight-Arm_Pulldown', 3, reps: 15, rest: 60),
      ]),
      StarterWorkout('Legs', [
        _E('Barbell_Squat', 4, reps: 6, rest: 180, warmups: 1),
        _E('Hack_Squat', 3, reps: 10, rest: 120),
        _E('Romanian_Deadlift', 3, reps: 10, rest: 120),
        _E('Leg_Extensions', 3, reps: 15, rest: 60),
        _E('Lying_Leg_Curls', 3, reps: 12, rest: 60),
        _E('Seated_Calf_Raise', 4, reps: 15, rest: 60),
      ]),
      StarterWorkout('Shoulders', [
        _E('Standing_Military_Press', 4, reps: 6, rest: 150, warmups: 1),
        _E('Dumbbell_Shoulder_Press', 3, reps: 10),
        _E('Side_Lateral_Raise', 4, reps: 15, rest: 45),
        _E('Reverse_Machine_Flyes', 3, reps: 15, rest: 60),
        _E('Dumbbell_Shrug', 3, reps: 12, rest: 60),
      ]),
      StarterWorkout('Arms & Abs', [
        _E('Close-Grip_Barbell_Bench_Press', 3, reps: 8, rest: 120),
        _E('Barbell_Curl', 3, reps: 10, rest: 75),
        _E('EZ-Bar_Skullcrusher', 3, reps: 10, rest: 75),
        _E('Incline_Dumbbell_Curl', 3, reps: 12, rest: 60),
        _E('Triceps_Pushdown_-_Rope_Attachment', 3, reps: 12, rest: 60),
        _E('Hanging_Leg_Raise', 3, reps: 12, rest: 60),
        _E('Cable_Crunch', 3, reps: 15, rest: 60),
      ]),
    ],
  ),
];
