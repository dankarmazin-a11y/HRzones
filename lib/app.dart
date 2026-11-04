import 'package:flutter/material.dart';

import 'app_services.dart';
import 'app_shell.dart';
import 'hr/hr_monitor.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/run_screen.dart';
import 'ui/screens/tools_screen.dart';
import 'ui/screens/workouts_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return AppShell(
      goTo: (t) => setState(() => _tab = t),
      child: Scaffold(
        body: IndexedStack(index: _tab.index, children: _screens),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RunningWorkoutBar(),
            NavigationBar(
              selectedIndex: _tab.index,
              onDestinationSelected: (i) => setState(() => _tab = AppTab.values[i]),
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
                NavigationDestination(
                  icon: Icon(Icons.handyman_outlined),
                  selectedIcon: Icon(Icons.handyman),
                  label: 'Tools',
                ),
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
    );
  }
}
