/// Common interface for every heart-rate source (simulated, Bluetooth LE,
/// HealthKit). The rest of the app only talks to this interface, so new
/// sources can be plugged in without touching the zone/beep logic.
library;

enum HrSourceKind { simulated, bluetooth, healthKit }

class HrReading {
  const HrReading({required this.bpm, required this.time, required this.source});

  final int bpm;
  final DateTime time;
  final HrSourceKind source;
}

abstract class HeartRateSource {
  HrSourceKind get kind;

  /// Human-readable name shown in the UI, e.g. "Simulated" or "Polar H10".
  String get displayName;

  /// Live readings. Only emits while started.
  Stream<HrReading> get readings;

  Future<void> start();
  Future<void> stop();
  void dispose();
}
