import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Steps since [MotionSource.start], the current cadence (steps/min) and
/// the height change since start in metres (barometer; null without one).
typedef MotionReading = ({int steps, double? cadence, double? altitude});

/// Step counter for cadence: the iPhone's motion chip (CMPedometer) or
/// nothing (web preview, tests).
abstract class MotionSource {
  /// Starts counting from 0. False when the phone can't count steps.
  Future<bool> start();
  Future<void> stop();
  Future<MotionReading?> read();

  /// Steps per day for the last [days] days (oldest first, today last),
  /// counted by the phone all day. Null when the phone can't tell (web,
  /// tests, no permission).
  Future<List<int>?> dailySteps(int days) async => null;

  static MotionSource create() => kIsWeb ? NoMotionSource(example: true) : NativeMotionSource();
}

class NativeMotionSource extends MotionSource {
  static const _channel = MethodChannel('hrzones/motion');

  @override
  Future<bool> start() async {
    try {
      return await _channel.invokeMethod<bool>('start') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {}
  }

  @override
  Future<List<int>?> dailySteps(int days) async {
    try {
      final l = await _channel.invokeListMethod<num>('daily', {'days': days});
      return l?.map((n) => n.toInt()).toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MotionReading?> read() async {
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('read');
      if (m == null) return null;
      return (
        steps: (m['steps'] as num?)?.toInt() ?? 0,
        cadence: (m['cadence'] as num?)?.toDouble(),
        altitude: (m['altitude'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

class NoMotionSource extends MotionSource {
  /// Web preview: an example week, so the Home card can be seen.
  NoMotionSource({this.example = false});

  final bool example;

  @override
  Future<List<int>?> dailySteps(int days) async =>
      example ? [9120, 6480, 10240, 5310, 8800, 11020, 7420].sublist(7 - days.clamp(1, 7)) : null;

  @override
  Future<bool> start() async => false;

  @override
  Future<void> stop() async {}

  @override
  Future<MotionReading?> read() async => null;
}
