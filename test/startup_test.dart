import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/startup.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  testWidgets('shows the start screen, then the app', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    final ready = Completer<AppServices>();
    await tester.pumpWidget(
      StartupApp(
        open: (onStep) {
          onStep('Loading the exercise list');
          return ready.future;
        },
      ),
    );
    await tester.pump();
    expect(find.text('Loading the exercise list…'), findsOneWidget);
    ready.complete(s);
    await settle(tester);
    expect(find.text('Strength'), findsWidgets); // the real app
    await tearDownApp(tester, s);
  });

  testWidgets('a failing start shows the step and the error, not a black screen', (tester) async {
    await tester.pumpWidget(
      StartupApp(
        open: (onStep) async {
          onStep('Opening the database');
          throw StateError('no sqlite');
        },
      ),
    );
    await tester.pump();
    expect(find.text('Could not start (Opening the database).'), findsOneWidget);
    expect(find.textContaining('no sqlite'), findsOneWidget);
  });

  testWidgets('a start that hangs says where it is stuck', (tester) async {
    final never = Completer<AppServices>();
    await tester.pumpWidget(
      StartupApp(
        slowAfter: const Duration(seconds: 5),
        open: (onStep) {
          onStep('Loading the exercise list');
          return never.future;
        },
      ),
    );
    await tester.pump(const Duration(seconds: 6));
    expect(find.byKey(const Key('startupSlow')), findsOneWidget);
    expect(find.textContaining('stuck at "Loading the exercise list"'), findsOneWidget);
  });
}
