import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

/// Muscle groups used by free-exercise-db (and our filters).
const muscleGroups = [
  'chest',
  'shoulders',
  'triceps',
  'biceps',
  'forearms',
  'lats',
  'middle back',
  'lower back',
  'traps',
  'neck',
  'abdominals',
  'quadriceps',
  'hamstrings',
  'glutes',
  'calves',
  'adductors',
  'abductors',
];

const equipmentTypes = [
  'barbell',
  'dumbbell',
  'cable',
  'machine',
  'kettlebells',
  'body only',
  'bands',
  'e-z curl bar',
  'medicine ball',
  'exercise ball',
  'foam roll',
  'other',
];

const exerciseImageBase = 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/';

/// Bump when assets/exercises.json changes so existing installs re-seed.
const exerciseSeedVersion = '1';

String titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class ExerciseRepository {
  ExerciseRepository(this.db);

  final AppDatabase db;
  List<Exercise>? _cache;
  Map<String, Exercise> _byId = {};

  /// Inserts/updates the bundled exercise list on first launch or when the
  /// seed version changes. [loadJson] returns the contents of exercises.json.
  Future<void> seedIfNeeded(Future<String> Function() loadJson) async {
    final current = await db.getSetting('exerciseSeedVersion');
    if (current == exerciseSeedVersion) return;
    final list = (jsonDecode(await loadJson()) as List).cast<Map<String, dynamic>>();
    await db.batch((b) {
      b.insertAllOnConflictUpdate(db.exercises, [for (final e in list) exerciseFromSeed(e)]);
    });
    await db.setSetting('exerciseSeedVersion', exerciseSeedVersion);
    _cache = null;
  }

  static ExercisesCompanion exerciseFromSeed(Map<String, dynamic> e) {
    final category = (e['category'] as String?) ?? 'strength';
    final equipment = e['equipment'] as String?;
    final images = (e['images'] as List?)?.cast<String>() ?? const [];
    final tracking = switch (category) {
      'stretching' || 'cardio' => TrackingType.duration,
      _ when equipment == 'body only' || equipment == null => TrackingType.bodyweightReps,
      _ => TrackingType.weightReps,
    };
    return ExercisesCompanion.insert(
      id: Value(e['id'] as String),
      name: e['name'] as String,
      primaryMuscle: ((e['primaryMuscles'] as List?)?.firstOrNull as String?) ?? 'other',
      secondaryMuscles: Value(((e['secondaryMuscles'] as List?) ?? const []).join(',')),
      equipment: Value(equipment),
      category: Value(category),
      trackingType: tracking,
      instructions: Value(((e['instructions'] as List?) ?? const []).join('\n')),
      imagePath: Value(images.firstOrNull),
      defaultRestSeconds: Value(e['mechanic'] == 'compound' ? 120 : 90),
    );
  }

  Future<List<Exercise>> all() async {
    final cached = _cache;
    if (cached != null) return cached;
    final rows = await (db.select(db.exercises)..orderBy([(e) => OrderingTerm.asc(e.name)])).get();
    _cache = rows;
    _byId = {for (final e in rows) e.id: e};
    return rows;
  }

  Future<Exercise?> byId(String id) async {
    if (_cache == null) await all();
    return _byId[id];
  }

  /// Search by name (all words must match), muscle and equipment.
  Future<List<Exercise>> search({String query = '', String? muscle, String? equipment}) async {
    final words = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return [
      for (final e in await all())
        if ((muscle == null || e.primaryMuscle == muscle || e.secondaryMuscles.split(',').contains(muscle)) &&
            (equipment == null || e.equipment == equipment) &&
            words.every(e.name.toLowerCase().contains))
          e,
    ]..sort((a, b) {
      // Primary-muscle matches first when filtering by muscle.
      if (muscle != null) {
        final pa = a.primaryMuscle == muscle ? 0 : 1, pb = b.primaryMuscle == muscle ? 0 : 1;
        if (pa != pb) return pa - pb;
      }
      return a.name.compareTo(b.name);
    });
  }

  Future<Exercise> createCustom({
    required String name,
    required String primaryMuscle,
    String? equipment,
    TrackingType trackingType = TrackingType.weightReps,
  }) async {
    final row = await db
        .into(db.exercises)
        .insertReturning(
          ExercisesCompanion.insert(
            name: name,
            primaryMuscle: primaryMuscle,
            equipment: Value(equipment),
            trackingType: trackingType,
            isCustom: const Value(true),
            category: const Value('strength'),
          ),
        );
    _cache = null;
    return row;
  }
}

extension SettingsAccess on AppDatabase {
  Future<String?> getSetting(String key) async =>
      (await (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
