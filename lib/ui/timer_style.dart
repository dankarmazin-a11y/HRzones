import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app_services.dart';
import '../beep/beeper.dart';
import 'theme/app_theme.dart';

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

/// Keeps the screen on while a full-screen timer (or a ride) is open. Holds
/// are counted: the screen is let go only when the last one closes, and the
/// app never touches the setting unless it asked for it first (owner,
/// 18 Nov – the phone's own "keep the screen on" got mixed up).
Future<void> keepScreenOn(bool on) async {
  if (on) {
    if (++screenHolds > 1) return;
  } else {
    if (screenHolds == 0) return;
    if (--screenHolds > 0) return;
  }
  try {
    await WakelockPlus.toggle(enable: on);
  } catch (_) {}
}

/// Screens that currently keep the screen on (see [keepScreenOn]).
@visibleForTesting
int screenHolds = 0;

/// Full-screen timer colours from the user's theme (owner, 17 Nov: they didn't
/// follow it): work = the theme's dark ink with the bright colour, rest = a
/// lighter ink with the second colour, get ready / done = a deeper ink.
class TimerColors {
  const TimerColors({
    required this.work,
    required this.rest,
    required this.neutral,
    required this.workAccent,
    required this.restAccent,
    required this.readyAccent,
  });

  factory TimerColors.of(BuildContext context) {
    final p = context.findAncestorWidgetOfExactType<Services>()?.services.palette.value ?? AppPalette.orange;
    return TimerColors(
      work: p.ink,
      rest: Color.lerp(p.ink, Colors.white, 0.08)!,
      neutral: Color.lerp(p.ink, Colors.black, 0.35)!,
      workAccent: p.bright,
      restAccent: p.second,
      readyAccent: p.second,
    );
  }

  final Color work, rest, neutral, workAccent, restAccent, readyAccent;
}

/// The round buttons on the full-screen timers (pause, skip, mute): one look.
class TimerRoundButton extends StatelessWidget {
  const TimerRoundButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.size = 48});

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton.filled(
    tooltip: tooltip,
    iconSize: size,
    style: IconButton.styleFrom(backgroundColor: Colors.white24),
    icon: Icon(icon, color: Colors.white),
    onPressed: onPressed,
  );
}

/// Mute on a full-screen timer (owner, 17 Nov): same round button as pause /
/// skip. Silences the app's sounds until the timer closes.
class TimerMuteButton extends StatelessWidget {
  const TimerMuteButton({super.key, required this.beeper, this.size = 48});

  final Beeper beeper;
  final double size;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: beeper.muted,
    builder: (context, muted, _) => TimerRoundButton(
      key: const Key('timerMute'),
      tooltip: muted ? 'Sound on' : 'Mute',
      size: size,
      icon: muted ? Icons.volume_off : Icons.volume_up,
      onPressed: () => beeper.muted.value = !muted,
    ),
  );
}
