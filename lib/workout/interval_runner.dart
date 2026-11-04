import 'dart:async';

import 'package:flutter/foundation.dart';

import '../beep/beeper.dart';
import '../data/preset_repository.dart';

/// One step of a running interval timer.
class IntervalStep {
  const IntervalStep({required this.label, required this.seconds, required this.work, required this.round});

  final String label;
  final int seconds;
  final bool work;
  final int round; // 1-based
}

/// Segments × rounds as a flat list of steps.
List<IntervalStep> expandSegments(List<IntervalSegment> segments, int rounds) => [
  for (var r = 1; r <= rounds; r++)
    for (final s in segments)
      if (s.seconds > 0) IntervalStep(label: s.label, seconds: s.seconds, work: s.work, round: r),
];

int totalSeconds(List<IntervalSegment> segments, int rounds) => segments.fold(0, (sum, s) => sum + s.seconds) * rounds;

/// Runs an interval timer: 3-second "get ready", then every step with beeps
/// (2 high = work starts, 1 low = rest starts, short ticks in the last 3 s,
/// 3 high at the end).
class IntervalRunner extends ChangeNotifier {
  IntervalRunner({
    required this.name,
    required this.steps,
    required this.rounds,
    required this.beeper,
    this.readySeconds = 3,
  });

  final String name;
  final List<IntervalStep> steps;
  final int rounds;
  final Beeper beeper;
  final int readySeconds;

  /// -1 = get ready; steps.length = finished.
  int _index = -1;
  int _remainingMs = 0;
  bool _paused = false;
  Timer? _timer;
  DateTime? _last;
  int _lastWholeSecond = -1;

  int get index => _index;
  bool get paused => _paused;
  bool get finished => _index >= steps.length;
  bool get gettingReady => _index < 0;
  IntervalStep? get current => _index >= 0 && _index < steps.length ? steps[_index] : null;
  IntervalStep? get next => _index + 1 < steps.length ? steps[_index + 1] : null;
  int get remaining => (_remainingMs / 1000).ceil();
  int get stepTotal => gettingReady ? readySeconds : (current?.seconds ?? 0);

  /// Seconds left in the whole timer.
  int get totalRemaining {
    if (finished) return 0;
    return remaining + steps.skip(_index + 1).fold(0, (s, x) => s + x.seconds);
  }

  Future<void> start() async {
    await beeper.start('intervals');
    begin(DateTime.now());
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => tick(DateTime.now()));
  }

  /// Resets to "get ready" at [now] without a timer (tests drive [tick]).
  void begin(DateTime now) {
    _index = -1;
    _remainingMs = readySeconds * 1000;
    _paused = false;
    _last = now;
    notifyListeners();
  }

  /// Advances the clock (public for tests).
  void tick(DateTime now) {
    final last = _last ?? now;
    _last = now;
    if (_paused || finished) return;
    _remainingMs -= now.difference(last).inMilliseconds;
    final whole = (_remainingMs / 1000).ceil();
    if (whole != _lastWholeSecond && whole >= 1 && whole <= 3 && _remainingMs > 0) {
      beeper.beep(frequency: 880, count: 1); // 3-2-1
    }
    _lastWholeSecond = whole;
    // Catch up through every step that ended (e.g. app was in the background).
    while (_remainingMs <= 0 && !finished) {
      _advance(carry: -_remainingMs);
    }
    notifyListeners();
  }

  void _advance({int carry = 0}) {
    _index++;
    if (finished) {
      _timer?.cancel();
      beeper.beep(frequency: 1200, count: 3);
      // Let the last beeps play before the audio may stop.
      Timer(const Duration(seconds: 2), _release);
      return;
    }
    final step = steps[_index];
    _remainingMs = step.seconds * 1000 - carry;
    _lastWholeSecond = -1;
    step.work ? beeper.beep(frequency: 1100, count: 2) : beeper.beep(frequency: 550, count: 1);
  }

  void togglePause([DateTime? now]) {
    _paused = !_paused;
    _last = now ?? DateTime.now();
    notifyListeners();
  }

  void skip() {
    if (finished) return;
    _advance();
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _index = steps.length;
    _release();
    notifyListeners();
  }

  void _release() => beeper.stop('intervals');

  @override
  void dispose() {
    _timer?.cancel();
    _release();
    super.dispose();
  }
}
