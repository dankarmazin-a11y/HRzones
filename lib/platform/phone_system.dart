import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// True in the Android app (not on iPhone or the web preview). Tests run as Android too; there
/// the native side is missing, so questions answer "allowed" and [PhoneSystem.battery] is null.
bool get isAndroidApp => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// "phone" on Android, "iPhone" on iPhone – for texts that name the device.
String get phoneWord => isAndroidApp ? 'phone' : 'iPhone';

/// Where the user changes the app's permissions, in plain words.
String get appSettingsPath => isAndroidApp ? 'phone Settings › Apps › HR Zones' : 'iPhone Settings › HR Zones';

/// What Android may do with the app in the background.
class BatteryState {
  const BatteryState({required this.unrestricted, required this.brand});

  /// Android won't stop the app to save battery.
  final bool unrestricted;

  /// The phone's maker in lower case ("samsung", "xiaomi", …).
  final String brand;
}

/// Android-only system helpers (native `SystemPlugin.kt`, channel `hrzones/system`).
/// On iPhone / web / tests every question answers "allowed" and nothing opens.
class PhoneSystem {
  static const _channel = MethodChannel('hrzones/system');

  /// True in the real Android app once start-up found the native side (false on iPhone, web, tests).
  static bool hasNative = false;

  /// Asks for Bluetooth (scan + connect) when needed; true when allowed.
  static Future<bool> bluetooth({bool ask = true}) => _permission('bluetooth', ask);

  /// Asks for "Physical activity" (step counter) when needed; true when allowed.
  static Future<bool> activity({bool ask = true}) => _permission('activity', ask);

  static Future<bool> _permission(String name, bool ask) async {
    if (!isAndroidApp) return true;
    try {
      return await _channel.invokeMethod<bool>('permission', {'name': name, 'ask': ask}) ?? false;
    } catch (_) {
      return true;
    }
  }

  /// Null when unknown (not Android).
  static Future<BatteryState?> battery() async {
    if (!isAndroidApp) return null;
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('battery');
      if (m == null) return null;
      return BatteryState(unrestricted: m['unrestricted'] == true, brand: (m['brand'] as String?) ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod<void>('openAppSettings');
    } catch (_) {}
  }

  /// Android: puts the app in the background (like the Home button) instead of closing it.
  /// False when it couldn't (not Android) – then Back closes the app as usual.
  static Future<bool> toBack() async {
    try {
      return await _channel.invokeMethod<bool>('toBack') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openUrl(String url) async {
    try {
      await _channel.invokeMethod<void>('openUrl', {'url': url});
    } catch (_) {}
  }
}

/// The steps that keep a workout running with the screen off, per phone maker
/// (from dontkillmyapp.com). The first line is what the App info button opens.
List<String> batterySteps(String brand) => switch (brand) {
  'samsung' => [
    'Tap "Open App info" below → Battery → choose "Unrestricted".',
    'Then phone Settings › Battery › Background usage limits: make sure HR Zones is not in '
        '"Sleeping apps" or "Deep sleeping apps".',
  ],
  'xiaomi' || 'redmi' || 'poco' => [
    'Tap "Open App info" below → Battery saver → "No restrictions".',
    'Also turn on "Autostart" for HR Zones on the same page.',
  ],
  'oneplus' ||
  'oppo' ||
  'realme' => ['Tap "Open App info" below → Battery → "Unrestricted" (or "Allow background activity").'],
  'huawei' || 'honor' => [
    'Phone Settings › Battery › App launch → HR Zones → turn off "Manage automatically" and allow all three.',
  ],
  _ => ['Tap "Open App info" below → Battery → choose "Unrestricted" (or "Don\'t optimise").'],
};

/// dontkillmyapp.com page for the brand (general page when unknown).
String batteryHelpUrl(String brand) {
  const known = {'samsung', 'xiaomi', 'oneplus', 'huawei', 'oppo', 'realme', 'honor', 'google', 'motorola', 'nokia'};
  final b = {'redmi': 'xiaomi', 'poco': 'xiaomi'}[brand] ?? brand;
  return known.contains(b) ? 'https://dontkillmyapp.com/$b' : 'https://dontkillmyapp.com/';
}
