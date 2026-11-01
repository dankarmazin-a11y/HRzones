import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../hr/zone_alert_engine.dart';

/// Plays alert beeps. On iOS this is a native module (AVAudioEngine, mixes
/// over music, keeps working with the screen locked). On web it is a stub.
abstract class Beeper {
  Future<void> start();
  Future<void> stop();
  Future<void> beep({required double frequency, required int count});
  Future<void> setVolume(double volume);

  /// 3 high beeps above range, 2 low beeps below.
  Future<void> alert(ZoneAlert alert) => switch (alert) {
    ZoneAlert.high => beep(frequency: 1200, count: 3),
    ZoneAlert.low => beep(frequency: 500, count: 2),
  };

  static Beeper create() => kIsWeb ? SilentBeeper() : NativeBeeper();
}

class NativeBeeper extends Beeper {
  static const _channel = MethodChannel('hrzones/beeper');

  Future<void> _call(String method, [Object? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Platform without the native module (tests, Android for now).
    } on PlatformException catch (e) {
      debugPrint('Beeper.$method failed: ${e.message}');
    }
  }

  @override
  Future<void> start() => _call('start');

  @override
  Future<void> stop() => _call('stop');

  @override
  Future<void> beep({required double frequency, required int count}) =>
      _call('beep', {'frequency': frequency, 'count': count});

  @override
  Future<void> setVolume(double volume) => _call('setVolume', {'volume': volume});
}

/// Used on web and in tests: records calls instead of making sound.
class SilentBeeper extends Beeper {
  final calls = <String>[];

  @override
  Future<void> start() async => calls.add('start');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> beep({required double frequency, required int count}) async =>
      calls.add('beep ${frequency.round()}x$count');

  @override
  Future<void> setVolume(double volume) async => calls.add('volume $volume');
}
