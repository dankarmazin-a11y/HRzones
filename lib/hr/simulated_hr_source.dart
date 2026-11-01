import 'dart:async';

import 'heart_rate_source.dart';

/// Development source: emits the value of a slider once per second.
/// [signalLost] stops emitting to test the "no signal" state.
class SimulatedHrSource implements HeartRateSource {
  SimulatedHrSource({this.bpm = 120, this.interval = const Duration(seconds: 1)});

  int bpm;
  bool signalLost = false;
  final Duration interval;

  final _controller = StreamController<HrReading>.broadcast();
  Timer? _timer;

  @override
  HrSourceKind get kind => HrSourceKind.simulated;

  @override
  String get displayName => 'Simulated';

  @override
  Stream<HrReading> get readings => _controller.stream;

  @override
  Future<void> start() async {
    _timer?.cancel();
    _emit();
    _timer = Timer.periodic(interval, (_) => _emit());
  }

  void _emit() {
    if (signalLost || _controller.isClosed) return;
    _controller.add(HrReading(bpm: bpm, time: DateTime.now(), source: kind));
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
