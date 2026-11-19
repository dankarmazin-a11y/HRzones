import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/notify/rest_notifier.dart';

const _channel = MethodChannel('dexterous.com/flutter/local_notifications');

/// Android shows notifications even while the app is open, so "Rest is over" and
/// "Still working out?" popped up on top of the app (owner's Galaxy, 2026-11-19). On
/// Android they are only handed to the phone while the app is in the background.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android: reminders wait while the app is open', (tester) async {
    AndroidFlutterLocalNotificationsPlugin.registerWith(); // what the Android app does at start-up
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call.method);
      return call.method == 'initialize' ? true : null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, null));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    final n = LocalRestNotifier();
    await n.scheduleRestOver(const Duration(seconds: 90));
    await n.scheduleIdle(const Duration(minutes: 90), workout: 'Push');
    expect(calls, isNot(contains('zonedSchedule')), reason: 'nothing on top of the open app');

    // Screen off / another app: both are handed to the phone.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(calls.where((c) => c == 'zonedSchedule'), hasLength(2));

    // Back in the app: taken back again.
    calls.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls.where((c) => c == 'cancel'), hasLength(2));

    // Rest skipped while open: nothing comes later.
    await n.cancel();
    calls.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(calls.where((c) => c == 'zonedSchedule'), hasLength(1), reason: 'only "Still working out?"');
    for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
  });
}
