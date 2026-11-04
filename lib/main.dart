import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final services = await AppServices.open(loadExercises: () => rootBundle.loadString('assets/exercises.json'));
    // Write the running workout right away when the app goes to the
    // background (iOS may close it later without warning). Lives as long as
    // the app.
    AppLifecycleListener(onHide: services.session.flush, onPause: services.session.flush);
    runApp(HrZonesApp(services: services));
  } catch (e, st) {
    debugPrint('Startup failed: $e\n$st');
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Could not open the database:\n$e'))),
      ),
    );
  }
}
