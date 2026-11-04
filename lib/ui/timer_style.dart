import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Full-screen timers: bold white numbers on a dark background (easy to read
/// from across the room, and dark colours use less battery on OLED screens).
/// The phase is shown by the background and an accent colour.
abstract final class TimerStyle {
  static const workBackground = Color(0xFF2A0C4E); // dark purple
  static const restBackground = Color(0xFF0B1D3A); // dark blue
  static const neutralBackground = Color(0xFF0D0D12); // almost black

  static const workAccent = Color(0xFF69F0AE); // green
  static const restAccent = Color(0xFF80D8FF); // light blue
  static const readyAccent = Color(0xFFFFD740); // amber

  static const digits = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 200,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Keeps the screen on while a full-screen timer is open. Never fails (no
/// plugin in tests / some platforms).
Future<void> keepScreenOn(bool on) async {
  try {
    await WakelockPlus.toggle(enable: on);
  } catch (_) {}
}
