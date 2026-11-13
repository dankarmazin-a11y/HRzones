import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_services.dart';
import 'feedback/problem_log.dart';
import 'startup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Errors are written to the app's own log (Settings › Report a problem).
  // Nothing leaves the phone unless the user shares a report.
  final flutterError = FlutterError.onError;
  FlutterError.onError = (details) {
    ProblemLog.instance.record(details.exception, details.stack);
    flutterError?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    ProblemLog.instance.record(error, stack);
    return false; // still printed as before
  };
  // Draw the start screen right away (never a black screen), then open the
  // database etc. behind it.
  runApp(
    StartupApp(
      open: (onStep) async {
        final services = await AppServices.open(
          loadExercises: () => rootBundle.loadString('assets/exercises.json'),
          onStep: onStep,
        );
        // Write the running workout right away when the app goes to the
        // background (iOS may close it later without warning). Lives as long
        // as the app.
        AppLifecycleListener(
          onHide: () {
            // Switching apps closes the keyboard (it used to stay open, stuck).
            FocusManager.instance.primaryFocus?.unfocus();
            services.session.flush();
            services.run.flush();
          },
          onPause: () {
            services.session.flush();
            services.run.flush();
          },
        );
        return services;
      },
    ),
  );
}
