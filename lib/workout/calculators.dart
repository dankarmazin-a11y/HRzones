import 'stats.dart';

/// Standard gym plates (kg), heaviest first.
const standardPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

class PlateResult {
  const PlateResult({required this.perSide, required this.remainder});

  /// Plates to load on each side, heaviest first.
  final List<double> perSide;

  /// Weight that could not be made with the plates (total, not per side).
  final double remainder;
}

/// Which plates to put on each side of a [bar] to reach [target] kg.
PlateResult platesPerSide(double target, {double bar = 20, List<double> plates = standardPlates}) {
  var side = (target - bar) / 2;
  if (side <= 0) return PlateResult(perSide: const [], remainder: target < bar ? 0 : target - bar);
  final out = <double>[];
  for (final p in plates) {
    while (side + 1e-9 >= p) {
      out.add(p);
      side -= p;
    }
  }
  return PlateResult(perSide: out, remainder: double.parse((side * 2).toStringAsFixed(2)));
}

/// Rows of a 1RM table: percentage, weight and roughly how many reps that is
/// (Epley formula turned around).
List<(int, double, int)> percentTable(
  double oneRm, {
  List<int> percents = const [100, 95, 90, 85, 80, 75, 70, 65, 60],
}) => [
  for (final pct in percents)
    (pct, double.parse((oneRm * pct / 100).toStringAsFixed(1)), pct >= 100 ? 1 : (30 * (100 / pct - 1)).round()),
];

/// Estimated 1RM from a set (re-exported for the calculator UI).
double oneRepMax(double weightKg, int reps) => estimated1RM(weightKg, reps);
