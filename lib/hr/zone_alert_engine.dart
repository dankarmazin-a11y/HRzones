import 'zones.dart';

/// Where the heart rate currently is relative to the target range.
enum RangeStatus { noSignal, inRange, above, below }

enum ZoneAlert { high, low }

/// Which side of the zone beeps (owner, 19 Nov: "just too high" so warm-ups
/// and rests stay quiet). Stored by index on heart-rate zones – only append.
enum BeepWhen {
  both('Both'),
  high('Too high'),
  low('Too low');

  const BeepWhen(this.label);
  final String label;

  bool allows(ZoneAlert a) => this == both || (this == high) == (a == ZoneAlert.high);
}

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

  /// Only these alerts beep; the other side stays quiet.
  BeepWhen beepWhen = BeepWhen.both;

  /// Smarter beeps: far outside the zone the beeps repeat twice as often.
  /// Off by default (the pace alerts use this engine too); the heart-rate
  /// monitor switches it on from the setting `beepFaster`.
  bool fasterWhenFar = false;

  /// How far outside the zone counts as "far".
  static const farBpm = 10;

  /// Set by [onReading] when the heart rate came back into the zone after an
  /// alert (a gentle chime).
  bool justBack = false;
  bool _alerted = false;

  RangeStatus _status = RangeStatus.noSignal;
  DateTime? _lastReadingAt;
  DateTime? _outOfRangeSince;
  DateTime? _lastAlertAt;

  RangeStatus get status => _status;

  /// Process one reading. Returns an alert to play, or null.
  ZoneAlert? onReading(int bpm, DateTime now) {
    _lastReadingAt = now;
    justBack = false;
    final next = _classify(bpm);
    if (next != _status) {
      if (next == RangeStatus.inRange && _alerted) justBack = true;
      _alerted = false;
      _outOfRangeSince = next == RangeStatus.inRange ? null : now;
      _status = next;
    }
    if (_status == RangeStatus.inRange) return null;
    final alert = _status == RangeStatus.above ? ZoneAlert.high : ZoneAlert.low;
    if (!beepWhen.allows(alert)) return null;

    final since = _outOfRangeSince!;
    if (now.difference(since) < settings.grace) return null;
    final last = _lastAlertAt;
    final far = alert == ZoneAlert.high ? bpm >= range.max + farBpm : bpm <= range.min - farBpm;
    final cooldown = fasterWhenFar && far ? settings.cooldown ~/ 2 : settings.cooldown;
    if (last != null && now.difference(last) < cooldown) return null;

    _lastAlertAt = now;
    _alerted = true;
    return alert;
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
    justBack = false;
    _alerted = false;
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
