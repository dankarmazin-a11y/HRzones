import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

/// One exercise slot in a template (editable, in memory).
/// A planned set in a template (values are optional targets).
class TemplateSet {
  const TemplateSet({this.type = SetType.normal, this.weightKg, this.reps, this.durationS, this.side, this.distanceM});

  final SetType type;
  final double? weightKg;
  final int? reps;
  final int? durationS;

  /// Target metres (distance sets).
  final double? distanceM;

  /// Left / right for one-sided exercises.
  final Side? side;

  Map<String, Object?> toJson() => {
    't': type.index,
    if (weightKg != null) 'w': weightKg,
    if (reps != null) 'r': reps,
    if (durationS != null) 's': durationS,
    if (side != null) 'd': side!.index,
    if (distanceM != null) 'm': distanceM,
  };

  factory TemplateSet.fromJson(Map<String, dynamic> j) => TemplateSet(
    type: SetType.values[(j['t'] as int? ?? 1).clamp(0, SetType.values.length - 1)],
    weightKg: (j['w'] as num?)?.toDouble(),
    reps: j['r'] as int?,
    durationS: j['s'] as int?,
    side: j['d'] is int ? Side.values[(j['d'] as int).clamp(0, 1)] : null,
    distanceM: (j['m'] as num?)?.toDouble(),
  );

  static String? encode(List<TemplateSet> sets) => sets.isEmpty ? null : jsonEncode([for (final s in sets) s.toJson()]);

  static List<TemplateSet> decode(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return [for (final j in (jsonDecode(json) as List).cast<Map<String, dynamic>>()) TemplateSet.fromJson(j)];
    } catch (_) {
      return [];
    }
  }
}

class TemplateSlot {
  TemplateSlot({
    required this.exerciseId,
    this.targetSets = 3,
    this.restSeconds = 90,
    this.supersetGroup,
    List<String>? subExerciseIds,
    List<TemplateSet>? sets,
  }) : subExerciseIds = subExerciseIds ?? [],
       sets = sets ?? [];

  /// Planned sets with target values (empty for old templates: use
  /// [targetSets] empty sets).
  final List<TemplateSet> sets;

  String exerciseId;
  int targetSets;
  int restSeconds;
  int? supersetGroup;

  /// For a "Stretching" session slot: the stretches in order.
  final List<String> subExerciseIds;
}

class TemplateWithSlots {
  TemplateWithSlots({required this.template, required this.slots});

  final Template template;
  final List<TemplateSlot> slots;
}

class TemplateRepository {
  TemplateRepository(this.db);

  final AppDatabase db;

  Stream<List<TemplateWithSlots>> watchAll() {
    final q = db.select(db.templates)..orderBy([(t) => OrderingTerm.asc(t.position), (t) => OrderingTerm.asc(t.name)]);
    return q.watch().asyncMap((templates) async {
      final slots = await (db.select(db.templateExercises)..orderBy([(e) => OrderingTerm.asc(e.position)])).get();
      return [
        for (final t in templates)
          TemplateWithSlots(
            template: t,
            slots: [
              for (final s in slots.where((s) => s.templateId == t.id))
                TemplateSlot(
                  exerciseId: s.exerciseId,
                  targetSets: s.targetSets,
                  restSeconds: s.restSeconds,
                  supersetGroup: s.supersetGroup,
                  subExerciseIds: (s.subExerciseIds ?? '').split(',').where((x) => x.isNotEmpty).toList(),
                  sets: TemplateSet.decode(s.setsJson),
                ),
            ],
          ),
      ];
    });
  }

  /// Creates ([id] null) or replaces a template and its exercise list.
  Future<String> save({
    String? id,
    required String name,
    String? folder,
    String? hrPresetId,
    required List<TemplateSlot> slots,
  }) {
    return db.transaction(() async {
      final templateId = id ?? newId();
      final count = await db.templates.count().getSingle();
      await db
          .into(db.templates)
          .insertOnConflictUpdate(
            TemplatesCompanion.insert(
              id: Value(templateId),
              name: name,
              folder: Value(folder),
              hrPresetId: Value(hrPresetId),
              updatedAt: Value(DateTime.now()),
              position: id == null ? Value(count) : const Value.absent(),
            ),
          );
      await (db.delete(db.templateExercises)..where((e) => e.templateId.equals(templateId))).go();
      await db.batch((b) {
        b.insertAll(db.templateExercises, [
          for (final (i, s) in slots.indexed)
            TemplateExercisesCompanion.insert(
              templateId: templateId,
              exerciseId: s.exerciseId,
              position: i,
              targetSets: Value(s.targetSets),
              restSeconds: Value(s.restSeconds),
              supersetGroup: Value(s.supersetGroup),
              subExerciseIds: Value(s.subExerciseIds.isEmpty ? null : s.subExerciseIds.join(',')),
              setsJson: Value(TemplateSet.encode(s.sets)),
            ),
        ]);
      });
      return templateId;
    });
  }

  Future<TemplateWithSlots?> byId(String id) async =>
      (await watchAll().first).where((t) => t.template.id == id).firstOrNull;

  /// Folder names in use, A–Z.
  Future<List<String>> folders() async {
    final rows = await db.select(db.templates).get();
    return {
      for (final t in rows)
        if ((t.folder ?? '').isNotEmpty) t.folder!,
    }.toList()..sort();
  }

  /// Saves a copy named "Name (copy)" in the same folder.
  Future<String> duplicate(TemplateWithSlots t) => save(
    name: '${t.template.name} (copy)',
    folder: t.template.folder,
    hrPresetId: t.template.hrPresetId,
    slots: [
      for (final s in t.slots)
        TemplateSlot(
          exerciseId: s.exerciseId,
          targetSets: s.targetSets,
          restSeconds: s.restSeconds,
          supersetGroup: s.supersetGroup,
          subExerciseIds: [...s.subExerciseIds],
          sets: [...s.sets],
        ),
    ],
  );

  Future<void> delete(String id) => (db.delete(db.templates)..where((t) => t.id.equals(id))).go();
}
