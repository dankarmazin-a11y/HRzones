import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Steps since [MotionSource.start] and the current cadence (steps/min).
typedef MotionReading = ({int steps, double? cadence});

/// Step counter for cadence: the iPhone's motion chip (CMPedometer) or
/// nothing (web preview, tests).
abstract class MotionSource {
  /// Starts counting from 0. False when the phone can't count steps.
  Future<bool> start();
  Future<void> stop();
  Future<MotionReading?> read();

  static MotionSource create() => kIsWeb ? NoMotionSource() : NativeMotionSource();
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
  Future<MotionReading?> read() async {
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('read');
      if (m == null) return null;
      return (steps: (m['steps'] as num?)?.toInt() ?? 0, cadence: (m['cadence'] as num?)?.toDouble());
    } catch (_) {
      return null;
    }
  }
}

class NoMotionSource extends MotionSource {
  @override
  Future<bool> start() async => false;

  @override
  Future<void> stop() async {}

  @override
  Future<MotionReading?> read() async => null;
}
