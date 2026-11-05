import 'dart:async';

import 'package:flutter/widgets.dart';

import '../beep/beeper.dart';
import 'ble_hr_source.dart';
import 'heart_rate_source.dart';
import 'simulated_hr_source.dart';
import 'zone_alert_engine.dart';
import 'zones.dart';

/// Glues a heart-rate source, the alert engine and the beeper together and
/// exposes live state to the UI.
class HrMonitor extends ChangeNotifier {
  HrMonitor({HeartRateSource? source, Beeper? beeper, int age = 30})
    : _source = source ?? SimulatedHrSource(),
      beeper = beeper ?? Beeper.create(),
      _zones = HrZones.fromAge(age),
      _age = age {
    engine = ZoneAlertEngine(range: _zones.rangeForZone(2));
  }

  HeartRateSource _source;
  HeartRateSource get source => _source;

  /// Called when the user picks another source (to persist the choice).
  ValueChanged<HeartRateSource>? onSourceChanged;

  /// Switches the heart-rate source; keeps monitoring if it was running.
  Future<void> setSource(HeartRateSource next) async {
    final wasRunning = _running;
    if (wasRunning) await stop();
    final old = _source;
    _source = next;
    if (old is BleHrSource) old.status.removeListener(notifyListeners);
    if (next is BleHrSource) next.status.addListener(notifyListeners);
    old.dispose();
    onSourceChanged?.call(next);
    notifyListeners();
    if (wasRunning) await start();
  }

  /// Connection status for a Bluetooth strap, null for other sources.
  String? get sourceStatus => _source is BleHrSource ? (_source as BleHrSource).status.value : null;
  final Beeper beeper;
  late final ZoneAlertEngine engine;

  int _age;
  HrZones _zones;
  bool _running = false;
  int? _bpm;
  ZoneAlert? _lastAlert;
  DateTime? _lastAlertAt;
  double _volume = 0.7;
  StreamSubscription<HrReading>? _sub;
  Timer? _ticker;

  // Stats for the current workout (avg/max) and since the last completed set.
  int _sessionSum = 0;
  int _sessionCount = 0;
  int? _sessionMax;
  int? _intervalMax;

  /// Called after each beep alert (a run also says it out loud).
  void Function(ZoneAlert alert, int bpm)? onAlert;

  /// Called when a user-facing setting changes (to persist it).
  VoidCallback? onSettingsChanged;

  int get age => _age;
  HrZones get zones => _zones;
  HrRange get range => engine.range;
  AlertSettings get settings => engine.settings;
  bool get running => _running;
  RangeStatus get status => engine.status;
  double get volume => _volume;

  /// Latest bpm, or null when there is no signal.
  int? get bpm => status == RangeStatus.noSignal ? null : _bpm;
  HrZone? get zone => bpm == null ? null : _zones.zoneFor(bpm!);
  ZoneAlert? get lastAlert => _lastAlert;
  DateTime? get lastAlertAt => _lastAlertAt;

  SimulatedHrSource? get simulated => source is SimulatedHrSource ? source as SimulatedHrSource : null;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    engine.reset();
    await beeper.start('hr');
    _sub = source.readings.listen(_onReading);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final before = engine.status;
      engine.tick(DateTime.now());
      if (engine.status != before) notifyListeners();
    });
    await source.start();
    notifyListeners();
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _ticker?.cancel();
    await _sub?.cancel();
    await source.stop();
    await beeper.stop('hr');
    engine.reset();
    _bpm = null;
    notifyListeners();
  }

  void _onReading(HrReading r) {
    _bpm = r.bpm;
    _sessionSum += r.bpm;
    _sessionCount++;
    if (_sessionMax == null || r.bpm > _sessionMax!) _sessionMax = r.bpm;
    if (_intervalMax == null || r.bpm > _intervalMax!) _intervalMax = r.bpm;
    final alert = engine.onReading(r.bpm, r.time);
    if (alert != null) {
      _lastAlert = alert;
      _lastAlertAt = r.time;
      beeper.alert(alert);
      onAlert?.call(alert, r.bpm);
    }
    notifyListeners();
  }

  /// Average HR of the current workout (null without readings).
  int? get sessionAvg => _sessionCount == 0 ? null : (_sessionSum / _sessionCount).round();
  int? get sessionMax => _sessionMax;

  void resetSession() {
    _sessionSum = 0;
    _sessionCount = 0;
    _sessionMax = null;
    _intervalMax = null;
  }

  /// Max HR since the previous call (used per completed set).
  int? takeIntervalMax() {
    final v = _intervalMax;
    _intervalMax = null;
    return v;
  }

  void setRange(HrRange range) {
    engine.range = range;
    _settingsChanged();
  }

  void setAge(int age) {
    _age = age;
    _zones = HrZones.fromAge(age);
    _settingsChanged();
  }

  void setCooldown(Duration cooldown) {
    engine.settings = engine.settings.copyWith(cooldown: cooldown);
    _settingsChanged();
  }

  void setVolume(double v) {
    _volume = v;
    beeper.setVolume(v);
    _settingsChanged();
  }

  void _settingsChanged() {
    onSettingsChanged?.call();
    notifyListeners();
  }

  void setSimulatedBpm(int v) {
    simulated?.bpm = v;
    notifyListeners();
  }

  void setSignalLost(bool lost) {
    simulated?.signalLost = lost;
    notifyListeners();
  }

  Future<void> testBeep(ZoneAlert alert) async {
    await beeper.alert(alert); // the native side starts the audio if needed
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sub?.cancel();
    source.dispose();
    super.dispose();
  }
}

/// Makes the [HrMonitor] available to every screen.
class HrScope extends InheritedNotifier<HrMonitor> {
  const HrScope({super.key, required HrMonitor monitor, required super.child}) : super(notifier: monitor);

  static HrMonitor of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<HrScope>()!.notifier!;
}
