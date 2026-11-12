import 'package:flutter/material.dart';

import '../app_services.dart';
import 'run/run_start.dart';
import 'screens/workouts_screen.dart';
import 'theme/app_theme.dart';
import 'timers/timers_screen.dart';

/// The big round Start button in the middle of the tab bar.
/// Opens the Start menu, or goes back to a running workout / run.
class StartButton extends StatelessWidget {
  const StartButton({super.key});

  static const size = 66.0;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final scheme = Theme.of(context).colorScheme;
    final nav = Theme.of(context).navigationBarTheme.backgroundColor ?? scheme.surface;
    return ListenableBuilder(
      listenable: Listenable.merge([s.session, s.run]),
      builder: (context, _) {
        final busy = s.session.active != null || s.run.active;
        return Semantics(
          button: true,
          label: busy ? 'Back to your workout' : 'Start',
          child: GestureDetector(
            key: const Key('startButton'),
            onTap: () => openStart(context),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: nav, width: 4),
                boxShadow: const [BoxShadow(color: Color(0x47000000), blurRadius: 20, offset: Offset(0, 8))],
              ),
              alignment: Alignment.center,
              child: Text(
                busy ? 'Back' : 'Start',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Start button: back to a running workout or run, else the Start menu.
Future<void> openStart(BuildContext context) async {
  final s = Services.of(context);
  if (s.session.active != null) return openActiveWorkout(context);
  if (s.run.active) return openLiveRun(context);
  final pick = await showModalBottomSheet<Future<void> Function(BuildContext)>(
    context: context,
    builder: (_) => const StartMenu(),
  );
  if (pick != null && context.mounted) await pick(context);
}

/// Big tiles: strength, run, empty workout, timer. Pops with what to start
/// (run with the caller's context, which outlives the sheet).
class StartMenu extends StatelessWidget {
  const StartMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    void pick(Future<void> Function(BuildContext) f) => Navigator.of(context).pop(f);
    Widget tile({
      required Key key,
      required IconData icon,
      required String title,
      required String subtitle,
      required Color bg,
      required Color fg,
      required Future<void> Function(BuildContext) action,
    }) => Expanded(
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(10),
          onTap: () => pick(action),
          child: Container(
            height: 112,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: fg.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: fg, size: 19),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      subtitle,
                      style: text.bodySmall?.copyWith(color: fg.withValues(alpha: 0.75)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Start', style: text.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                tile(
                  key: const Key('startStrength'),
                  icon: Icons.fitness_center,
                  title: 'Strength',
                  subtitle: 'Pick a template',
                  bg: t.ink,
                  fg: onColor(t.ink),
                  action: quickStartStrength,
                ),
                const SizedBox(width: 8),
                tile(
                  key: const Key('startRunHome'),
                  icon: Icons.directions_run,
                  title: 'Run',
                  subtitle: 'Outdoor or treadmill',
                  bg: t.second,
                  fg: t.onSecond,
                  action: (c) => startRun(c),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                tile(
                  key: const Key('startEmpty'),
                  icon: Icons.add,
                  title: 'Empty workout',
                  subtitle: 'Pick as you go',
                  bg: t.field,
                  fg: t.ink,
                  action: startEmptyWorkout,
                ),
                const SizedBox(width: 8),
                tile(
                  key: const Key('startTimer'),
                  icon: Icons.timer_outlined,
                  title: 'Timer',
                  subtitle: 'Tabata, EMOM…',
                  bg: t.field,
                  fg: t.ink,
                  action: (c) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => const TimersScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
