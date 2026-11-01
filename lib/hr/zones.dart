/// Heart-rate zones (5 zones as % of max HR) and target ranges.
library;

class HrZone {
  const HrZone({required this.number, required this.name, required this.minBpm, required this.maxBpm});

  final int number; // 1..5
  final String name;
  final int minBpm; // inclusive
  final int maxBpm; // inclusive

  @override
  String toString() => 'Zone $number ($minBpm–$maxBpm)';
}

class HrZones {
  HrZones(this.maxHr) : zones = _build(maxHr);

  /// Classic estimate: 220 − age.
  factory HrZones.fromAge(int age) => HrZones(maxHrFromAge(age));

  static int maxHrFromAge(int age) => 220 - age;

  static const _names = ['Recovery', 'Endurance', 'Tempo', 'Threshold', 'Max'];
  static const _bounds = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0];

  final int maxHr;
  final List<HrZone> zones;

  static List<HrZone> _build(int maxHr) => [
    for (var i = 0; i < 5; i++)
      HrZone(
        number: i + 1,
        name: _names[i],
        minBpm: (maxHr * _bounds[i]).round(),
        maxBpm: (maxHr * _bounds[i + 1]).round() - (i == 4 ? 0 : 1),
      ),
  ];

  /// Zone for [bpm], or null when below zone 1.
  /// Readings above max HR count as zone 5.
  HrZone? zoneFor(int bpm) {
    if (bpm < zones.first.minBpm) return null;
    for (final z in zones) {
      if (bpm <= z.maxBpm) return z;
    }
    return zones.last;
  }

  HrRange rangeForZone(int number) {
    final z = zones[number - 1];
    return HrRange(min: z.minBpm, max: z.maxBpm);
  }
}

/// A target range the user wants to stay inside (e.g. Zone 2 or 130–145).
class HrRange {
  const HrRange({required this.min, required this.max}) : assert(min < max);

  final int min;
  final int max;

  @override
  bool operator ==(Object other) => other is HrRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => '$min–$max bpm';
}
