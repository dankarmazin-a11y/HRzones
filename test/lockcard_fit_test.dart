import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/ui/workout/active_workout_screen.dart' show KeyboardBar;
import 'package:hrzones/live/live_activity.dart';
import 'package:hrzones/workout/calculators.dart';

import 'test_helpers.dart';

/// Owner (2026-11-22): a typed 1000000 kg froze the app; no lock card on a run.
void main() {
  test('a huge typed weight gives at most 40 plates a side (no endless loop)', () {
    final r = platesPerSide(1000000000, bar: 20);
    expect(r.perSide.length, maxPlatesPerSide);
    expect(platesPerSide(100, bar: 20).perSide, [25, 15]);
  });

  test('a run whose lock-screen card did not start says why', () async {
    final live = _RefusingLive();
    final s = await testServices();
    s.run.live = live;
    await s.run.start(treadmill: true);
    await Future<void>.delayed(const Duration(seconds: 4));
    expect(s.run.liveProblem.value, contains('Turned off'));
    await s.run.discard();
    await s.close();
  });

  testWidgets('Next and Done fill the keyboard bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox(width: 400, child: KeyboardBar())),
      ),
    );
    final next = tester.getSize(find.byKey(const Key('keyboardNext')));
    final done = tester.getSize(find.byKey(const Key('keyboardDone')));
    expect(next.width + done.width, greaterThan(380));
  });
}

class _RefusingLive extends NoLiveActivity {
  @override
  Future<Map<String, Object?>?> status() async => {
    'supported': true,
    'extension': true,
    'enabled': false,
    'running': 0,
  };
}
