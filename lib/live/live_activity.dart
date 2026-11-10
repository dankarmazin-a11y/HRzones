import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the lock-screen / Dynamic Island card shows. Keep in step with
/// ios/WorkoutWidget/WorkoutAttributes.swift.
@immutable
class LiveCard {
  const LiveCard({
    required this.title,
    this.detail = '',
    this.heartRate,
    this.clockStart,
    this.elapsed = Duration.zero,
    this.countdownStart,
    this.countdownEnd,
    this.countdownLabel,
    this.paused = false,
    this.metrics = const [],
    this.actions = const [],
  });

  /// Buttons on the card (iOS 17+): "completeSet", "startSet", "skipRest".
  final List<String> actions;

  /// Big numbers under the title: (label, value), e.g. ("Pace", "5:12").
  final List<(String, String)> metrics;

  /// Big line: "5.24 km" / "Bench Press · set 3 of 4".
  final String title;

  /// Small line: "Pace 5:12 /km · avg 5:20" / "Next: Squat".
  final String detail;
  final int? heartRate;

  /// The clock on the card counts up from here by itself (nil while paused:
  /// then [elapsed] is shown, frozen).
  final DateTime? clockStart;
  final Duration elapsed;

  /// A countdown (rest, timed set) from [countdownStart] (for the bar) to
  /// [countdownEnd].
  final DateTime? countdownStart;
  final DateTime? countdownEnd;
  final String? countdownLabel;
  final bool paused;

  Map<String, Object?> toMap() => {
    'title': title,
    'detail': detail,
    'heartRate': heartRate,
    'clockStart': clockStart?.millisecondsSinceEpoch,
    'elapsed': elapsed.inSeconds,
    'countdownStart': countdownStart?.millisecondsSinceEpoch,
    'countdownEnd': countdownEnd?.millisecondsSinceEpoch,
    'countdownLabel': countdownLabel,
    'paused': paused,
    'actions': actions,
    'metrics': [
      for (final (label, value) in metrics) {'label': label, 'value': value},
    ],
  };

  // The frozen clock only matters while paused (it ticks by itself otherwise).
  @override
  bool operator ==(Object other) =>
      other is LiveCard &&
      other.title == title &&
      other.detail == detail &&
      other.heartRate == heartRate &&
      other.clockStart?.millisecondsSinceEpoch == clockStart?.millisecondsSinceEpoch &&
      (!paused || other.elapsed.inSeconds == elapsed.inSeconds) &&
      other.countdownStart?.millisecondsSinceEpoch == countdownStart?.millisecondsSinceEpoch &&
      other.countdownEnd?.millisecondsSinceEpoch == countdownEnd?.millisecondsSinceEpoch &&
      other.countdownLabel == countdownLabel &&
      other.paused == paused &&
      listEquals(other.metrics, metrics) &&
      listEquals(other.actions, actions);

  @override
  int get hashCode => Object.hash(title, detail, heartRate, clockStart, countdownEnd, countdownLabel, paused);

  @override
  String toString() => 'LiveCard($title | $detail${paused ? ' | paused' : ''})';
}

/// The workout card on the lock screen and in the Dynamic Island (iOS Live
/// Activity) – one card at a time, for a run or a strength workout.
/// Updates are skipped when nothing changed and, unless [update]'s `now`
/// is set, sent at most every [minGap] (the clocks on the card tick by
/// themselves, so this is only for the numbers).
abstract class LiveActivity {
  LiveActivity({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final DateTime Function() _now;

  static const minGap = Duration(seconds: 5);

  static LiveActivity create() =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS ? NativeLiveActivity() : NoLiveActivity();

  /// A button on the card was tapped (set by AppServices).
  void Function(String action)? onAction;

  String? _kind;
  LiveCard? _last;
  DateTime? _sentAt;

  /// "run" / "strength" while a card is up.
  String? get kind => _kind;
  LiveCard? get last => _last;

  Future<void> start(String kind, String name, LiveCard card) async {
    _kind = kind;
    _last = card;
    _sentAt = _now();
    await send('start', {'kind': kind, 'name': name, 'state': card.toMap()});
  }

  /// [now]: send right away (pause, resume, a new set…).
  Future<void> update(LiveCard card, {bool now = false}) async {
    if (_kind == null || card == _last) return;
    final t = _now();
    if (!now && _sentAt != null && t.difference(_sentAt!) < minGap) return;
    _last = card;
    _sentAt = t;
    await send('update', {'state': card.toMap()});
  }

  /// Takes the card away. [kind]: only if the card belongs to that kind.
  Future<void> end({String? kind}) async {
    if (kind != null && _kind != null && _kind != kind) return;
    _kind = null;
    _last = null;
    _sentAt = null;
    await send('end', const {});
  }

  @protected
  Future<void> send(String method, Map<String, Object?> args);

  /// Why the card might not show (iPhone only; null elsewhere).
  Future<Map<String, Object?>?> status() async => null;
}

class NativeLiveActivity extends LiveActivity {
  NativeLiveActivity() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'action' && call.arguments is String) onAction?.call(call.arguments as String);
    });
  }

  static const _channel = MethodChannel('hrzones/live');

  @override
  Future<void> send(String method, Map<String, Object?> args) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Older build / not on iOS.
    } on PlatformException catch (e) {
      debugPrint('Live Activity $method failed: $e');
    }
  }

  @override
  Future<Map<String, Object?>?> status() async {
    try {
      return await _channel.invokeMapMethod<String, Object?>('status');
    } catch (_) {
      return {'old': true};
    }
  }
}

/// Plain-language summary of [LiveActivity.status] for Settings.
String liveStatusText(Map<String, Object?>? m) {
  if (m == null) return 'Only on the iPhone.';
  if (m['old'] == true) return 'This build has no lock-screen card. Install the latest IPA.';
  if (m['supported'] != true) return 'Needs iOS 16.2 or newer (this iPhone has iOS ${m['ios']}).';
  if (m['extension'] != true) {
    return 'The widget part of the app is missing – it was removed when the app was installed. '
        'In Sideloadly, make sure "Remove app extensions" is NOT ticked, then install again.';
  }
  if (m['enabled'] != true) return 'Turned off: iPhone Settings › HR Zones › Live Activities → on.';
  final err = m['lastError'];
  if (err != null) return 'The iPhone refused the card: $err';
  return 'Ready. iOS ${m['ios']}, ${m['running'] ?? 0} card(s) showing now.';
}

/// Web preview and tests: remembers what would have been sent.
class NoLiveActivity extends LiveActivity {
  NoLiveActivity({super.clock});

  final calls = <(String, Map<String, Object?>)>[];

  @override
  Future<void> send(String method, Map<String, Object?> args) async => calls.add((method, args));
}
