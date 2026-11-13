import 'package:flutter/material.dart';

import 'ui/onboarding/onboarding_screen.dart';
import 'ui/theme/app_theme.dart';

import 'app_services.dart';
import 'app_shell.dart';
import 'hr/hr_monitor.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/run_screen.dart';
import 'ui/screens/workouts_screen.dart';
import 'ui/run/running_run_bar.dart';
import 'ui/start_menu.dart';
import 'ui/workout/forgotten_workout.dart';
import 'ui/workout/running_workout_bar.dart';
import 'ui/theme/emblems.dart';
import 'units/units.dart';

class HrZonesApp extends StatelessWidget {
  const HrZonesApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Services(
      services: services,
      child: HrScope(
        monitor: services.hr,
        child: ListenableBuilder(
          listenable: Listenable.merge([services.themeMode, services.palette, Units.notifier]),
          builder: (context, _) => MaterialApp(
            title: 'HR Zones',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(services.palette.value, Brightness.light),
            darkTheme: buildAppTheme(services.palette.value, Brightness.dark),
            themeMode: services.themeMode.value,
            // First launch: the setup walk-through, then the app.
            home: ValueListenableBuilder<bool>(
              valueListenable: services.needsOnboarding,
              builder: (context, show, _) => show ? const OnboardingScreen() : const HomeShell(),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppTab _tab = AppTab.home;

  static const _screens = [HomeScreen(), WorkoutsScreen(), RunScreen(), ProfileScreen()];

  /// Tab → NavigationBar slot (slot 2 is the gap under the Start button).
  static int _slot(AppTab t) => t.index < 2 ? t.index : t.index + 1;

  /// One scroll position per tab. Without this, on iPhone every tab's list
  /// attached to the same (route-wide) controller and the tabs' scroll
  /// positions got mixed up.
  final _scroll = [for (final _ in AppTab.values) ScrollController()];

  /// Swipe left/right between the tabs.
  final _pages = PageController();

  @override
  void dispose() {
    for (final c in _scroll) {
      c.dispose();
    }
    _pages.dispose();
    super.dispose();
  }

  /// Tapping the tab you are on scrolls it back to the top (like iOS apps).
  void _select(AppTab t) {
    if (t == _tab) {
      final c = _scroll[t.index];
      if (c.hasClients) c.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }
    _goTo(t);
  }

  void _goTo(AppTab t) {
    setState(() => _tab = t);
    // Jump (no slide through the tabs in between).
    if (_pages.hasClients) _pages.jumpToPage(t.index);
  }

  @override
  Widget build(BuildContext context) {
    return ForgottenWorkoutWatcher(
      child: AppShell(
        goTo: _goTo,
        child: Scaffold(
          body: PageView(
            key: const Key('tabPages'),
            controller: _pages,
            physics: const SnappyPagePhysics(),
            // Builds the neighbouring tabs ahead of time: no stutter at the
            // start of a swipe.
            allowImplicitScrolling: true,
            onPageChanged: (i) => setState(() => _tab = AppTab.values[i]),
            children: [
              for (final (i, screen) in _screens.indexed)
                _KeepAlive(
                  child: RepaintBoundary(
                    child: PrimaryScrollController(
                      controller: _scroll[i],
                      automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
                      child: screen,
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RunningWorkoutBar(),
              const RunningRunBar(),
              // The Start button and the bar's bump stick up above the tab
              // bar. They stay inside the Stack (taps outside a Stack's box
              // are lost); the space also keeps every tab's content clear.
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: StartButton.overhang),
                    child: NavigationBar(
                      selectedIndex: _slot(_tab),
                      onDestinationSelected: (i) {
                        if (i == 2) return; // the Start button's gap
                        _select(AppTab.values[i < 2 ? i : i - 1]);
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.fitness_center_outlined),
                          selectedIcon: Icon(Icons.fitness_center),
                          label: 'Strength',
                        ),
                        NavigationDestination(icon: SizedBox(width: 24, height: 24), label: '', enabled: false),
                        NavigationDestination(
                          icon: EmblemIcon(EmblemKind.run),
                          selectedIcon: EmblemIcon(EmblemKind.run, bold: true),
                          label: 'Run',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline),
                          selectedIcon: Icon(Icons.person),
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: StartButton.overhang - StartBump.height,
                    child: StartBump(
                      color:
                          Theme.of(context).navigationBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  const Positioned(top: 0, child: StartButton()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps a tab's screen (and its scroll position) when swiped away.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Tab swiping that reacts to a short, quick flick and settles fast (the
/// default needs a long drag or a hard fling and glides slowly).
class SnappyPagePhysics extends PageScrollPhysics {
  const SnappyPagePhysics({super.parent});

  @override
  SnappyPagePhysics applyTo(ScrollPhysics? ancestor) => SnappyPagePhysics(parent: buildParent(ancestor));

  /// A slower, shorter flick already turns the page (default 50 px/s).
  @override
  double get minFlingVelocity => 30;

  @override
  double get minFlingDistance => 8;

  /// Settles about twice as fast as the default (stiffness 100).
  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(mass: 0.5, stiffness: 400, ratio: 1.05);

  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}
