import 'dart:convert';

import 'package:drift/drift.dart';

import '../workout/training_level.dart';
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
const exerciseSeedVersion = '5';

/// How many popular exercises are listed before the A–Z list.
const popularCount = 5;

/// Friendlier labels for database terms ("abductors" and "adductors" look
/// like a duplicate to most people).
const _labels = {
  'arms': 'Arms',
  'legs': 'Legs',
  'core': 'Core',
  'back': 'Back',
  'abductors': 'Outer thighs',
  'adductors': 'Inner thighs',
  'body only': 'Bodyweight',
  'e-z curl bar': 'EZ bar',
  'kettlebells': 'Kettlebell',
  'lats': 'Lats (upper back)',
};

/// Display label for a muscle / equipment / category value.
String titleCase(String s) => _labels[s] ?? (s.isEmpty ? s : s[0].toUpperCase() + s.substring(1));

/// Search result: the most popular matches first, then the rest A–Z.
class ExerciseSearchResult {
  const ExerciseSearchResult({required this.popular, required this.others});

  final List<Exercise> popular;
  final List<Exercise> others;

  int get length => popular.length + others.length;
  List<Exercise> get all => [...popular, ...others];
}

class ExerciseRepository {
  ExerciseRepository(this.db);

  final AppDatabase db;
  List<Exercise>? _cache;
  Map<String, Exercise> _byId = {};

  /// Inserts/updates the bundled exercise list on first launch or when the
  /// seed version changes. [loadJson] returns the contents of exercises.json.
  /// The user's own choices (tracking type, rest) are kept on update.
  Future<void> seedIfNeeded(Future<String> Function() loadJson) async {
    final current = await db.getSetting('exerciseSeedVersion');
    if (current == exerciseSeedVersion) return;
    final list = (jsonDecode(await loadJson()) as List).cast<Map<String, dynamic>>();
    await db.batch((b) {
      b.insertAll(
        db.exercises,
        [for (final e in list) exerciseFromSeed(e)],
        onConflict: DoUpdate<$ExercisesTable, Exercise>.withExcluded(
          (old, excluded) => ExercisesCompanion.custom(
            name: excluded.name,
            primaryMuscle: excluded.primaryMuscle,
            secondaryMuscles: excluded.secondaryMuscles,
            equipment: excluded.equipment,
            category: excluded.category,
            instructions: excluded.instructions,
            imagePath: excluded.imagePath,
            popularity: excluded.popularity,
            hidden: excluded.hidden,
            level: excluded.level,
          ),
        ),
      );
    });
    await db.setSetting('exerciseSeedVersion', exerciseSeedVersion);
    _cache = null;
  }

  static ExercisesCompanion exerciseFromSeed(Map<String, dynamic> e) {
    final category = (e['category'] as String?) ?? 'strength';
    final equipment = e['equipment'] as String?;
    final images = (e['images'] as List?)?.cast<String>() ?? const [];
    final tracking = switch (category) {
      _ when e['tracking'] == 'duration' => TrackingType.duration,
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
      popularity: Value(e['popularity'] as int?),
      hidden: Value(e['hidden'] == true),
      level: Value(e['level'] as String?),
    );
  }

  /// Forget the in-memory list (after direct database changes).
  void clearCache() => _cache = null;

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

  /// Search by name (all words must match), muscle, equipment and type.
  /// The [popularCount] most popular matches come first, then the rest A–Z.
  /// Search by name (all words must match), muscle (a detailed muscle or a
  /// simple group like "back"), equipment, type and [levels] (exercise levels
  /// to include; popular exercises always count). The [popularCount] most
  /// popular matches come first, then the rest A–Z.
  Future<ExerciseSearchResult> search({
    String query = '',
    String? muscle,
    String? equipment,
    ExerciseGroup? group,
    Set<String>? levels,
    Set<String>? allowedEquipment,
  }) async {
    final words = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final muscles = muscle == null ? null : musclesOf(muscle);
    bool primaryMatch(Exercise e) => muscles == null || muscles.contains(e.primaryMuscle);
    final matches = [
      for (final e in await all())
        if ((muscles == null || primaryMatch(e) || e.secondaryMuscles.split(',').any(muscles.contains)) &&
            (equipment == null || e.equipment == equipment) &&
            // Where you train: custom exercises and ones without equipment always count.
            (allowedEquipment == null || e.isCustom || e.equipment == null || allowedEquipment.contains(e.equipment)) &&
            (group == null || e.group == group) &&
            (levels == null || e.isCustom || e.popularity != null || levels.contains(e.level ?? 'beginner')) &&
            !e.isStretchSession &&
            !e.hidden &&
            words.every(e.name.toLowerCase().contains))
          e,
    ];
    // Popular = ranked exercises whose *primary* muscle matches the filter.
    final ranked = matches.where((e) => e.popularity != null && primaryMatch(e)).toList()
      ..sort((a, b) => a.popularity!.compareTo(b.popularity!));
    final popular = ranked.take(popularCount).toList();
    final others = matches.where((e) => !popular.contains(e)).toList()..sort((a, b) => a.name.compareTo(b.name));
    return ExerciseSearchResult(popular: popular, others: others);
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

  /// Changes how an exercise is logged (weight × reps, reps, time).
  Future<Exercise> setTrackingType(String id, TrackingType type) async {
    await (db.update(db.exercises)..where((e) => e.id.equals(id))).write(
      ExercisesCompanion(trackingType: Value(type), updatedAt: Value(DateTime.now())),
    );
    _cache = null;
    return (await byId(id))!;
  }
}

extension SettingsAccess on AppDatabase {
  Future<String?> getSetting(String key) async =>
      (await (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
