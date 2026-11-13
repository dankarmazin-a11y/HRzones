import 'package:drift/drift.dart';

import 'database.dart';
import '../units/units.dart';

/// A kind of body measurement.
class MeasurementKind {
  const MeasurementKind(this.key, this.label, this.unit, {this.lowerIsBetter = false});

  final String key;
  final String label;
  final String unit;

  /// For "progress" colouring (e.g. waist, body fat).
  final bool lowerIsBetter;
}

const measurementKinds = [
  MeasurementKind('weight', 'Body weight', 'kg'),
  MeasurementKind('bodyFat', 'Body fat', '%', lowerIsBetter: true),
  MeasurementKind('muscleMass', 'Muscle mass', 'kg'),
  MeasurementKind('neck', 'Neck', 'cm'),
  MeasurementKind('shoulders', 'Shoulders', 'cm'),
  MeasurementKind('chest', 'Chest', 'cm'),
  MeasurementKind('waist', 'Waist', 'cm', lowerIsBetter: true),
  MeasurementKind('hips', 'Hips', 'cm'),
  MeasurementKind('bicepL', 'Left biceps', 'cm'),
  MeasurementKind('bicepR', 'Right biceps', 'cm'),
  MeasurementKind('forearmL', 'Left forearm', 'cm'),
  MeasurementKind('forearmR', 'Right forearm', 'cm'),
  MeasurementKind('thighL', 'Left thigh', 'cm'),
  MeasurementKind('thighR', 'Right thigh', 'cm'),
  MeasurementKind('calfL', 'Left calf', 'cm'),
  MeasurementKind('calfR', 'Right calf', 'cm'),
  MeasurementKind('restingHr', 'Resting heart rate', 'bpm', lowerIsBetter: true),
];

/// Body weight / lengths shown in the chosen units (stored kg / cm).
extension MeasurementUnits on MeasurementKind {
  /// "kg"/"lb", "cm"/"in", or the kind's own unit ("%", "bpm").
  String get shownUnit => unit == 'kg' ? Units.w : (unit == 'cm' ? Units.len : unit);

  double toShown(double v) => unit == 'kg' ? Units.toW(v) : (unit == 'cm' ? Units.toLen(v) : v);

  double fromShown(double v) => unit == 'kg' ? Units.fromW(v) : (unit == 'cm' ? Units.fromLen(v) : v);
}

MeasurementKind kindOf(String key) =>
    measurementKinds.firstWhere((k) => k.key == key, orElse: () => MeasurementKind(key, key, ''));

class BodyRepository {
  BodyRepository(this.db);

  final AppDatabase db;

  Future<void> add(String kind, double value, {DateTime? date}) => db
      .into(db.bodyMeasurements)
      .insert(BodyMeasurementsCompanion.insert(kind: kind, value: value, date: date ?? DateTime.now()));

  Future<void> delete(String id) => (db.delete(db.bodyMeasurements)..where((m) => m.id.equals(id))).go();

  /// All entries, newest first (per kind via [byKind]).
  Stream<List<BodyMeasurement>> watchAll() =>
      (db.select(db.bodyMeasurements)..orderBy([(m) => OrderingTerm.desc(m.date)])).watch();

  Future<List<BodyMeasurement>> history(String kind) =>
      (db.select(db.bodyMeasurements)
            ..where((m) => m.kind.equals(kind))
            ..orderBy([(m) => OrderingTerm.desc(m.date)]))
          .get();

  Future<double?> latest(String kind) async => (await history(kind)).firstOrNull?.value;
}

/// Newest first per kind.
Map<String, List<BodyMeasurement>> byKind(List<BodyMeasurement> all) {
  final out = <String, List<BodyMeasurement>>{};
  for (final m in all) {
    out.putIfAbsent(m.kind, () => []).add(m);
  }
  return out;
}
