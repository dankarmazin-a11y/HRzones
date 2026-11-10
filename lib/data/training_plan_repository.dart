import 'package:drift/drift.dart';

import '../run/training_plan.dart';
import '../workout/streak.dart';
import 'database.dart';

/// The owner's weekly running plans; one is active (shown on the Run tab and
/// Home).
class TrainingPlanRepository {
  TrainingPlanRepository(this.db);

  final AppDatabase db;

  Stream<TrainingPlan?> watchActive() =>
      (db.select(db.trainingPlans)
            ..where((p) => p.active.equals(true))
            ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
            ..limit(1))
          .watchSingleOrNull();

  Future<TrainingPlan?> active() => watchActive().first;

  /// Saves a plan and makes it the active one.
  Future<String> save({
    String? id,
    required String name,
    required DateTime start,
    required int weeks,
    required List<PlanDay> days,
  }) async {
    final planId = id ?? newId();
    await db.transaction(() async {
      await (db.update(
        db.trainingPlans,
      )..where((p) => p.id.equals(planId).not())).write(const TrainingPlansCompanion(active: Value(false)));
      await db
          .into(db.trainingPlans)
          .insertOnConflictUpdate(
            TrainingPlansCompanion.insert(
              id: Value(planId),
              name: name,
              startDate: weekStart(start),
              weeks: weeks,
              daysJson: Value(
                encodePlanDays([
                  for (final d in days)
                    if (d.week < weeks) d,
                ]),
              ),
              active: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
          );
    });
    return planId;
  }

  Future<void> delete(String id) => (db.delete(db.trainingPlans)..where((p) => p.id.equals(id))).go();
}
