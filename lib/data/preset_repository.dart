import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

class HrPresetRepository {
  HrPresetRepository(this.db);

  final AppDatabase db;

  Stream<List<HrPreset>> watchAll() => (db.select(db.hrPresets)..orderBy([(p) => OrderingTerm.asc(p.minBpm)])).watch();

  Future<List<HrPreset>> all() => (db.select(db.hrPresets)..orderBy([(p) => OrderingTerm.asc(p.minBpm)])).get();

  Future<HrPreset?> byId(String? id) async =>
      id == null ? null : (db.select(db.hrPresets)..where((p) => p.id.equals(id))).getSingleOrNull();

  /// Presets usable for [use] (presets for "any" always count).
  Future<List<HrPreset>> forUse(PresetUse use) async => [
    for (final p in await all())
      if (p.use == PresetUse.any || p.use == use) p,
  ];

  Future<String> save({
    String? id,
    required String name,
    required int min,
    required int max,
    required PresetUse use,
  }) async {
    final presetId = id ?? newId();
    await db
        .into(db.hrPresets)
        .insertOnConflictUpdate(
          HrPresetsCompanion.insert(
            id: Value(presetId),
            name: name,
            minBpm: min,
            maxBpm: max,
            use: Value(use),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return presetId;
  }

  Future<void> delete(String id) => (db.delete(db.hrPresets)..where((p) => p.id.equals(id))).go();
}

/// One step of an interval timer.
class IntervalSegment {
  const IntervalSegment({required this.label, required this.seconds, this.work = true});

  final String label;
  final int seconds;

  /// Work (high beep) or rest (low beep).
  final bool work;

  Map<String, Object> toJson() => {'l': label, 's': seconds, 'w': work};

  factory IntervalSegment.fromJson(Map<String, dynamic> j) =>
      IntervalSegment(label: j['l'] as String? ?? '', seconds: j['s'] as int? ?? 30, work: j['w'] as bool? ?? true);

  IntervalSegment copyWith({String? label, int? seconds, bool? work}) =>
      IntervalSegment(label: label ?? this.label, seconds: seconds ?? this.seconds, work: work ?? this.work);
}

List<IntervalSegment> decodeSegments(String json) {
  try {
    return [for (final j in (jsonDecode(json) as List).cast<Map<String, dynamic>>()) IntervalSegment.fromJson(j)];
  } catch (_) {
    return [];
  }
}

String encodeSegments(List<IntervalSegment> s) => jsonEncode([for (final x in s) x.toJson()]);

/// Built-in timers added on first launch (editable / deletable).
final defaultIntervalPresets = <(String, int, List<IntervalSegment>)>[
  (
    'Tabata',
    8,
    const [IntervalSegment(label: 'Work', seconds: 20), IntervalSegment(label: 'Rest', seconds: 10, work: false)],
  ),
  ('EMOM 10 min', 10, const [IntervalSegment(label: 'Every minute', seconds: 60)]),
  (
    'Run intervals 6 × 90 s',
    6,
    const [IntervalSegment(label: 'Fast', seconds: 90), IntervalSegment(label: 'Easy jog', seconds: 90, work: false)],
  ),
  (
    'Plank 3 × 45 s',
    3,
    const [IntervalSegment(label: 'Plank', seconds: 45), IntervalSegment(label: 'Rest', seconds: 15, work: false)],
  ),
];

class IntervalPresetRepository {
  IntervalPresetRepository(this.db);

  final AppDatabase db;

  Stream<List<IntervalPreset>> watchAll() => (db.select(
    db.intervalPresets,
  )..orderBy([(p) => OrderingTerm.asc(p.position), (p) => OrderingTerm.asc(p.name)])).watch();

  /// Adds the built-in timers once.
  Future<void> seedDefaults() async {
    if (await db.getSettingRaw('intervalSeeded') == '1') return;
    for (final (i, (name, rounds, segments)) in defaultIntervalPresets.indexed) {
      await save(name: name, rounds: rounds, segments: segments, position: i);
    }
    await db.setSettingRaw('intervalSeeded', '1');
  }

  Future<String> save({
    String? id,
    required String name,
    required int rounds,
    required List<IntervalSegment> segments,
    int? position,
  }) async {
    final presetId = id ?? newId();
    await db
        .into(db.intervalPresets)
        .insertOnConflictUpdate(
          IntervalPresetsCompanion.insert(
            id: Value(presetId),
            name: name,
            rounds: Value(rounds),
            segmentsJson: encodeSegments(segments),
            position: position == null ? const Value.absent() : Value(position),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return presetId;
  }

  Future<void> delete(String id) => (db.delete(db.intervalPresets)..where((p) => p.id.equals(id))).go();
}

extension _RawSettings on AppDatabase {
  Future<String?> getSettingRaw(String key) async =>
      (await (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setSettingRaw(String key, String value) =>
      into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
