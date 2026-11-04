import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'app_services.dart';

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
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE53935)), useMaterial3: true),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monitor_heart_outlined, size: 56, color: Color(0xFFE53935)),
                  const SizedBox(height: 16),
                  Text('HR Zones', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  if (_error == null) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('$_step…', key: const Key('startupStep')),
                    if (_slow) ...[
                      const SizedBox(height: 16),
                      Text(
                        'This is taking unusually long (stuck at "$_step"). '
                        'Please send a screenshot of this screen.',
                        key: const Key('startupSlow'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ] else ...[
                    Text('Could not start ($_step).', key: const Key('startupError')),
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
    );
  }
}
