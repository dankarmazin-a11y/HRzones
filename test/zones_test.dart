import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/hr/zones.dart';

void main() {
  test('max HR from age', () {
    expect(HrZones.maxHrFromAge(30), 190);
  });

  test('5 contiguous zones from 50% to 100% of max', () {
    final z = HrZones(200);
    expect(z.zones.map((e) => [e.minBpm, e.maxBpm]).toList(), [
      [100, 119],
      [120, 139],
      [140, 159],
      [160, 179],
      [180, 200],
    ]);
  });

  test('zoneFor', () {
    final z = HrZones(200);
    expect(z.zoneFor(99), isNull);
    expect(z.zoneFor(100)!.number, 1);
    expect(z.zoneFor(139)!.number, 2);
    expect(z.zoneFor(140)!.number, 3);
    expect(z.zoneFor(215)!.number, 5);
  });

  test('rangeForZone', () {
    expect(HrZones(200).rangeForZone(2), const HrRange(min: 120, max: 139));
  });
}
