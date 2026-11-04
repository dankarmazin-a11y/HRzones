import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_services.dart';
import 'startup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        AppLifecycleListener(onHide: services.session.flush, onPause: services.session.flush);
        return services;
      },
    ),
  );
}
