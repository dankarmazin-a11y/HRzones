import 'package:flutter/foundation.dart';

/// Display units (owner, 2026-11-13: Settings › Units). Everything is stored
/// in kg / cm / metres; these only change what is shown and how typed values
/// are read.
enum WeightUnit { kg, lb }

enum LengthUnit { cm, inch }

enum DistanceUnit { km, mi }

@immutable
class UnitPrefs {
  const UnitPrefs({this.weight = WeightUnit.kg, this.length = LengthUnit.cm, this.distance = DistanceUnit.km});

  final WeightUnit weight;
  final LengthUnit length;
  final DistanceUnit distance;

  UnitPrefs copyWith({WeightUnit? weight, LengthUnit? length, DistanceUnit? distance}) =>
      UnitPrefs(weight: weight ?? this.weight, length: length ?? this.length, distance: distance ?? this.distance);

  /// Saved as "kg,cm,km".
  String encode() => '${weight.name},${length.name},${distance.name}';

  static UnitPrefs decode(String? s) {
    final p = (s ?? '').split(',');
    T pick<T extends Enum>(List<T> values, int i, T fallback) =>
        i < p.length ? values.where((v) => v.name == p[i]).firstOrNull ?? fallback : fallback;
    return UnitPrefs(
      weight: pick(WeightUnit.values, 0, WeightUnit.kg),
      length: pick(LengthUnit.values, 1, LengthUnit.cm),
      distance: pick(DistanceUnit.values, 2, DistanceUnit.km),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UnitPrefs && other.weight == weight && other.length == length && other.distance == distance;

  @override
  int get hashCode => Object.hash(weight, length, distance);
}

/// The current display units, readable from anywhere (formatters are plain
/// functions). The app rebuilds when [notifier] changes.
class Units {
  Units._();

  static const kgPerLb = 0.45359237;
  static const cmPerInch = 2.54;
  static const metresPerMile = 1609.344;

  static final notifier = ValueNotifier<UnitPrefs>(const UnitPrefs());
  static UnitPrefs get current => notifier.value;

  // ---- weight ----
  static bool get lb => current.weight == WeightUnit.lb;

  /// "kg" / "lb".
  static String get w => lb ? 'lb' : 'kg';

  /// Stored kg → the number to show.
  static double toW(double kg) => lb ? kg / kgPerLb : kg;

  /// A typed number → kg to store.
  static double fromW(double v) => lb ? v * kgPerLb : v;

  // ---- body lengths ----
  static bool get inch => current.length == LengthUnit.inch;
  static String get len => inch ? 'in' : 'cm';
  static double toLen(double cm) => inch ? cm / cmPerInch : cm;
  static double fromLen(double v) => inch ? v * cmPerInch : v;

  // ---- distance ----
  static bool get mi => current.distance == DistanceUnit.mi;

  /// "km" / "mi".
  static String get d => mi ? 'mi' : 'km';

  /// "kilometres" / "miles" (spoken).
  static String get dSpoken => mi ? 'miles' : 'kilometres';

  /// Metres in one shown unit (1000 or 1609.344): splits, voice updates.
  static double get metresPerUnit => mi ? metresPerMile : 1000;

  /// Metres → km or miles.
  static double toD(double metres) => metres / metresPerUnit;

  /// Typed km or miles → metres.
  static double fromD(double v) => v * metresPerUnit;

  /// "/km" / "/mi".
  static String get pace => mi ? '/mi' : '/km';

  /// Seconds per km → seconds per shown unit.
  static double? paceOut(double? secPerKm) => secPerKm == null ? null : secPerKm * metresPerUnit / 1000;

  /// Typed seconds per shown unit → seconds per km.
  static double paceIn(double secPerUnit) => secPerUnit * 1000 / metresPerUnit;
}
