import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

/// The exercise list ships packed (`assets/exercises.json.gz`, made by tool/pack_exercises.py
/// from assets/exercises.json): the phone keeps app files unpacked, so this saves ~700 KB.
const exerciseAsset = 'assets/exercises.json.gz';

/// Unpacks the shipped exercise list into the same JSON text as assets/exercises.json.
String unpackExercises(List<int> packed) => utf8.decode(const GZipDecoder().decodeBytes(packed));

/// Reads the exercise list from the app bundle.
Future<String> loadExerciseAsset([AssetBundle? bundle]) async {
  final data = await (bundle ?? rootBundle).load(exerciseAsset);
  return unpackExercises(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
}
