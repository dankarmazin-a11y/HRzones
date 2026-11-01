import 'package:drift/drift.dart';

import 'database.dart';

/// One exercise slot in a template (editable, in memory).
class TemplateSlot {
  TemplateSlot({required this.exerciseId, this.targetSets = 3, this.restSeconds = 90, this.supersetGroup});

  String exerciseId;
  int targetSets;
  int restSeconds;
  int? supersetGroup;
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
                ),
            ],
          ),
      ];
    });
  }

  /// Creates ([id] null) or replaces a template and its exercise list.
  Future<String> save({String? id, required String name, String? folder, required List<TemplateSlot> slots}) {
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
            ),
        ]);
      });
      return templateId;
    });
  }

  Future<void> delete(String id) => (db.delete(db.templates)..where((t) => t.id.equals(id))).go();
}
