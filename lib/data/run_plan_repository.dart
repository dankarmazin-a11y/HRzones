import 'package:drift/drift.dart';

import '../run/run_plan.dart';
import 'database.dart';
import 'exercise_repository.dart';

class RunPlanRepository {
  RunPlanRepository(this.db);

  final AppDatabase db;

  Stream<List<RunPlan>> watchAll() =>
      (db.select(db.runPlans)..orderBy([(p) => OrderingTerm.asc(p.position), (p) => OrderingTerm.asc(p.name)])).watch();

  Future<RunPlan?> byId(String? id) async =>
      id == null ? null : (db.select(db.runPlans)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<String> save({String? id, required String name, required PlanSpec spec}) async {
    final planId = id ?? newId();
    final position = id == null ? (await db.select(db.runPlans).get()).length : null;
    await db
        .into(db.runPlans)
        .insertOnConflictUpdate(
          RunPlansCompanion.insert(
            id: Value(planId),
            name: name,
            specJson: spec.toJson(),
            position: position == null ? const Value.absent() : Value(position),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return planId;
  }

  Future<void> delete(String id) => (db.delete(db.runPlans)..where((p) => p.id.equals(id))).go();

  /// The built-in examples, added once (setting `runPlansSeeded`).
  Future<void> seedDefaults() async {
    if (await db.getSetting('runPlansSeeded') == '1') return;
    for (final (name, spec) in defaultPlans) {
      await save(name: name, spec: spec);
    }
    await db.setSetting('runPlansSeeded', '1');
  }
}
