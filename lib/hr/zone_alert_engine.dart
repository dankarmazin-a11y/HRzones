import 'zones.dart';

/// Where the heart rate currently is relative to the target range.
enum RangeStatus { noSignal, inRange, above, below }

enum ZoneAlert { high, low }

class AlertSettings {
  const AlertSettings({
    this.grace = const Duration(seconds: 5),
    this.cooldown = const Duration(seconds: 10),
    this.hysteresisBpm = 2,
    this.signalTimeout = const Duration(seconds: 15),
  });

  /// How long HR must be continuously out of range before the first alert.
  final Duration grace;

  /// Minimum gap between two alerts.
  final Duration cooldown;

  /// HR must come this many bpm back inside the range to count as "back in".
  final int hysteresisBpm;

  /// No reading for this long → "no signal", alerts paused.
  final Duration signalTimeout;

  AlertSettings copyWith({Duration? cooldown, Duration? grace}) => AlertSettings(
    grace: grace ?? this.grace,
    cooldown: cooldown ?? this.cooldown,
    hysteresisBpm: hysteresisBpm,
    signalTimeout: signalTimeout,
  );
}

/// Pure decision logic: feed it readings (and periodic ticks) and it tells
/// you when to beep. No timers or I/O inside, so it is fully unit-testable.
class ZoneAlertEngine {
  ZoneAlertEngine({required this.range, this.settings = const AlertSettings()});

  HrRange range;
  AlertSettings settings;

  RangeStatus _status = RangeStatus.noSignal;
  DateTime? _lastReadingAt;
  DateTime? _outOfRangeSince;
  DateTime? _lastAlertAt;

  RangeStatus get status => _status;

  /// Process one reading. Returns an alert to play, or null.
  ZoneAlert? onReading(int bpm, DateTime now) {
    _lastReadingAt = now;
    final next = _classify(bpm);
    if (next != _status) {
      _outOfRangeSince = next == RangeStatus.inRange ? null : now;
      _status = next;
    }
    if (_status == RangeStatus.inRange) return null;

    final since = _outOfRangeSince!;
    if (now.difference(since) < settings.grace) return null;
    final last = _lastAlertAt;
    if (last != null && now.difference(last) < settings.cooldown) return null;

    _lastAlertAt = now;
    return _status == RangeStatus.above ? ZoneAlert.high : ZoneAlert.low;
  }

  /// Call about once a second so a lost signal is detected even when no
  /// readings arrive.
  void tick(DateTime now) {
    final last = _lastReadingAt;
    if (last != null && now.difference(last) >= settings.signalTimeout) {
      _status = RangeStatus.noSignal;
      _outOfRangeSince = null;
    }
  }

  void reset() {
    _status = RangeStatus.noSignal;
    _lastReadingAt = null;
    _outOfRangeSince = null;
    _lastAlertAt = null;
  }

  RangeStatus _classify(int bpm) {
    final h = settings.hysteresisBpm;
    if (bpm > range.max) return RangeStatus.above;
    if (bpm < range.min) return RangeStatus.below;
    // Inside the range, but still within the hysteresis band of the edge we
    // left through → keep the previous out-of-range status.
    if (_status == RangeStatus.above && bpm > range.max - h) return RangeStatus.above;
    if (_status == RangeStatus.below && bpm < range.min + h) return RangeStatus.below;
    return RangeStatus.inRange;
  }
}
