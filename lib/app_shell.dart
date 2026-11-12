import 'package:flutter/widgets.dart';

/// The four tab screens. The Start button sits between Strength and Run.
enum AppTab { home, strength, run, profile }

/// Lets screens switch tabs (e.g. Home → Zones).
class AppShell extends InheritedWidget {
  const AppShell({super.key, required this.goTo, required super.child});

  final ValueChanged<AppTab> goTo;

  static AppShell of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppShell>()!;

  @override
  bool updateShouldNotify(AppShell oldWidget) => false;
}
