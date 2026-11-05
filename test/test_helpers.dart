import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/beep/beeper.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/hr/hr_monitor.dart';
import 'package:hrzones/hr/simulated_hr_source.dart';
import 'package:hrzones/ui/exercises/exercise_avatar.dart';
import 'package:hrzones/ui/run/run_map.dart';

/// Small exercise list instead of the full 873-entry asset.
final testExercisesJson = jsonEncode([
  {
    'id': 'Barbell_Bench_Press',
    'name': 'Barbell Bench Press',
    'category': 'strength',
    'equipment': 'barbell',
    'primaryMuscles': ['chest'],
    'secondaryMuscles': ['triceps', 'shoulders'],
    'instructions': ['Lie down.', 'Press.'],
    'images': ['Barbell_Bench_Press/0.jpg'],
    'mechanic': 'compound',
  },
  {
    'id': 'Pullups',
    'name': 'Pullups',
    'category': 'strength',
    'equipment': 'body only',
    'primaryMuscles': ['lats'],
    'secondaryMuscles': ['biceps'],
    'instructions': [],
    'images': [],
    'mechanic': 'compound',
  },
  {
    'id': 'hz_stretching',
    'name': 'Stretching',
    'category': 'stretching',
    'equipment': 'body only',
    'primaryMuscles': ['full body'],
    'secondaryMuscles': [],
    'instructions': [],
    'images': [],
    'mechanic': null,
  },
  {
    'id': 'Hamstring_Stretch',
    'name': 'Standing Hamstring Stretch',
    'category': 'stretching',
    'equipment': 'body only',
    'primaryMuscles': ['hamstrings'],
    'secondaryMuscles': [],
    'instructions': [],
    'images': [],
    'mechanic': null,
    'popularity': 1000,
  },
  {
    'id': 'Plank',
    'name': 'Plank',
    'category': 'stretching',
    'equipment': 'body only',
    'primaryMuscles': ['abdominals'],
    'secondaryMuscles': [],
    'instructions': [],
    'images': [],
    'mechanic': null,
  },
]);

AppDatabase memoryDb() {
  ExerciseAvatar.loadImages = false; // no network in tests
  RunMap.loadTiles = false; // no map tiles from the network in tests
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

Future<AppServices> testServices({SilentBeeper? beeper, SimulatedHrSource? source}) => AppServices.open(
  loadExercises: () async => testExercisesJson,
  db: memoryDb(),
  hr: HrMonitor(beeper: beeper ?? SilentBeeper(), source: source),
);
