import 'package:flutter/widgets.dart';

enum AppTab { home, strength, run, zones, profile }

/// Lets screens switch tabs (e.g. Home → Zones).
class AppShell extends InheritedWidget {
  const AppShell({super.key, required this.goTo, required super.child});

  final ValueChanged<AppTab> goTo;

  static AppShell of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppShell>()!;

  @override
  bool updateShouldNotify(AppShell oldWidget) => false;
}
