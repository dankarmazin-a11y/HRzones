import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../hr/zone_alert_engine.dart';
import 'sounds.dart';

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

  /// One of the generated sounds ([SoundChoice] other than classic/high/low),
  /// played [count] times.
  Future<void> sound(String name, {int count = 1});

  /// Says [text] out loud (voice updates during runs). Other apps' music is
  /// turned down while speaking.
  Future<void> speak(String text);

  /// The sound picked for each event (Settings › Sounds); missing = classic.
  final choices = <SoundEvent, SoundChoice>{};

  /// Plays the sound for [event] with the user's choice.
  Future<void> play(SoundEvent event) => preview(event, choices[event] ?? SoundChoice.classic);

  /// Plays [event] as [choice] (also used to preview a choice).
  Future<void> preview(SoundEvent event, SoundChoice choice) => switch (choice) {
    SoundChoice.classic => event.classicDing ? ding() : beep(frequency: event.frequency, count: event.count),
    SoundChoice.high => beep(frequency: 1200, count: event.count),
    SoundChoice.low => beep(frequency: 500, count: event.count),
    SoundChoice.ding => event.count == 1 ? ding() : sound('ding', count: event.count),
    _ => sound(choice.name, count: event.count),
  };

  /// 3 high beeps above range, 2 low beeps below (or the chosen sounds).
  Future<void> alert(ZoneAlert alert) => play(switch (alert) {
    ZoneAlert.high => SoundEvent.zoneHigh,
    ZoneAlert.low => SoundEvent.zoneLow,
  });

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

  @override
  Future<void> sound(String name, {int count = 1}) => _call('sound', {'name': name, 'count': count});

  @override
  Future<void> speak(String text) => _call('speak', {'text': text});
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

  @override
  Future<void> sound(String name, {int count = 1}) async => calls.add('sound ${name}x$count');

  /// Every sentence spoken (tests check the voice updates here).
  final spoken = <String>[];

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    calls.add('speak');
  }
}
