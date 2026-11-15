import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/data/exercise_asset.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the app reads the packed list from its bundle', () async {
    expect(await loadExerciseAsset(), File('assets/exercises.json').readAsStringSync());
  });

  test('the packed exercise list is exactly assets/exercises.json', () {
    // Fails when exercises.json changed without running tool/pack_exercises.py.
    final packed = File(exerciseAsset).readAsBytesSync();
    expect(unpackExercises(packed), File('assets/exercises.json').readAsStringSync());
    expect(packed.length, lessThan(File('assets/exercises.json').lengthSync() ~/ 3));
  });

  test('the app ships the packed copy, not the plain one', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- $exerciseAsset'));
    expect(pubspec, isNot(contains('- assets/exercises.json\n')));
  });
}
