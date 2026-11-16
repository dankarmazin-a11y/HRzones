import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app_services.dart';
import 'package:hrzones/data/exercise_repository.dart' show SettingsAccess;
import 'package:hrzones/platform/phone_system.dart';
import 'package:hrzones/ui/battery_guide.dart';

import 'test_helpers.dart';

const _channel = MethodChannel('hrzones/system');

/// Pretend Android side: battery restricted on a Samsung, permissions as given.
void _fakeAndroid({bool unrestricted = false, bool allowBluetooth = true, List<String>? calls}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) async {
    calls?.add(call.method);
    switch (call.method) {
      case 'battery':
        return {'unrestricted': unrestricted, 'brand': 'samsung', 'sdk': 35};
      case 'permission':
        return (call.arguments as Map)['name'] == 'bluetooth' ? allowBluetooth : true;
    }
    return null;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, null),
  );

  test('battery help per brand', () {
    expect(batteryHelpUrl('samsung'), 'https://dontkillmyapp.com/samsung');
    expect(batteryHelpUrl('redmi'), 'https://dontkillmyapp.com/xiaomi');
    expect(batteryHelpUrl('fairphone'), 'https://dontkillmyapp.com/');
    expect(batterySteps('samsung').join(), contains('Sleeping apps'));
    expect(batterySteps('fairphone').single, contains('Unrestricted'));
  });

  test('without the native side (iPhone, web, tests) permissions count as allowed', () async {
    expect(await PhoneSystem.bluetooth(), isTrue);
    expect(await PhoneSystem.activity(), isTrue);
    expect(await PhoneSystem.battery(), isNull);
  });

  test('a refused Bluetooth permission is reported by the permission call', () async {
    _fakeAndroid(allowBluetooth: false);
    expect(await PhoneSystem.bluetooth(), isFalse);
    expect(await PhoneSystem.activity(), isTrue);
  });

  testWidgets('battery question is asked once, only when the phone may stop the app', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    final calls = <String>[];
    _fakeAndroid(calls: calls);
    await tester.pumpWidget(
      Services(
        services: s,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(onPressed: () => askBatteryOnce(context), child: const Text('go')),
          ),
        ),
      ),
    );
    Future<void> tapGo() async {
      await tester.tap(find.text('go'));
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tapGo();
    expect(find.byKey(const Key('batteryDialog')), findsOneWidget);
    expect(find.textContaining('Sleeping apps'), findsOneWidget);
    await tester.tap(find.byKey(const Key('batteryOpen')));
    await tester.pumpAndSettle();
    expect(calls, contains('openAppSettings'));
    expect(await tester.runAsync(() => s.db.getSetting('batteryAsked')), '1');

    // Second workout: no question again.
    await tapGo();
    expect(find.byKey(const Key('batteryDialog')), findsNothing);
  });

  testWidgets('no battery question when the app is already unrestricted', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    _fakeAndroid(unrestricted: true);
    await tester.pumpWidget(
      Services(
        services: s,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(onPressed: () => askBatteryOnce(context), child: const Text('go')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('batteryDialog')), findsNothing);
    expect(await tester.runAsync(() => s.db.getSetting('batteryAsked')), isNull);
  });

  testWidgets('Settings › Keep running shows the steps for this phone', (tester) async {
    _fakeAndroid();
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: BatterySettingsSection())));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(find.text('Keep running'), findsOneWidget);
    expect(find.text('Your phone may stop HR Zones in the background'), findsOneWidget);
    expect(find.byKey(const Key('batteryAppInfo')), findsOneWidget);
  });
}
