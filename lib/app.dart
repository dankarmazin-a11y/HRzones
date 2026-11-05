import 'package:flutter/material.dart';

import 'app_services.dart';
import 'app_shell.dart';
import 'hr/hr_monitor.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/run_screen.dart';
import 'ui/screens/tools_screen.dart';
import 'ui/screens/workouts_screen.dart';
import 'ui/run/running_run_bar.dart';
import 'ui/tools_icon.dart';
import 'ui/workout/forgotten_workout.dart';
import 'ui/workout/running_workout_bar.dart';

class HrZonesApp extends StatelessWidget {
  const HrZonesApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE53935), brightness: b),
      useMaterial3: true,
    );
    return Services(
      services: services,
      child: HrScope(
        monitor: services.hr,
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: services.themeMode,
          builder: (context, mode, _) => MaterialApp(
            title: 'HR Zones',
            debugShowCheckedModeBanner: false,
            theme: theme(Brightness.light),
            darkTheme: theme(Brightness.dark),
            themeMode: mode,
            home: const HomeShell(),
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

  static const _screens = [HomeScreen(), WorkoutsScreen(), RunScreen(), ToolsScreen(), ProfileScreen()];

  /// One scroll position per tab. Without this, on iPhone every tab's list
  /// attached to the same (route-wide) controller and the tabs' scroll
  /// positions got mixed up.
  final _scroll = [for (final _ in AppTab.values) ScrollController()];

  @override
  void dispose() {
    for (final c in _scroll) {
      c.dispose();
    }
    super.dispose();
  }

  /// Tapping the tab you are on scrolls it back to the top (like iOS apps).
  void _select(AppTab t) {
    if (t == _tab) {
      final c = _scroll[t.index];
      if (c.hasClients) c.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }
    setState(() => _tab = t);
  }

  @override
  Widget build(BuildContext context) {
    return ForgottenWorkoutWatcher(
      child: AppShell(
        goTo: (t) => setState(() => _tab = t),
        child: Scaffold(
          body: IndexedStack(
            index: _tab.index,
            children: [
              for (final (i, screen) in _screens.indexed)
                PrimaryScrollController(
                  controller: _scroll[i],
                  automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
                  child: screen,
                ),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RunningWorkoutBar(),
              const RunningRunBar(),
              NavigationBar(
                selectedIndex: _tab.index,
                onDestinationSelected: (i) => _select(AppTab.values[i]),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                  NavigationDestination(
                    icon: Icon(Icons.fitness_center_outlined),
                    selectedIcon: Icon(Icons.fitness_center),
                    label: 'Strength',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.directions_run_outlined),
                    selectedIcon: Icon(Icons.directions_run),
                    label: 'Run',
                  ),
                  NavigationDestination(icon: ToolsIcon(), selectedIcon: ToolsIcon(selected: true), label: 'Tools'),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
