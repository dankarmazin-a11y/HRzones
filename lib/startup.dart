import 'dart:async';

import 'package:flutter/material.dart';

import 'feedback/problem_log.dart';

import 'ui/theme/app_theme.dart';

import 'app.dart';
import 'app_services.dart';
import 'ui/theme/heart_logo.dart';

/// Shown from the very first frame while [AppServices.open] runs, so the
/// app never sits on a black screen: it shows the current step, and the
/// error (or the step that hangs) if start-up fails.
class StartupApp extends StatefulWidget {
  const StartupApp({super.key, required this.open, this.slowAfter = const Duration(seconds: 15)});

  /// Opens the services and reports each step.
  final Future<AppServices> Function(ValueChanged<String> onStep) open;

  /// After this long without finishing, the screen says which step hangs.
  final Duration slowAfter;

  @override
  State<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<StartupApp> {
  String _step = 'Starting';
  AppServices? _services;
  Object? _error;
  bool _slow = false;
  Timer? _watchdog;

  @override
  void initState() {
    super.initState();
    _watchdog = Timer(widget.slowAfter, () => setState(() => _slow = true));
    _start();
  }

  Future<void> _start() async {
    try {
      final s = await widget.open((step) {
        debugPrint('Startup: $step');
        if (mounted) setState(() => _step = step);
      });
      _watchdog?.cancel();
      if (mounted) setState(() => _services = s);
    } catch (e, st) {
      debugPrint('Startup failed at "$_step": $e\n$st');
      ProblemLog.instance.record('Start-up failed at "$_step": $e', st);
      _watchdog?.cancel();
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _services;
    if (s != null) return HrZonesApp(services: s);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(AppPalette.fallback, Brightness.light),
      home: Scaffold(
        // The app icon's dark ink with the beating heart (owner pick, 2026-11-13).
        backgroundColor: AppPalette.fallback.ink,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white70, fontFamily: 'Inter'),
                textAlign: TextAlign.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error == null) const BeatingHeart() else const HeartLogo(),
                    const SizedBox(height: 18),
                    const Text(
                      'HR Zones',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    if (_error == null) ...[
                      Text('$_step…', key: const Key('startupStep'), style: const TextStyle(fontSize: 13)),
                      if (_slow) ...[
                        const SizedBox(height: 16),
                        Text(
                          'This is taking unusually long (stuck at "$_step"). '
                          'Please send a screenshot of this screen.',
                          key: const Key('startupSlow'),
                        ),
                      ],
                    ] else ...[
                      Text(
                        'Could not start ($_step).',
                        key: const Key('startupError'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      SelectableText('$_error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      const Text('Please send a screenshot of this screen.'),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
