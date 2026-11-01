import 'package:flutter/material.dart';

/// Colour per HR zone (1..5); grey for no zone / no signal.
Color zoneColor(int? zone) => switch (zone) {
  1 => const Color(0xFF90A4AE),
  2 => const Color(0xFF42A5F5),
  3 => const Color(0xFF66BB6A),
  4 => const Color(0xFFFFA726),
  5 => const Color(0xFFEF5350),
  _ => const Color(0xFF757575),
};
