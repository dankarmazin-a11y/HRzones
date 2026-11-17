import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/ui/plate_calculator.dart';

void main() {
  test('kilo plates use the official colours: 25 kg red like 2.5 kg, 20 kg blue', () {
    expect(plateColor(25), plateColor(2.5));
    expect(plateColor(20), plateColor(45, lb: true));
    expect(plateColor(15), plateColor(35, lb: true));
    expect(plateColor(10), plateColor(25, lb: true));
    expect(plateColor(5), plateColor(10, lb: true));
  });
}
