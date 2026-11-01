import 'dart:async';

import 'package:flutter/widgets.dart';

import '../beep/beeper.dart';
import 'heart_rate_source.dart';
import 'simulated_hr_source.dart';
import 'zone_alert_engine.dart';
import 'zones.dart';

/// Glues a heart-rate source, the alert engine and the beeper together and
/// exposes live state to the UI.
class HrMonitor extends ChangeNotifier {
  HrMonitor({HeartRateSource? source, Beeper? beeper, int age = 30})
    : source = source ?? SimulatedHrSource(),
      beeper = beeper ?? Beeper.create(),
      _zones = HrZones.fromAge(age),
      _age = age {
    engine = ZoneAlertEngine(range: _zones.rangeForZone(2));
  }

  final HeartRateSource source;
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
    await beeper.start();
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
    await beeper.stop();
    engine.reset();
    _bpm = null;
    notifyListeners();
  }

  void _onReading(HrReading r) {
    _bpm = r.bpm;
    final alert = engine.onReading(r.bpm, r.time);
    if (alert != null) {
      _lastAlert = alert;
      _lastAlertAt = r.time;
      beeper.alert(alert);
    }
    notifyListeners();
  }

  void setRange(HrRange range) {
    engine.range = range;
    notifyListeners();
  }

  void setAge(int age) {
    _age = age;
    _zones = HrZones.fromAge(age);
    notifyListeners();
  }

  void setCooldown(Duration cooldown) {
    engine.settings = engine.settings.copyWith(cooldown: cooldown);
    notifyListeners();
  }

  void setVolume(double v) {
    _volume = v;
    beeper.setVolume(v);
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
    if (!_running) await beeper.start();
    await beeper.alert(alert);
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
