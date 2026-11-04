import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../hr/zone_alert_engine.dart';

/// Plays alert beeps. On iOS this is a native module (AVAudioEngine, mixes
/// over music, keeps working with the screen locked). On web it is a stub.
///
/// Several features keep the audio running at the same time (HR monitor,
/// live workout timers, interval timer). Each one takes a *hold* with
/// [start] and releases it with [stop]; the audio only really stops when the
/// last hold is released – otherwise e.g. finishing an interval timer would
/// silence the HR beeps of a running workout once the screen is locked.
abstract class Beeper {
  final _holds = <String>{};

  /// Who currently keeps the audio running (for tests/debugging).
  Set<String> get holds => Set.unmodifiable(_holds);

  /// Keeps the audio session running for [owner] (also in the background).
  Future<void> start([String owner = 'default']) async {
    _holds.add(owner);
    // Always ask the platform: it restarts the engine if iOS stopped it.
    await startAudio();
  }

  /// Releases [owner]'s hold; stops the audio when nobody needs it any more.
  /// [linger] keeps it on a little longer so a last beep/ding can finish
  /// (the native side cancels that stop if a sound starts again).
  Future<void> stop([String owner = 'default', Duration linger = Duration.zero]) async {
    if (!_holds.remove(owner)) return;
    if (_holds.isEmpty) await stopAudio(linger);
  }

  @protected
  Future<void> startAudio();
  @protected
  Future<void> stopAudio(Duration linger);
  Future<void> beep({required double frequency, required int count});
  Future<void> setVolume(double volume);

  /// A bell-like "ding" (end of rest).
  Future<void> ding();

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
  Future<void> startAudio() => _call('start');

  @override
  Future<void> stopAudio(Duration linger) => _call('stop', {'afterMs': linger.inMilliseconds});

  @override
  Future<void> beep({required double frequency, required int count}) =>
      _call('beep', {'frequency': frequency, 'count': count});

  @override
  Future<void> setVolume(double volume) => _call('setVolume', {'volume': volume});

  @override
  Future<void> ding() => _call('ding');
}

/// Used on web and in tests: records calls instead of making sound.
class SilentBeeper extends Beeper {
  final calls = <String>[];

  @override
  Future<void> startAudio() async => calls.add('start');

  @override
  Future<void> stopAudio(Duration linger) async => calls.add('stop');

  @override
  Future<void> beep({required double frequency, required int count}) async =>
      calls.add('beep ${frequency.round()}x$count');

  @override
  Future<void> setVolume(double volume) async => calls.add('volume $volume');

  @override
  Future<void> ding() async => calls.add('ding');
}
