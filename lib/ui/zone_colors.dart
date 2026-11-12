import 'package:flutter/material.dart';

/// Colour per HR zone (1..5), fixed in every theme (docs/DESIGN.md); grey for no zone / no signal.
Color zoneColor(int? zone) => switch (zone) {
  1 => const Color(0xFF9AA6B2),
  2 => const Color(0xFF4A9FE8),
  3 => const Color(0xFF3FBF7F),
  4 => const Color(0xFFF5A524),
  5 => const Color(0xFFEF4F4F),
  _ => const Color(0xFF757575),
};
