import '../data/database.dart';
import '../data/exercise_repository.dart';
import '../data/workout_repository.dart';
import 'active_workout.dart';
import 'interval_runner.dart';

/// One exercise in a follow-along workout.
class AbMove {
  const AbMove(this.exerciseId, this.name, {this.seconds});

  /// free-exercise-db id (picture, history).
  final String exerciseId;

  /// Name shown and spoken ("Side plank – left").
  final String name;

  /// Overrides the workout's work time.
  final int? seconds;
}

/// A ready-made follow-along workout (like the ab videos): every move for a
/// set time, a short rest, the next one – optionally several rounds.
class AbWorkout {
  const AbWorkout({
    required this.id,
    required this.name,
    required this.level,
    required this.description,
    required this.workSeconds,
    required this.restSeconds,
    required this.moves,
    this.rounds = 1,
    this.roundRestSeconds = 0,
  });

  final String id;
  final String name;

  /// "Beginner", "Intermediate", "Advanced".
  final String level;
  final String description;
  final int workSeconds;
  final int restSeconds;
  final int rounds;

  /// Rest between rounds (instead of the normal rest).
  final int roundRestSeconds;
  final List<AbMove> moves;

  /// The timer steps (work = a move, rest = "Rest") and, for each step, the
  /// move it belongs to (null for rests). No rest at the very end.
  ({List<IntervalStep> steps, List<AbMove?> moves}) plan() {
    final steps = <IntervalStep>[];
    final which = <AbMove?>[];
    for (var r = 1; r <= rounds; r++) {
      for (var i = 0; i < moves.length; i++) {
        final m = moves[i];
        steps.add(IntervalStep(label: m.name, seconds: m.seconds ?? workSeconds, work: true, round: r));
        which.add(m);
        final lastOfRound = i == moves.length - 1;
        final rest = lastOfRound ? (r < rounds ? roundRestSeconds : 0) : restSeconds;
        if (rest > 0) {
          steps.add(IntervalStep(label: lastOfRound ? 'Round break' : 'Rest', seconds: rest, work: false, round: r));
          which.add(null);
        }
      }
    }
    return (steps: steps, moves: which);
  }

  int get totalSeconds => plan().steps.fold(0, (s, x) => s + x.seconds);

  /// Minutes, rounded ("10 min").
  int get minutes => (totalSeconds / 60).round();
}

const _left = 'Side plank – left', _right = 'Side plank – right';

/// Bodyweight only, so they work anywhere (home, gym, outdoors).
const abWorkouts = <AbWorkout>[
  AbWorkout(
    id: 'abs5',
    name: 'Quick abs',
    level: 'Beginner',
    description: '8 moves, 30 s each, 10 s rest',
    workSeconds: 30,
    restSeconds: 10,
    moves: [
      AbMove('Crunches', 'Crunch'),
      AbMove('Air_Bike', 'Bicycle crunch'),
      AbMove('Reverse_Crunch', 'Reverse crunch'),
      AbMove('Plank', 'Plank'),
      AbMove('Alternate_Heel_Touchers', 'Heel touches'),
      AbMove('Flutter_Kicks', 'Flutter kicks'),
      AbMove('Dead_Bug', 'Dead bug'),
      AbMove('Mountain_Climbers', 'Mountain climbers'),
    ],
  ),
  AbWorkout(
    id: 'abs10',
    name: '10-minute abs',
    level: 'Beginner',
    description: '10 moves, 40 s each, 20 s rest',
    workSeconds: 40,
    restSeconds: 20,
    moves: [
      AbMove('Crunches', 'Crunch'),
      AbMove('Air_Bike', 'Bicycle crunch'),
      AbMove('Reverse_Crunch', 'Reverse crunch'),
      AbMove('Plank', 'Plank'),
      AbMove('Russian_Twist', 'Russian twist'),
      AbMove('Flutter_Kicks', 'Flutter kicks'),
      AbMove('Side_Bridge', _left),
      AbMove('Side_Bridge', _right),
      AbMove('Mountain_Climbers', 'Mountain climbers'),
      AbMove('Dead_Bug', 'Dead bug'),
    ],
  ),
  AbWorkout(
    id: 'core15',
    name: 'Core burn',
    level: 'Intermediate',
    description: '2 rounds of 7 moves, 45 s on, 15 s rest',
    workSeconds: 45,
    restSeconds: 15,
    rounds: 2,
    roundRestSeconds: 45,
    moves: [
      AbMove('Jackknife_Sit-Up', 'Jackknife sit-up'),
      AbMove('Russian_Twist', 'Russian twist'),
      AbMove('Scissor_Kick', 'Scissor kicks'),
      AbMove('Plank', 'Plank'),
      AbMove('Mountain_Climbers', 'Mountain climbers'),
      AbMove('Oblique_Crunches_-_On_The_Floor', 'Oblique crunch'),
      AbMove('Leg_Pull-In', 'Leg pull-in'),
    ],
  ),
  AbWorkout(
    id: 'abs20',
    name: 'Six-pack 20',
    level: 'Advanced',
    description: '2 rounds of 10 moves, 50 s on, 10 s rest',
    workSeconds: 50,
    restSeconds: 10,
    rounds: 2,
    roundRestSeconds: 60,
    moves: [
      AbMove('Sit-Up', 'Sit-up'),
      AbMove('Air_Bike', 'Bicycle crunch'),
      AbMove('Tuck_Crunch', 'Tuck crunch'),
      AbMove('Flutter_Kicks', 'Flutter kicks'),
      AbMove('Side_Bridge', _left),
      AbMove('Side_Bridge', _right),
      AbMove('Spider_Crawl', 'Spider crawl'),
      AbMove('Frog_Sit-Ups', 'Frog sit-up'),
      AbMove('Elbow_to_Knee', 'Elbow to knee'),
      AbMove('Plank', 'Plank', seconds: 60),
    ],
  ),
];

/// Saves a finished follow-along workout to the history (it counts for the
/// streak and "this week"): one exercise per move, one timed set per time it
/// was done.
Future<void> saveAbWorkout(
  AbWorkout workout,
  ExerciseRepository exercises,
  WorkoutRepository workouts, {
  required DateTime startedAt,
  required DateTime endedAt,
}) async {
  final w = ActiveWorkout(name: workout.name, startedAt: startedAt);
  final byId = <String, LoggedExercise>{};
  var t = startedAt;
  final plan = workout.plan();
  for (var i = 0; i < plan.steps.length; i++) {
    final step = plan.steps[i];
    t = t.add(Duration(seconds: step.seconds));
    final move = plan.moves[i];
    if (move == null) continue;
    var e = byId[move.exerciseId];
    if (e == null) {
      final ex = await exercises.byId(move.exerciseId);
      if (ex == null) continue;
      e = byId[move.exerciseId] = LoggedExercise(exercise: ex, restSeconds: workout.restSeconds);
      w.exercises.add(e);
    }
    e.sets.add(LoggedSet(durationS: step.seconds)..completedAt = t);
  }
  await workouts.save(w, endedAt: endedAt);
}

/// The picture to show for a move: free-exercise-db has a start (0) and an
/// end (1) position; flipping between them looks like a little video.
String? moveImage(Exercise? e, {required bool second}) {
  final p = e?.imagePath;
  if (p == null) return null;
  return second ? p.replaceFirst(RegExp(r'0\.jpg$'), '1.jpg') : p;
}
